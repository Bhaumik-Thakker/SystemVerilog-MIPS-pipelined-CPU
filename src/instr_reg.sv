// instruction register and instruction decode
module instr_reg
  #(
   parameter BITS=32,                       // default number of bits per word
   parameter REG_WORDS=32,                  // default number of words in the regfile
   parameter ADDR_LEFT=$clog2(REG_WORDS)-1, // log base 2 of the number of words
                                            // which is # of bits needed to address
                                            // the memory for read and write
   parameter OP_BITS=4,                     // bits needed to define operations
   parameter SHIFT_BITS=5,                  // bits needed to define shift amount
   parameter JMP_LEFT=25,                   // left bit of the jump target
   parameter IMM_LEFT=BITS/2                // number of bits in immediate field
   )
   (
   output logic [ADDR_LEFT:0]    r1_addr,      // reg file read address 1
   output logic [ADDR_LEFT:0]    r2_addr,      // reg file read address 2
   output logic [ADDR_LEFT:0]    waddr,        // reg file write address
   output logic [SHIFT_BITS-1:0] shamt,        // shift amount for alu
   output logic [OP_BITS-1:0]    alu_op,       // alu operation
   output logic [IMM_LEFT-1:0]   imm,          // use immediate value
   output logic [JMP_LEFT:0]     addr,         // jump address
   output logic                  rw_,          // register file read/write
   output logic                  mem_rw_,      // data memory read/write
   output logic                  sel_mem,      // use data from memory
   output logic                  alu_imm,      // use immediate data for alu
   output logic                  signed_ext,   // do sign extension
   output logic [ 3:0]           byte_en,      // byte enables
   output logic                  halt,         // stop the program
   output logic                  load_link_,   // load link register
   output logic                  check_link,   // check if link register same as addr
   output logic                  atomic,       // atomic operation
   output logic                  jmp,          // jump
   output logic                  breq,         // branch on equal
   output logic                  brne,         // branch on not equal
   output logic                  jal,          // jump and link
   output logic                  jreg,         // jump to register value
   output logic                  exception,    // take exception

   input                         clk,          // system clock
   input                         cache_stall,  // stall from cache controller
   input                         load_instr,   // if 1 load register
   input  [BITS-1:0]             mem_data,     // instruction from instruction memory
   input                         rst_,         // system reset
   input                         equal,        // alu inputs were equal for branches
   input                         stall_pipe,   // stall the pipeline
   input                         not_equal     // alu inputs were not equal for branches
   );

   `include "common.vh"               // common constants
   `include "instr_reg_params.vh"     // instruction register constants

   // Instruction format constants 
   localparam OP_CODE_BITS = 6;       // instruction op code bits
   localparam FUNC_BITS = 6;          // instruction function bits
   localparam OP_LEFT = 31;           // MSB of opcode field
   localparam OP_RIGHT = 26;          // LSB of opcode field  
   localparam RS_LEFT = 25;           // MSB of rs field
   localparam RS_RIGHT = 21;          // LSB of rs field
   localparam RT_LEFT = 20;           // MSB of rt field
   localparam RT_RIGHT = 16;          // LSB of rt field
   localparam RD_LEFT = 15;           // MSB of rd field
   localparam RD_RIGHT = 11;          // LSB of rd field
   localparam SH_LEFT = 10;           // MSB of shift amount field
   localparam SH_RIGHT = 6;           // LSB of shift amount field
   localparam FU_LEFT = 5;            // MSB of function field
   localparam FU_RIGHT = 0;           // LSB of function field
   localparam IMM_RIGHT = 0;          // LSB of immediate field

   // Instruction type identification
   localparam NUM_REG_BITS = 5;       // Number of bits for register addressing
   localparam OP_RTYPE = 6'h00;       // R-type instruction opcode
   localparam OP_JMP = 6'h02;         // J-type instruction opcode
   localparam OP_JAL = 6'h03;         // J-type instruction opcode
   localparam OP_ADDI = 6'h08;        // ADDI instruction opcode
   localparam OP_HALT = 6'h3F;        // HALT instruction opcode
   localparam OP_SW = 6'h2B;
   localparam OP_SB = 6'h28;
   localparam OP_SH = 6'h29;
   localparam OP_BEQ = 6'h4;
   localparam OP_BNE = 6'h5;
   localparam OP_SC = 6'h38;

   localparam NOP = 32'h0000_0020;    // ADD $0, $0, $0
   localparam ZERO = {BITS{1'b0}};    // All zeros constant
   localparam ONE = {{(BITS-1){1'b0}}, 1'b1}; // Value 1
   localparam HALT = 12'hFC0;
   localparam SHIFT_16 = 5'h10;       // Shift amount for LUI instruction
   localparam RA_REG = 5'h1F;


   // Internal registers and signals
   logic [BITS-1:0]         instr;             // instruction register
   logic [OP_CODE_BITS-1:0] opcode;            // instruction opcode
   logic [FUNC_BITS-1:0]    funct;             // instruction function
   logic [ADDR_LEFT:0]      rs;                // source register 1
   logic [ADDR_LEFT:0]      rt;                // source register 2
   logic [ADDR_LEFT:0]      rd;                // destination register
   logic                    r_type;            // R-type instruction
   logic                    j_type;            // J-type instruction  
   logic                    i_type;            // I-type instruction
   logic                    rt_is_src;         // rt is source (not destination)
   logic                    stall;             // pipeline stall signal
   logic                    swap;              // swap low 16 bits to high 16 bits

   // Instruction register - synchronous load with reset
   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_)
         instr <= NOP;   // Load NOP on reset
      else if (!halt && stall_pipe)
         instr <= instr;
      else if (!halt && cache_stall)
         instr <= NOP;
      else if(!halt && stall)
         instr <= NOP;
      else if (!halt && load_instr)
         instr <= mem_data;
   end


   assign opcode = instr[OP_LEFT:OP_RIGHT];
   assign rs     = instr[RS_LEFT:RS_RIGHT];
   assign rt     = instr[RT_LEFT:RT_RIGHT];
   assign rd     = instr[RD_LEFT:RD_RIGHT];
   assign funct  = (r_type) ? instr[FU_LEFT:FU_RIGHT] : ZERO[FU_LEFT:FU_RIGHT];

   // Determine instruction type
   assign r_type = (opcode == OP_RTYPE);                                             // R-type always has opcode 0
   assign i_type = (opcode != OP_RTYPE) && (opcode != OP_JAL) && (opcode != OP_JMP); // Not R, not J
   assign j_type = (opcode == OP_JMP) || (opcode == OP_JAL);                         // Jump opcodes

   // Determine if RT is source or destination
   assign rt_is_src = r_type ||         // R-type: RT is source operand
                  (opcode == OP_BEQ) || // BEQ: RT compared with RS
                  (opcode == OP_BNE) || // BNE: RT compared with RS  
                  (opcode == OP_SW) ||  // SW: RT is data to store
                  (opcode == OP_SB) ||  // SB: RT is data to store
                  (opcode == OP_SC) ||  // SC: RT is data to store
                  (opcode == OP_SH);    // SH: RT is data to store 

   // Extract instruction fields based on type
   assign r1_addr = rs;
   assign r2_addr = rt_is_src ? rt : ZERO[ADDR_LEFT:0];
   assign waddr   = jal ? RA_REG : (r_type ? rd : rt);

   // Shift amount extraction
   assign shamt = swap ? SHIFT_16 : instr[SH_LEFT:SH_RIGHT];

   // Immediate field extraction - sign extension handled in CPU
   assign imm = instr[IMM_LEFT-1:IMM_RIGHT];

   // Jump address extraction
   assign addr = instr[JMP_LEFT:0];

   // Main instruction decode logic
   always @(*) begin
      
      rw_        = 1'b1;       // Default: read from register file
      mem_rw_    = 1'b1;       // Default: read from memory
      alu_op     = ALU_PASS1;  // Default: pass input 1
      alu_imm    = 1'b0;       // Default: use register for ALU input 2
      sel_mem    = 1'b0;       // Default: select ALU output for reg write
      signed_ext = 1'b0;       // Default: zero extension
      halt       = 1'b0;       // Default: don't halt
      byte_en    = 4'hF;       // Default: full word access
      swap       = 1'b0;       // Default: don't swap bytes
      load_link_ = 1'b1;       // Default: don't load link
      check_link = 1'b0;       // Default: don't check link
      atomic     = 1'b0;       // Default: not atomic
      jmp        = 1'b0;       // Default: no jump
      stall      = 1'b0;       // Default: no stall
      breq       = 1'b0;       // Default: no branch on equal
      brne       = 1'b0;       // Default: no branch on not equal
      jal        = 1'b0;       // Default: no jump and link
      jreg       = 1'b0;       // Default: no jump register
      exception  = 1'b0;       // Default: no exception


         // instruction decode
         case ({opcode, funct})
            ADD: begin
               // ADD: rd = rs + rt
               rw_     = 1'b0;      // Write to register file
               alu_op  = ALU_ADD;   // ALU addition
               alu_imm = 1'b0;      // Use register for second operand
            end

            ADDI: begin
               // ADDI: rt = rs + immediate
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_ADD;   // ALU addition
               alu_imm    = 1'b1;      // Use immediate for second operand
               signed_ext = 1'b1;      // Sign extend immediate
            end

            ADDIU: begin
               // ADDIU: rt = rs + immediate
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_ADD;   // ALU addition
               alu_imm    = 1'b1;      // Use immediate for second operand
               signed_ext = 1'b1;      // Sign extend immediate
            end

            ADDU: begin
               // ADDU: rd = rs + rt
               rw_     = 1'b0;      // Write to register file
               alu_op  = ALU_ADD;   // ALU addition
            end

            AND: begin
               // AND: rd = rs & rt
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_AND;   // ALU AND
            end

            ANDI: begin
               // ANDI
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_AND;   // ALU
               alu_imm    = 1'b1;      // Use immediate for second operand
            end

            BEQ: begin
               // BEQ
               breq       = 1'b1;      // Write to register file
               alu_op     = ALU_SUB;   // ALU SUB
               signed_ext = 1'b1;      // Sign extend immediate
	       stall      = (breq && equal);
            end

            BNE: begin
               // BNE
               brne        = 1'b1;     // Write to register file
               alu_op     = ALU_SUB;   // ALU SUB
               alu_imm    = 1'b0;      // Use immediate for second operand
               signed_ext = 1'b1;      // Sign extend immediate
	       stall      = (brne && not_equal);
            end

            LW: begin
               // LW
               rw_        = 1'b0;      // Write to register file
	            sel_mem    = 1'b1;      // Select memory data for write
               alu_op     = ALU_ADD;   // ALU addition
               alu_imm    = 1'b1;      // Use immediate for second operand
               signed_ext = 1'b1;      // Sign extend immediate
            end

            NOR: begin
               // NOR
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_NOR;   // ALU NOR
            end

            OR: begin
               // OR
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_OR;    // ALU OR
            end

            ORI: begin
               // ORI
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_OR;    // ALU OR
               alu_imm    = 1'b1;      // Use immediate for second operand
            end

            SLL: begin
               // SLL
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_SLL;   // ALU SLL
               alu_imm    = 1'b0;      // Use immediate for second operand
            end

            SRL: begin
               // SRL
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_SRL;   // ALU SRL
               alu_imm    = 1'b0;      // Use immediate for second operand
            end

            SW: begin
               // SW
               alu_op     = ALU_ADD;   // ALU addition
               alu_imm    = 1'b1;      // Use immediate for second operand
               signed_ext = 1'b1;      // Sign extend immediate
               mem_rw_    = 1'b0;      // Write to memory
            end

            SUB: begin
               // SUB
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_SUB;   // ALU SUB
            end

            SUBU: begin
               // SUBU
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_SUB;   // ALU SUB
            end

            SRA: begin
               // SRA
               rw_        = 1'b0;      // Write to register file
               alu_op     = ALU_SRA;   // ALU SRA
            end

            J: begin
               // J
               jmp = 1'b1;         	   // jump enable
               stall = 1'b1;       	   // Stall next instr
            end

            JAL: begin
               // JAL
               jmp = 1'b1;         	   // En_jmp
               jal = 1'b1;         	   // En_jal
               rw_ = 1'b1;         	   // En_reg_write 
               //stall = 1'b1;       	   // Stall next instr
            end

            JR: begin
               // JR 
               jreg = 1'b1;        	 // Jump to reg
               stall = 1'b1;       	 // Stall next instr
            end

	    LBU: begin
               // LBU
               sel_mem    = 1'b1;  	// Select memory to write_register 
               rw_        = 1'b0;  	// write_register 
               alu_op     = ALU_ADD; 	// ALU ADD
               alu_imm    = 1'b1;  	// ALU Imm
               signed_ext = 1'b1;  	// Sign extend immediate
               mem_rw_    = 1'b1;       // Mem_read
               byte_en    = 4'b0001;    // Load 1B
            end

            LHU: begin
               // LHU
               sel_mem    = 1'b1;  	// Select memory to write_register 
               rw_        = 1'b0;  	// write_register 
               alu_op     = ALU_ADD; 	// ALU ADD
               alu_imm    = 1'b1;  	// ALU Imm
               signed_ext = 1'b1;  	// Sign extend immediate
               mem_rw_    = 1'b1;  	// Mem_read
               byte_en    = 4'b0011; 	// Load 2B
            end

	     LL: begin
               // LL
               sel_mem    = 1'b1;  	// Select memory to write_register 
               rw_        = 1'b0;  	// write_register 
               alu_op     = ALU_ADD; 	// ALU ADD
               alu_imm    = 1'b1;  	// ALU Imm
               signed_ext = 1'b1;  	// Sign extend immediate
               mem_rw_    = 1'b1;  	// Mem_read 
               load_link_ = 1'b0;  	// Mark load-link
               atomic     = 1'b0;  	// Atomic
            end

	     LUI: begin
               // LUI
               rw_     = 1'b0;     	// write_register 
               alu_op  = ALU_SLL; 	// Shift
               alu_imm = 1'b1;     	// ALU Imm
               swap = 1'b1;             // Swap bytes
	     end

	     SB: begin
               // SB
               mem_rw_    = 1'b0;  	// write_register 
               alu_op     = ALU_ADD; 	// ALU ADD
               alu_imm    = 1'b1;  	// ALU Imm
               signed_ext = 1'b1;  	// Sign extend immediate
               byte_en    = 4'b0001; 	// Store 1B
            end

	    SC: begin
               // SC
               mem_rw_     = 1'b0; 	// write_register 
               alu_op      = ALU_ADD; 	// ALU ADD
               alu_imm     = 1'b1; 	// ALU Imm
               signed_ext  = 1'b1; 	// Sign extend immediate
               check_link  = 1'b1; 	// Check link valid
               atomic      = 1'b1; 	// Atomic
               rw_         = 1'b0; 	// write_register 
            end

	    SH: begin
               // SH
               mem_rw_    = 1'b0;  	// write_register 
               alu_op     = ALU_ADD; 	// ALU ADD
               alu_imm    = 1'b1;  	// ALU Imm
               signed_ext = 1'b1;  	// Sign extend immediate
               byte_en    = 4'b0011; 	// Store 2B
            end

	    SLT: begin
               // SLT
               rw_    = 1'b0;      	// write_register 
               alu_op = ALU_LTS;   	// ALU LTS
            end

	    SLTI: begin
               // SLTI
               rw_        = 1'b0;  	// write_register 
               alu_op     = ALU_LTS;
               alu_imm    = 1'b1;  	// ALU Imm
               signed_ext = 1'b1;  	// Sign extend immediate
            end

	    SLTIU: begin
               // SLTIU
               rw_        = 1'b0;  	// write_register 
               alu_op     = ALU_LTU; 	// compare unsigned 
               alu_imm    = 1'b1;  	// ALU Imm
               signed_ext = 1'b1;  	// Sign extend immediate 
            end

	    SLTU: begin
               // SLTU
               rw_    = 1'b0;      	// write_register 
               alu_op = ALU_LTU;   	// ALU LTU
            end

            HALT: begin  // HALT instruction 
               // HALT
               halt = 1'b1;
            end

            default: begin
               exception = 1'b1;
               halt      = 1'b0;
            end
         endcase
end

   // Debug output for simulation - remove for synthesis
  // always_ff @(posedge clk) begin
   //   if (load_instr && rst_) begin
   //      $display("Loaded instruction: %h, opcode: %h, funct: %h", mem_data, mem_data[31:26], mem_data[5:0]);
     // end
  // end

endmodule
