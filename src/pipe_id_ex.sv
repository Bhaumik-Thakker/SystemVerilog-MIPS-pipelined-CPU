module pipe_id_ex
  #(
   parameter BITS          = 32,
   parameter REG_ADDR_LEFT = 4,
   parameter OP_BITS       = 4,
   parameter SHIFT_BITS    = 5
   )
  (
   // Outputs - Stage 3 
   output logic                     atomic_s3,
   output logic                     sel_mem_s3,
   output logic                     check_link_s3,
   output logic                     mem_rw_s3,
   output logic                     rw_s3,
   output logic [REG_ADDR_LEFT:0]   waddr_s3,
   output logic                     load_link_s3,
   output logic [BITS-1:0]          r2_data_s3,
   output logic [BITS-1:0]          r1_data_s3,
   output logic                     alu_imm_s3,
   output logic [BITS-1:0]          sign_ext_imm_s3,
   output logic [SHIFT_BITS-1:0]    shamt_s3,
   output logic [OP_BITS-1:0]       alu_op_s3,
   output logic [3:0]               byte_en_s3,
   output logic                     halt_s3,
   output logic [REG_ADDR_LEFT:0]   r1_addr_s3,
   output logic [REG_ADDR_LEFT:0]   r2_addr_s3,

   // Inputs - Stage 2 
   input logic                      atomic,
   input logic                      sel_mem,
   input logic                      check_link,
   input logic                      mem_rw_,
   input logic                      rw_,
   input logic [REG_ADDR_LEFT:0]    waddr,
   input logic                      load_link_,
   input logic [BITS-1:0]           r2_data,
   input logic [BITS-1:0]           r1_data,
   input logic                      alu_imm,
   input logic [BITS-1:0]           sign_ext_imm,
   input logic [SHIFT_BITS-1:0]     shamt,
   input logic [OP_BITS-1:0]        alu_op,
   input logic [3:0]                byte_en,
   input logic                      halt_s2,
   input logic [REG_ADDR_LEFT:0]    r1_addr,
   input logic [REG_ADDR_LEFT:0]    r2_addr,
   input logic                      stall_pipe,

   // Clock and reset
   input logic                      clk,
   input logic                      rst_
   );

   // Reset values (inactive states)
   localparam ZERO_ADDR = {(REG_ADDR_LEFT+1){1'b0}};
   localparam ZERO      = {BITS{1'b0}};
   localparam READ_MODE = 1'b1;  // Default read for memory
   localparam ALU_PASS1 = 4'h0;  // Default ALU operation

   // Pipeline register logic - single always block
   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         // Reset all registers to inactive values
         atomic_s3        <= 1'b0;          // Not atomic
         sel_mem_s3       <= 1'b0;          // Select ALU output
         check_link_s3    <= 1'b0;          // Check link
         mem_rw_s3        <= READ_MODE;     // Memory read
         rw_s3            <= READ_MODE;     // Register read
         waddr_s3         <= ZERO_ADDR;     // Write to register 0 (no effect)
         load_link_s3     <= READ_MODE;     // Don't load link
         r2_data_s3       <= ZERO;          // Zero data
         r1_data_s3       <= ZERO;          // Zero data
         alu_imm_s3       <= 1'b0;          // Use register for ALU
         sign_ext_imm_s3  <= ZERO;          // Zero immediate
         shamt_s3         <= 5'b0;          // Zero shift
         alu_op_s3        <= ALU_PASS1;     // Pass operation
         byte_en_s3       <= 4'hF;          // Full word
         halt_s3          <= 1'b0;          // Don't halt
         r1_addr_s3       <= ZERO_ADDR;     // Write to register 0 (no effect)
         r2_addr_s3       <= ZERO_ADDR;     // Write to register 0 (no effect)
      end else begin
         if (stall_pipe) begin
         // Hold current values
         atomic_s3        <= 1'b0;
         check_link_s3    <= 1'b0;
         mem_rw_s3        <= 1'b1;
         rw_s3            <= 1'b1;
         load_link_s3     <= 1'b1;
         sel_mem_s3       <= 1'b0;
         end else begin
         // Load new values on each clock cycle
         atomic_s3        <= atomic;
         sel_mem_s3       <= sel_mem;
         check_link_s3    <= check_link;
         mem_rw_s3        <= mem_rw_;
         rw_s3            <= rw_;
         waddr_s3         <= waddr;
         load_link_s3     <= load_link_;
         r2_data_s3       <= r2_data;
         r1_data_s3       <= r1_data;
         alu_imm_s3       <= alu_imm;
         sign_ext_imm_s3  <= sign_ext_imm;
         shamt_s3         <= shamt;
         alu_op_s3        <= alu_op;
         byte_en_s3       <= byte_en;
         halt_s3          <= halt_s2;
         r1_addr_s3       <= r1_addr;
         r2_addr_s3       <= r2_addr;
      end
   end
   end

endmodule
