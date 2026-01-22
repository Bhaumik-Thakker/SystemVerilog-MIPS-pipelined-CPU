// Pipeline register between Memory (MEM) and Write Back (WB)
module pipe_mem_wb
#(
   parameter BITS 	   = 32,
   parameter REG_ADDR_LEFT = 4
)
(
// Outputs - Stage 5 
   output logic [BITS-1:0] 	  alu_out_s5,
   output logic 	   	  atomic_s5,
   output logic [BITS-1:0] 	  d_mem_rdata_s5,
   output logic 		  link_rw_s5,
   output logic 		  sel_mem_s5,
   output logic 		  rw_s5,
   output logic [REG_ADDR_LEFT:0] waddr_s5,
   output logic [3:0] 		  byte_en_s5,
   output logic 		  halt_s5,
// Inputs - Stage 4 
   input logic [BITS-1:0]        alu_out_s4,
   input logic            	 atomic_s4,
   input logic [BITS-1:0] 	 d_mem_rdata,
   input logic            	 link_rw_,
   input logic            	 sel_mem_s4,
   input logic                   rw_s4,
   input logic [REG_ADDR_LEFT:0] waddr_s4,
   input logic [3:0] 		 byte_en_s4,
   input logic 			 halt_s4,
   input logic 			 clk,
   input logic  		 rst_
);
   localparam ZERO_ADDR   = {(REG_ADDR_LEFT+1){1'b0}};
   localparam ZERO        = {BITS{1'b0}};
   localparam READ_MODE   = 1'b1;
   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         alu_out_s5     <= ZERO;
         atomic_s5      <= 1'b0;
         d_mem_rdata_s5 <= ZERO;
         link_rw_s5     <= READ_MODE;
         sel_mem_s5     <= 1'b0;
         rw_s5          <= READ_MODE;
         waddr_s5       <= ZERO_ADDR;
         byte_en_s5     <= 4'hF;
         halt_s5        <= 1'b0;
      end else begin
         alu_out_s5     <= alu_out_s4;
         atomic_s5      <= atomic_s4;
         d_mem_rdata_s5 <= d_mem_rdata;
         link_rw_s5     <= link_rw_;
         sel_mem_s5     <= sel_mem_s4;
         rw_s5          <= rw_s4;
         waddr_s5       <= waddr_s4;
         byte_en_s5     <= byte_en_s4;
         halt_s5        <= halt_s4;
      end
   end
endmodule
