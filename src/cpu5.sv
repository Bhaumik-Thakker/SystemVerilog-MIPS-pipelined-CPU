// the top level cpu5 

module cpu5
  #(
   parameter CACHE_ENTRIES = 8, // how many entries in the cache
   parameter CACHE_TAGSZ = 32, // tag bits - entire address
   parameter CACHE_ADDR_LEFT=$clog2(CACHE_ENTRIES)-1  // log2 of the number of entries
   )
   (
   output logic                halt,         // halt signal to end simulation
   output logic                exception,    // the exception interupt signal

   input                       clk,          // system clock
   input                       rst_          // system reset
   );

   `include "cpu_params.vh"
   localparam PAD_WIDTH = BITS - IMM_LEFT;   // Extension width
   localparam ONE = {{(BITS-1){1'b0}}, 1'b1};// Value 1
   localparam ZERO = {BITS{1'b0}};


   // ======== Stage 1 (Fetch) Signals ========
   logic [BITS-1:0]            pc_addr;      // current address
   logic [BITS-1:0]            i_mem_rdata;  // instruction memory read data
   logic [REG_ADDR_LEFT:0]     r1_addr;      // register file read addr 1
   logic [REG_ADDR_LEFT:0]     r2_addr;      // register file read addr 2
   logic [REG_ADDR_LEFT:0]     waddr;        // register file write addr
   logic [SHIFT_BITS-1:0]      shamt;        // shift amount
   logic [OP_BITS-1:0]         alu_op;       // alu operation
   logic [IMM_LEFT-1:0]        imm;          // immediate data
   logic [JMP_LEFT:0]          addr;         // jump address to program counter
   logic                       rw_;          // register file read write signal
   logic                       mem_rw_;      // data memory read write signal
   logic                       sel_mem;      // select the output from the memory
   logic                       load_link_;   // load the link register
   logic                       check_link;   // check if link register is same as address
   logic                       atomic;       // force value to 0 or 1 for atomic operation
   logic                       jmp;          // doing a jump
   logic                       equal;        // values were equal for branches
   logic                       breq;         // doing a branch on equal
   logic                       not_equal;    // values were not equal for branches
   logic                       brne;         // doing o branch o not equal
   logic                       jal;          // doing a jump and link
   logic                       jreg;         // jumping to an address in a register
   logic [BITS-1:0]            link_addr;    // Address from LL
   logic                       link_valid;   // Link still valid?
   logic [BITS-1:0]            jump_target;  // Jump target
   // ======== Cache Signals ========
   logic                       cache_hit;       // cache hit from cam2
   logic [BITS-1:0]            cache_data;      // instruction from cache
   logic                       cache_full;      // cache is full
   logic                       cache_read;      // read signal to cache
   logic                       cache_write_;    // write signal to cache
   logic [CACHE_ADDR_LEFT:0]   cache_w_addr;    // write address for cache
   logic                       cache_new_valid; // new valid bit for cache entry
   logic                       cache_stall;     // stall from cache controller

// ======== Stage 2 (Decode) Signals ========
   logic [BITS-1:0] immediate_with_sign_pad; // Sign-extended version
   logic [BITS-1:0] immediate_with_zero_pad; // Zero-extended version
   logic                       alu_imm;      // use immediate data for the alu
   logic [BITS-1:0]            sign_ext_imm; // immediate data that has been sign extended
   logic                       signed_ext;   // whether or not to extend the sign bit
   logic [ 3:0]                byte_en;      // byte enables
   logic [BITS-1:0]            r1_data;      // register file read data 1
   logic [BITS-1:0]            r2_data;      // register file read data 2
   logic                       halt_s2;      // halt signal for stage 2 of the pipeline
   logic [BITS-1:0]            r1_data_s2;
   logic [BITS-1:0]            r2_data_s2;

// ======== Stage 3 (EX) Signals ========
   logic [BITS-1:0]            alu_out;      // alu output
   logic [BITS-1:0] 	       r1_data_s3;
   logic [BITS-1:0]            r2_data_s3;
   logic [BITS-1:0]            alu_in_1_s3;
   logic [BITS-1:0]            alu_in_2_s3;
   logic [OP_BITS-1:0]         alu_op_s3;
   logic [SHIFT_BITS-1:0]      shamt_s3;
   logic                       alu_imm_s3;
   logic [BITS-1:0]            sign_ext_imm_s3;
   logic [REG_ADDR_LEFT:0]     waddr_s3;
   logic                       rw_s3;
   logic                       mem_rw_s3;
   logic                       sel_mem_s3;
   logic                       atomic_s3;
   logic                       check_link_s3;
   logic                       load_link_s3;
   logic [3:0]                 byte_en_s3;
   logic                       halt_s3;
   logic [REG_ADDR_LEFT:0]     r1_addr_s3;
   logic [REG_ADDR_LEFT:0]     r2_addr_s3;
   logic [BITS-1:0]            r2_data_fwd_s3;
   // Forwarding signals
   logic                       stall_pipe;
   logic                       r1_fwd_s4;
   logic                       r2_fwd_s4;
   logic                       r1_fwd_s5;
   logic                       r2_fwd_s5;
   logic                       r1_fwd_s6;
   logic                       r2_fwd_s6;
   logic                       j_fwd_s4;
   logic                       j_fwd_s5;
   logic                       b_r1_fwd_s4;
   logic                       b_r2_fwd_s4;
   logic                       b_r1_fwd_s5;
   logic                       b_r2_fwd_s5;
// ======== Stage 4 (MEM) Signals ========
   logic [BITS-1:0]            alu_out_s4;
   logic [BITS-1:0]            r2_data_s4;
   logic [REG_ADDR_LEFT:0]     waddr_s4;
   logic                       rw_s4;
   logic                       mem_rw_s4;
   logic                       use_mem_rw_s4;
   logic                       sel_mem_s4;
   logic                       atomic_s4;
   logic                       check_link_s4;
   logic                       load_link_s4;
   logic [3:0]                 byte_en_s4;
   logic                       halt_s4;
   logic                       link_rw_s4;
   logic                       if_not_used_s4;
   //logic [BITS-1:0]            reg_wdata;

// ======== Stage 5 (WB) Signals ========
   logic [BITS-1:0]            alu_out_s5;
   logic [BITS-1:0]            d_mem_rdata;  
   logic [BITS-1:0]            d_mem_rdata_s5;
   logic [REG_ADDR_LEFT:0]     waddr_s5;
   logic                       rw_s5;
   logic                       sel_mem_s5;
   logic                       atomic_s5;
   logic [3:0]                 byte_en_s5;
   logic                       halt_s5;
   logic                       link_rw_s5;
   logic [BITS-1:0]            reg_wdata_s5;
   logic [BITS-1:0]            atomic_wdata_s5;
   logic [BITS-1:0]            sc_result_s5;


   // =================================================================
   // STAGE 1: Instruction Fetch 
   // =================================================================
assign jump_target = j_fwd_s4 ? alu_out_s4 : (j_fwd_s5 ? reg_wdata_s5 : r1_data);
   // the program counter
   // which instruction to read from the instruction memory
   pc #(.BITS(BITS) ) pc (
          .pc_addr(pc_addr), .clk(clk), .addr(addr), .rst_(rst_),
          .jmp(jmp), .load_instr(~halt_s2), .sign_ext_imm(sign_ext_imm),
          .equal(equal), .not_equal(not_equal), .breq(breq), .brne(brne),
          .jreg(jreg), .r1_data(jump_target), .stall_pipe(stall_pipe),
          .cache_stall(cache_stall) );

   // the instruction memory
   // holds the program
   // NOTE: not currently enabling writes to the instruction memory
   memory #( .BASE_ADDR(I_MEM_BASE_ADDR), .BITS(BITS), .WORDS(I_MEM_WORDS) ) i_memory(
       .rdata(i_mem_rdata), .clk(clk), .wdata({BITS{1'b0}}), .rw_(1'b1),
       .addr(pc_addr), .byte_en(4'b0) );

   ca_ctrl #( 
      .CACHE_ENTRIES(CACHE_ENTRIES)
   ) ca_ctrl (
      .cache_read(cache_read), .cache_write_(cache_write_), .cache_w_addr(cache_w_addr), .new_valid(cache_new_valid),
      .cache_stall(cache_stall), .cache_hit(cache_hit), .cache_full(cache_full),
      .branch_or_jump(jmp | jreg | (breq & equal) | (brne & not_equal) ), .clk(clk), .rst_(rst_)
   );

   cam2 #(
      .WORDS(CACHE_ENTRIES), .BITS(BITS), .ADDR_LEFT(CACHE_ADDR_LEFT), .TAG_SZ(CACHE_TAGSZ)
   ) cam (
      .cache_data(cache_data), .cache_hit(cache_hit), .cache_full(cache_full), .check_tag(pc_addr),              
      .read(cache_read), .write_(cache_write_), .w_addr(cache_w_addr), .wdata(i_mem_rdata),               
      .new_tag(pc_addr), .new_valid(cache_new_valid), .clk(clk), .rst_(rst_)
   );
   // =================================================================
   // STAGE 2: Instruction Decode
   // =================================================================

   // the instruction register - includes instruction decode
   // gets instruction to execute and decodes it, telling the rest of the design what to do
   instr_reg #( .BITS(BITS), .REG_WORDS(REG_WORDS), .OP_BITS(OP_BITS),
                .SHIFT_BITS(SHIFT_BITS), .JMP_LEFT(JMP_LEFT) ) instr_reg (
       .r1_addr(r1_addr), .r2_addr(r2_addr), .waddr(waddr),
       .jal(jal), .jreg(jreg), .exception(exception),
       .shamt(shamt), .alu_op(alu_op), .imm(imm), .addr(addr),
       .rw_(rw_), .sel_mem(sel_mem), .alu_imm(alu_imm),
       .signed_ext(signed_ext), .byte_en(byte_en), .halt(halt_s2),
       .clk(clk), .load_instr(~halt_s2), .mem_rw_(mem_rw_),
       .load_link_(load_link_), .check_link(check_link),
       .atomic(atomic), .jmp(jmp), .breq(breq), .equal(equal), 
       .brne(brne), .not_equal(not_equal), .cache_stall(cache_stall),
       .mem_data(i_mem_rdata), .rst_(rst_), .stall_pipe(stall_pipe) );

   equality #( .NUM_BITS(BITS) ) equality (
       .equal(equal), .not_equal(not_equal), 
       .data1(r1_data), .data2(r2_data), .b_r1_fwd_s4(b_r1_fwd_s4), .b_r1_fwd_s5(b_r1_fwd_s5), .alu_imm(alu_imm), .b_r2_fwd_s4(b_r2_fwd_s4), .b_r2_fwd_s5(b_r2_fwd_s5), 
       .alu_out_s4(alu_out_s4), .reg_wdata_s5(reg_wdata_s5), .sign_ext_imm(sign_ext_imm) );

   // the register file
   // holds the 32 registers that you can read or write
   // Using modified regfile with reset and base address elimination
   regfile #( .WORDS(REG_WORDS), .BITS(BITS) ) regfile(
       .r1_data(r1_data), .r2_data(r2_data), .clk(clk), .rst_(rst_),
       .rw_(rw_s5), .wdata(reg_wdata_s5), .waddr(waddr_s5),
       .r1_addr(r1_addr), .r2_addr(r2_addr), .byte_en(byte_en_s5), .pc_addr(pc_addr), .jal(jal) ); 
   
   // Sign extension logic for immediate values
   assign immediate_with_sign_pad = { {PAD_WIDTH{imm[(IMM_LEFT-1)]}}, imm }; // Sign extend
   assign immediate_with_zero_pad = { {PAD_WIDTH{1'b0}}, imm };              // Zero extend
   assign sign_ext_imm = signed_ext ? immediate_with_sign_pad : immediate_with_zero_pad;

   // Equality input selection
  // assign equality_data1 = b_r1_fwd_s4 ? alu_out_s4 : b_r1_fwd_s5 ? reg_wdata_s5 : r1_data;  
  // assign equality_data2 = alu_imm ? sign_ext_imm : b_r2_fwd_s4 ? alu_out_s4 : b_r2_fwd_s5 ? reg_wdata_s5 : r2_data;
   assign r1_data_s2 = (r1_fwd_s6 ) ? reg_wdata_s5 : r1_data;
   assign r2_data_s2 = (r2_fwd_s6 ) ? reg_wdata_s5 : r2_data;

// Pipeline Register: ID -> EX
    pipe_id_ex #(
      .BITS(BITS), .REG_ADDR_LEFT(REG_ADDR_LEFT),
      .OP_BITS(OP_BITS), .SHIFT_BITS(SHIFT_BITS)
    )  pipe_id_ex_inst (
      .clk(clk), .rst_(rst_),
      .atomic(atomic), .sel_mem(sel_mem), .check_link(check_link),
      .mem_rw_(mem_rw_), .rw_(rw_), .waddr(waddr),
      .load_link_(load_link_), .r2_data(r2_data_s2), .r1_data(r1_data_s2),
      .alu_imm(alu_imm), .sign_ext_imm(sign_ext_imm), .shamt(shamt),
      .alu_op(alu_op), .byte_en(byte_en), .halt_s2(halt_s2),
      .atomic_s3(atomic_s3), .sel_mem_s3(sel_mem_s3),
      .check_link_s3(check_link_s3), .mem_rw_s3(mem_rw_s3),
      .rw_s3(rw_s3), .waddr_s3(waddr_s3), .load_link_s3(load_link_s3),
      .r2_data_s3(r2_data_s3), .r1_data_s3(r1_data_s3),
      .alu_imm_s3(alu_imm_s3), .sign_ext_imm_s3(sign_ext_imm_s3),
      .shamt_s3(shamt_s3), .alu_op_s3(alu_op_s3),
      .byte_en_s3(byte_en_s3), .halt_s3(halt_s3), .stall_pipe(stall_pipe),
      .r1_addr_s3(r1_addr_s3), .r2_addr_s3(r2_addr_s3),
      .r1_addr(r1_addr), .r2_addr(r2_addr)
   );

   // =================================================================
   // STAGE 3: Execute
   // =================================================================

   // ALU input selection
   assign alu_in_1_s3 = r1_fwd_s4 ? alu_out_s4 : (r1_fwd_s5 ? reg_wdata_s5 : r1_data_s3);                                 // First operand is always from register
   assign alu_in_2_s3 = alu_imm_s3 ? sign_ext_imm_s3 : (r2_fwd_s4 ? alu_out_s4 : (r2_fwd_s5 ? reg_wdata_s5 : r2_data_s3));  // Second operand: immediate or register

   assign r2_data_fwd_s3 = (r2_fwd_s4 && !mem_rw_s3) ? alu_out_s4 : ((r2_fwd_s5 && !sel_mem_s5) ? reg_wdata_s5 : r2_data_s3);
   // the alu
   // does the math
   alu #(.NUM_BITS(BITS), .OP_BITS(OP_BITS), .SHIFT_BITS(SHIFT_BITS)) alu (
   .alu_out(alu_out), .data1(alu_in_1_s3), .data2(alu_in_2_s3), 
   .alu_op(alu_op_s3), .shamt(shamt_s3) );
   assign if_not_used_s4 = (!mem_rw_s4 && (alu_out_s4 == link_addr) && link_valid);
   forward #(.BITS(BITS), .REG_ADDR_LEFT(REG_ADDR_LEFT)) forward (
      .r1_fwd_s4(r1_fwd_s4), .r2_fwd_s4(r2_fwd_s4), .r1_fwd_s5(r1_fwd_s5),
      .r2_fwd_s5(r2_fwd_s5), .stall_pipe(stall_pipe), .r1_fwd_s6(r1_fwd_s6),
      .r2_fwd_s6(r2_fwd_s6), .r1_addr_s3(r1_addr_s3), .r2_addr_s3(r2_addr_s3),
      .rw_s4(rw_s4), .waddr_s4(waddr_s4), .rw_s5(rw_s5), .waddr_s5(waddr_s5),
      .sel_mem_s3(sel_mem_s3), .waddr_s3(waddr_s3), .r1_addr(r1_addr), .r2_addr(r2_addr), 
      .j_fwd_s4(j_fwd_s4), .j_fwd_s5(j_fwd_s5), .b_r1_fwd_s4(b_r1_fwd_s4),
      .b_r2_fwd_s4(b_r2_fwd_s4), .b_r1_fwd_s5(b_r1_fwd_s5), .b_r2_fwd_s5(b_r2_fwd_s5),
      .breq(breq), .brne(brne), .jreg(jreg), .rw_s3(rw_s3), .sel_mem_s4(sel_mem_s4)
   );
   // the link register
   // holds the address from the LL instruction
   // and is used to check if the address is still valid
   // and is used to clear the link register
   // and is used to write to the data memory
   // and is used to read from the data memory
   // and is used to write to the register file
   // and is used to read from the register file
   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         link_addr  <= ZERO;
         link_valid <= 1'b0;
      end
      else begin
         // LL: Save address and mark valid
         if (!load_link_s3) begin
            link_addr  <= alu_out;
            link_valid <= 1'b1;
         end
         // SC: Always clear
         else if (check_link_s4 && atomic_s4) begin
            link_addr  <= ZERO;
            link_valid <= 1'b0;
         end
         // Any store to link_addr clears it
         else if (if_not_used_s4) begin
            link_addr  <= ZERO;
            link_valid <= 1'b0;
         end
      end
   end

   // Pipeline Register: EX -> MEM
   pipe_ex_mem #(.BITS(BITS), .REG_ADDR_LEFT(REG_ADDR_LEFT))
     pipe_ex_mem_inst (
      .clk(clk), .rst_(rst_),
      .alu_out(alu_out), .atomic_s3(atomic_s3), .sel_mem_s3(sel_mem_s3),
      .check_link_s3(check_link_s3), .mem_rw_s3(mem_rw_s3), .rw_s3(rw_s3),
      .waddr_s3(waddr_s3), .load_link_s3(load_link_s3),
      .r2_data_s3(r2_data_fwd_s3), .byte_en_s3(byte_en_s3), .halt_s3(halt_s3),
      .alu_out_s4(alu_out_s4), .atomic_s4(atomic_s4), .sel_mem_s4(sel_mem_s4),
      .check_link_s4(check_link_s4), .mem_rw_s4(mem_rw_s4), .rw_s4(rw_s4),
      .waddr_s4(waddr_s4), .load_link_s4(load_link_s4),
      .r2_data_s4(r2_data_s4), .byte_en_s4(byte_en_s4), .halt_s4(halt_s4));
   
   // =================================================================
   // STAGE 4: Memory
   // =================================================================
   //assign reg_wdata = sel_mem_s4 ? d_mem_rdata : alu_out_s4;
   // Block SC write if link invalid or address mismatch
   assign link_rw_s4 = check_link_s4 && (!link_valid || (alu_out_s4 != link_addr));
   assign use_mem_rw_s4 = mem_rw_s4 || link_rw_s4;

   // the data memory
   // the data is stored or read
   memory #( .BASE_ADDR(D_MEM_BASE_ADDR), .BITS(BITS), .WORDS(D_MEM_WORDS) ) d_memory (
        .rdata(d_mem_rdata), .clk(clk), .wdata(r2_data_s4),
        .rw_(use_mem_rw_s4), .addr((sel_mem_s4 || !use_mem_rw_s4) ? alu_out_s4 : ZERO), .byte_en(byte_en_s4) );

   // Pipeline Register: MEM -> WB
   pipe_mem_wb #(.BITS(BITS), .REG_ADDR_LEFT(REG_ADDR_LEFT))
      pipe_mem_wb_inst (
         .clk(clk), .rst_(rst_),
         .alu_out_s4(alu_out_s4), .atomic_s4(atomic_s4),
         .d_mem_rdata(d_mem_rdata), .link_rw_(link_rw_s4),
         .sel_mem_s4(sel_mem_s4), .rw_s4(rw_s4), .waddr_s4(waddr_s4),
         .byte_en_s4(byte_en_s4), .halt_s4(halt_s4),
         .alu_out_s5(alu_out_s5), .atomic_s5(atomic_s5),
         .d_mem_rdata_s5(d_mem_rdata_s5), .link_rw_s5(link_rw_s5),
         .sel_mem_s5(sel_mem_s5), .rw_s5(rw_s5), .waddr_s5(waddr_s5),
         .byte_en_s5(byte_en_s5), .halt_s5(halt_s5)
   );

   // =================================================================
   // STAGE 5: Write Back
   // =================================================================

   // SC result: 1 if succeeded, 0 if failed
   assign sc_result_s5 = {{(BITS-1){1'b0}}, ~link_rw_s5};
   assign atomic_wdata_s5 = atomic_s5 ? sc_result_s5 : alu_out_s5;
   assign reg_wdata_s5 = sel_mem_s5 ? d_mem_rdata_s5 : atomic_wdata_s5;
   assign halt = halt_s5;

endmodule 


