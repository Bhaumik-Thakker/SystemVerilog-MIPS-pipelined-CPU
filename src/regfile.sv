// the register file - 2 read, 1 write
// Revised version with reset functionality and base address elimination
module regfile
  #(
   parameter WORDS=32,                  // default number of words
   parameter BITS=32,                   // default number of bits per word
   parameter ADDR_LEFT=$clog2(WORDS)-1,  // log base 2 of the number of words
   parameter BYTES = BITS/8             // number of bytes per word
   )
   (
   output [BITS-1:0] r1_data,          // read value 1
   output [BITS-1:0] r2_data,          // read value 2

   input                clk,           // system clock
   input                rst_,          // system reset (active low)
   input                rw_,           // read=1, write=0
   input  [BITS-1:0]    wdata,         // data to write
   input  [ADDR_LEFT:0] waddr,         // write address (register index)
   input  [ADDR_LEFT:0] r1_addr,       // read address 1
   input  [ADDR_LEFT:0] r2_addr,       // read address 2 
   input  [3:0]         byte_en,       // byte enables
   input                jal,           // jump and link
   input  [BITS-1:0]    pc_addr        // next program counter value
   );
   localparam ZERO_ADDR = {(ADDR_LEFT+1){1'b0}};
   localparam ZERO      = {BITS{1'b0}};
   localparam ONE       = {{(BITS-1){1'b0}}, 1'b1};   // Value 1
   localparam WRITE_EN  = 1'b0;
   localparam RA_ADDR   = 31;                         // $ra register address

   reg [BITS-1:0] mem[0:WORDS-1];                     // default creates 32 32-bit words

   logic jal_priority;

   assign jal_priority = (waddr != ZERO_ADDR) && (!jal || waddr != RA_ADDR); 
   // Write Logic: synchronous on positive clock edge with reset
   always_ff @(posedge clk or negedge rst_)
   begin
      if (!rst_) begin
         // Reset all registers to 0
         for (int i = 0; i < WORDS; i++) begin
            mem[i] <= ZERO;
         end
      end
      else begin
            if (jal) begin
               mem[RA_ADDR] <= pc_addr + ONE;
          end
            if (rw_ == WRITE_EN && jal_priority) begin
            case (byte_en)
               // Write 1 byte: Other bytes are set to 0.
               4'b0001: begin 
		mem[waddr] <= { ZERO[(BITS-1):8], wdata[7:0] };
		end
               // Write 2 bytes: Other bytes are set to 0.
               4'b0011: begin
		 mem[waddr] <= { ZERO[(BITS-1):16], wdata[15:0] };
		end
               // All other values are treated as a 4-byte write.
               default: begin 
		mem[waddr] <= wdata;
		end
            endcase
         end
      end
   end

   // Read Logic: combinational
   // Register 0 always returns 0, other registers return their values
   assign r1_data = (r1_addr == ZERO_ADDR) ? ZERO : mem[r1_addr];
   assign r2_data = (r2_addr == ZERO_ADDR) ? ZERO : mem[r2_addr];

endmodule
