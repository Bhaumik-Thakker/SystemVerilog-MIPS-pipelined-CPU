// the alu module 
module alu
  #(
   parameter NUM_BITS=32, // default data width
   parameter OP_BITS=4,   // bits needed to define operations
   parameter SHIFT_BITS=5 // bits needed to define shift amount
   )

   (
   output [NUM_BITS-1:0] alu_out,     // alu result

   input  [NUM_BITS-1:0]   data1,     // two data inputs
   input  [NUM_BITS-1:0]   data2,
   input  [OP_BITS-1:0]    alu_op,    // operation to perform
   input  [SHIFT_BITS-1:0] shamt      // shift amount needed for shifting
   );

   `include "common.vh" // holds the common constant values

   logic data1_sign,data2_sign;
   logic [NUM_BITS-1:0] alu_result;

   localparam ZERO = {NUM_BITS{1'b0}};
   localparam ONE = {{(NUM_BITS-1){1'b0}}, 1'b1};
   localparam SIGN_BIT = 1'b1;

always @( * ) begin 
        data1_sign = data1[NUM_BITS-1];
        data2_sign = data2[NUM_BITS-1];
	case (alu_op)
		ALU_PASS1: begin
		 alu_result = data1;
		end
		ALU_ADD: begin
		 alu_result = data1 + data2;
		end
 		ALU_AND: begin
		 alu_result = data1 & data2;
		end
		ALU_OR: begin
		 alu_result = (data1 | data2);
		end
		ALU_NOR: begin
		 alu_result = ~(data1 | data2);
		end
		ALU_SUB: begin
		 alu_result = data1 + (~(data2) + ONE);
		end
		ALU_LTS: begin
        	 // If signs are different, the negative number (sign bit=1) is smaller.
        	 if (data1_sign != data2_sign) begin
         	  alu_result = (data1_sign == SIGN_BIT) ? ONE : ZERO;
        	 // If signs are the same, a normal unsigned comparison is correct.
        	end else begin
        	   alu_result = (data1 < data2) ? ONE : ZERO;
       		 end
     		end
		ALU_LTU: begin
		  alu_result = (data1 < data2) ? ONE : ZERO;
		end
		ALU_SLL: begin 
		  alu_result = data2 << shamt;
		end
		ALU_SRL: begin
		  alu_result = data2 >> shamt;
		end
		ALU_PASS2: begin
		  alu_result = data2;
		end
     		ALU_SRA: begin            
		 if (data2_sign)
              	  alu_result = (data2 >> shamt) | (~(ZERO) << (NUM_BITS-shamt));
            	 else
               	  alu_result = data2 >> shamt;
         	end
		default: begin
		 alu_result = ZERO;
		end
	endcase
end

 assign alu_out = alu_result;

endmodule
