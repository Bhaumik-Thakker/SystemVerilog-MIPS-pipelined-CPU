// data memory
module memory
  #(
   parameter BASE_ADDR = 32'h4000_0000,       // Base address for this memory module
   parameter WORDS=1024,                // default number of words
   parameter BITS=32,                   // default number of bits per word
   parameter ADDR_LEFT=$clog2(WORDS)-1,  // log base 2 of the number of words
   parameter BYTES = BITS/8             // number of bytes per word
   )
   (

   output [BITS-1:0]  rdata,  // read data

   input              clk,    // system clock
   input  [BITS-1:0]  wdata,  // data to write
   input              rw_,    // read=1, write=0
   input  [31:0]      addr,   // only uses enough bits to access # of words
   input  [3:0]       byte_en // byte enables
   );

   reg [BITS-1:0] mem[0:WORDS-1]; // default creates 1024 32-bit words

   // Address decoding logic
   logic addr_valid;
   logic [ADDR_LEFT:0] index;

   localparam ZERO = {BITS{1'b0}};

   // An address is valid if it falls within the range [BASE_ADDR, BASE_ADDR + size_in_bytes - 1]
   assign addr_valid = (addr >= BASE_ADDR) && (addr < (BASE_ADDR + WORDS));
   // Calculate the index into the memory array from the byte address
   assign index = addr[ADDR_LEFT:0];

   // Write Logic: synchronous on positive clock edge
   always @(posedge clk)
   begin
      // Write only occurs if rw_ is 0 (write enable) and the address is valid
      if (rw_ == 1'b0 && addr_valid) begin
         case (byte_en)
            // Write 1 byte: Other bytes in the word are not modified.
            4'b0001: begin
		 mem[index][7:0] <= wdata[7:0];
	    end
            // Write 2 bytes: Other bytes in the word are not modified.
            4'b0011: begin
		 mem[index][15:0] <= wdata[15:0];
	    end
            // Write 4 bytes (full word)
            4'b1111: begin
		 mem[index] <= wdata;
	    end
            // All other byte_en values are ignored.
            default: begin
		//No operation ;
	    end 
         endcase
      end
   end

   // Read Logic: combinational
   // Outputs the data from the specified address if valid, otherwise outputs 0.
   assign rdata = addr_valid ? mem[index] : ZERO;

endmodule
