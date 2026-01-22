// program counter
module pc
  #(
   parameter BITS=32                  // default number of BITS per word
   )
   (
   output logic [BITS-1:0] pc_addr,      // current instruction address

   input                clk,             // system clock
   input                cache_stall,     // stall for cache controller
   input  [BITS-7:0]    addr,            // jump address
   input                rst_,            // system reset (active low)
   input                jmp,             // take a jump
   input                load_instr,      // load the next address
   input  [BITS-1:0]    sign_ext_imm,    // branch address (sign extended immediate)
   input                equal,           // values equal for branch
   input                breq,            // doing branch on equal
   input                not_equal,       // values not equal for branch
   input                brne,            // doing branch on not equal
   input                jreg,            // jumping to register value
   input  [BITS-1:0]    r1_data,         // value read from register file for jreg
   input                stall_pipe       // stall the pipeline
   );

   // Internal signals for next address calculation
   logic [BITS-1:0]     p1_addr;         // PC + 1 (sequential address)
   logic [BITS-1:0]     jump_addr;       // computed jump address
   logic [BITS-1:0]     branch_addr;     // computed branch address
   logic [BITS-1:0]     next_addr;
   logic [BITS-1:0]     next_addr_sequential; 
   logic [BITS-1:0]     next_addr_jump;
   logic [BITS-1:0]     next_addr_jreg;
   logic [BITS-1:0]     next_addr_breq; 
   logic [BITS-1:0]     next_addr_brne;
   //logic                take_branch;

   localparam ZERO        = {BITS{1'b0}};
   localparam ONE         = {{(BITS-1){1'b0}}, 1'b1};
   localparam OFFSET_ADDR = 2'b00;

   //assign take_branch = jmp || jreg || (breq && equal) || (brne && not_equal);
   
   // Sequential logic for the program counter register
   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         pc_addr <= ZERO;                // Reset to address 0
      end else if (cache_stall) begin
         pc_addr <= pc_addr;           // Load next address when enabled
      end else if (load_instr && !stall_pipe ) begin
         pc_addr <= next_addr;           // Load next address when enabled
      end
   // If load_instr is not asserted, hold current value
   end

   // Combinational logic for possible next address computations
   assign p1_addr     = pc_addr + ONE;                                // sequential next
   assign jump_addr   = {pc_addr[BITS-1:BITS-4], OFFSET_ADDR , addr}; // jump target
   assign branch_addr = pc_addr + sign_ext_imm;                       // branch target

   // next address assignments
   assign next_addr_sequential = ({BITS{!jmp && !jreg && !(breq && equal) && !(brne && not_equal)}} & p1_addr);
   assign next_addr_jump       = ({BITS{jmp && !jreg}} & jump_addr);
   assign next_addr_jreg       = ({BITS{jreg}} & r1_data);
   assign next_addr_breq       = ({BITS{breq && equal && !jmp && !jreg}} & branch_addr);
   assign next_addr_brne       = ({BITS{brne && not_equal && !jmp && !jreg}} & branch_addr);

   // Final next_addr selection with bitwise OR
   assign next_addr = next_addr_sequential |
                      next_addr_jump      |
                      next_addr_jreg      |
                      next_addr_breq      |
                      next_addr_brne;
endmodule  
