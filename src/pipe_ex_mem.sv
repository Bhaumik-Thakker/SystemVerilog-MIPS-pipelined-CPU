module pipe_ex_mem
#(
   parameter BITS 	   = 32,
   parameter REG_ADDR_LEFT = 4
)
(
// Outputs - Stage 4 
   output logic [BITS-1:0] 	  alu_out_s4,
   output logic  		  atomic_s4,
   output logic 		  sel_mem_s4,
   output logic 		  check_link_s4,
   output logic 		  mem_rw_s4,
   output logic  		  rw_s4,
   output logic [REG_ADDR_LEFT:0] waddr_s4,
   output logic 		  load_link_s4,
   output logic [BITS-1:0] 	  r2_data_s4,
   output logic [3:0] 		  byte_en_s4,
   output logic 		  halt_s4,
// Inputs - Stage 3 
   input logic [BITS-1:0] 	  alu_out,
   input logic 		 	  atomic_s3,
   input logic 			  sel_mem_s3,
   input logic 			  check_link_s3,
   input logic 			  mem_rw_s3,
   input logic  		  rw_s3,
   input logic [REG_ADDR_LEFT:0]  waddr_s3,
   input logic 			  load_link_s3,
   input logic [BITS-1:0] 	  r2_data_s3,
   input logic [3:0] 		  byte_en_s3,
   input logic 			  halt_s3,
   input logic 		 	  clk,
   input logic 			  rst_
);
   localparam ZERO_ADDR = {(REG_ADDR_LEFT+1){1'b0}};
   localparam ZERO      = {BITS{1'b0}};
   localparam READ_MODE = 1'b1; 
   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         alu_out_s4    <= ZERO;
         atomic_s4     <= 1'b0;
         sel_mem_s4    <= 1'b0;
         check_link_s4 <= 1'b0;
         mem_rw_s4     <= READ_MODE;
         rw_s4         <= READ_MODE;
         waddr_s4      <= ZERO_ADDR;
         load_link_s4  <= READ_MODE;
         r2_data_s4    <= ZERO;
         byte_en_s4    <= 4'hF;
         halt_s4       <= 1'b0;
      end else begin
         alu_out_s4    <= alu_out;
         atomic_s4     <= atomic_s3;
         sel_mem_s4    <= sel_mem_s3;
         check_link_s4 <= check_link_s3;
         mem_rw_s4     <= mem_rw_s3;
         rw_s4         <= rw_s3;
         waddr_s4      <= waddr_s3;
         load_link_s4  <= load_link_s3;
         r2_data_s4    <= r2_data_s3;
         byte_en_s4    <= byte_en_s3;
         halt_s4       <= halt_s3;
      end
   end
endmodule
