module equality
  #(
   parameter NUM_BITS=32 // default data width
   )

   (
   output            equal,           // arguments eqaul needed for branches
   output            not_equal,       // arguments not equal needed for branches

   input  [NUM_BITS-1:0]   data1,     // two data inputs
   input  [NUM_BITS-1:0]   data2,
   input                   b_r1_fwd_s4,
   input                   b_r1_fwd_s5,
   input                   alu_imm,
   input                   b_r2_fwd_s4,
   input                   b_r2_fwd_s5,
   input  [NUM_BITS-1:0]   alu_out_s4,
   input  [NUM_BITS-1:0]   reg_wdata_s5,
   input  [NUM_BITS-1:0]   sign_ext_imm             
   );

 logic [NUM_BITS-1:0] equality_data1;
 logic [NUM_BITS-1:0] equality_data2;
 assign equality_data1 = b_r1_fwd_s4 ? alu_out_s4 : b_r1_fwd_s5 ? reg_wdata_s5 : data1;  
 assign equality_data2 = alu_imm ? sign_ext_imm : b_r2_fwd_s4 ? alu_out_s4 : b_r2_fwd_s5 ? reg_wdata_s5 : data2;
 assign equal = (equality_data1 == equality_data2);
 assign not_equal = (equality_data1 != equality_data2);

endmodule
