// forward.sv
module forward
  #(
    parameter BITS = 32,
    parameter REG_ADDR_LEFT = 4
  )
  (
    output logic                  r1_fwd_s4,
    output logic                  r2_fwd_s4,
    output logic                  r1_fwd_s5,
    output logic                  r2_fwd_s5,
    output logic                  stall_pipe,
    output logic                  r1_fwd_s6,
    output logic                  r2_fwd_s6,
    //new signals
    output logic                  j_fwd_s4, // also needed for jr
    output logic                  j_fwd_s5,
    output logic                  b_r1_fwd_s4, // also needed for branches
    output logic                  b_r2_fwd_s4,
    output logic                  b_r1_fwd_s5,
    output logic                  b_r2_fwd_s5,
    
    input logic [REG_ADDR_LEFT:0] r1_addr_s3,
    input logic [REG_ADDR_LEFT:0] r2_addr_s3,
    input logic                   rw_s4,
    input logic [REG_ADDR_LEFT:0] waddr_s4,
    input logic                   rw_s5,
    input logic [REG_ADDR_LEFT:0] waddr_s5,
    input logic                   sel_mem_s3,
    input logic [REG_ADDR_LEFT:0] waddr_s3,
    input logic [REG_ADDR_LEFT:0] r1_addr,
    input logic [REG_ADDR_LEFT:0] r2_addr,
    //new signals
    input logic                   jreg,
    input logic                   rw_s3,
    input logic                   sel_mem_s4,
    input logic                   breq, 
    input logic                   brne
  );
  logic                       stall_pipe_load;
  logic                       stall_pipe_jr;
  logic                       stall_pipe_2_cycles;
  logic                       branch;
  logic                       waddr_s3_r1;
  logic                       waddr_s3_r2;
  logic                       waddr_s4_r1;
  logic                       waddr_s4_r2;
  logic                       waddr_s5_r1;
  logic                       waddr_s5_r2;
  logic                       stall_pipe_branch;
  logic                       stall_pipe_branch_2_cycles;

  localparam ZERO_ADDR = {(REG_ADDR_LEFT+1){1'b0}};

assign branch = (breq == 1'b1 || brne == 1'b1);
assign waddr_s3_r1 = waddr_s3 == r1_addr && waddr_s3 != ZERO_ADDR;
assign waddr_s3_r2 = waddr_s3 == r2_addr && waddr_s3 != ZERO_ADDR;
assign waddr_s4_r1 = waddr_s4 == r1_addr && waddr_s4 != ZERO_ADDR;
assign waddr_s4_r2 = waddr_s4 == r2_addr && waddr_s4 != ZERO_ADDR;
assign waddr_s5_r1 = waddr_s5 == r1_addr && waddr_s5 != ZERO_ADDR;
assign waddr_s5_r2 = waddr_s5 == r2_addr && waddr_s5 != ZERO_ADDR;

assign r1_fwd_s4 = (rw_s4 == 1'b0 && (waddr_s4 == r1_addr_s3 && waddr_s4 != ZERO_ADDR)) ? 1'b1 : 1'b0;
assign r2_fwd_s4 = (rw_s4 == 1'b0 && (waddr_s4 == r2_addr_s3 && waddr_s4 != ZERO_ADDR)) ? 1'b1 : 1'b0;
assign r1_fwd_s5 = (rw_s5 == 1'b0 && (waddr_s5 == r1_addr_s3 && waddr_s5 != ZERO_ADDR)) ? 1'b1 : 1'b0;
assign r2_fwd_s5 = (rw_s5 == 1'b0 && (waddr_s5 == r2_addr_s3 && waddr_s5 != ZERO_ADDR)) ? 1'b1 : 1'b0;

assign r1_fwd_s6 = (rw_s5 == 1'b0 && waddr_s5_r1) ? 1'b1 : 1'b0;
assign r2_fwd_s6 = (rw_s5 == 1'b0 && waddr_s5_r2) ? 1'b1 : 1'b0;

assign stall_pipe_load = (sel_mem_s3 == 1'b1 && rw_s3 == 1'b0 && (waddr_s3_r1 || waddr_s3_r2)) ? 1'b1 : 1'b0;
assign stall_pipe_jr = (jreg == 1'b1 && rw_s3 == 1'b0 && waddr_s3_r1) ? 1'b1 : 1'b0;
assign stall_pipe_2_cycles = (jreg == 1'b1 && (sel_mem_s3 == 1'b1 || sel_mem_s4 == 1'b1) && waddr_s4_r1) ? 1'b1 : 1'b0;

assign stall_pipe_branch = (branch && rw_s3 == 1'b0 && (waddr_s3_r1 || waddr_s3_r2)) ? 1'b1 : 1'b0;
assign stall_pipe_branch_2_cycles = (branch && (sel_mem_s4 == 1'b1 || sel_mem_s3 == 1'b1) && (waddr_s4_r1 || waddr_s4_r2)) ? 1'b1 : 1'b0;

assign stall_pipe = stall_pipe_load || stall_pipe_jr || stall_pipe_2_cycles || stall_pipe_branch || stall_pipe_branch_2_cycles;
//new signals
assign j_fwd_s5 = (jreg == 1'b1 && rw_s5 == 1'b0 && waddr_s5_r1) ? 1'b1 : 1'b0;
assign j_fwd_s4 = (jreg == 1'b1 && rw_s4 == 1'b0 && waddr_s4_r1) ? 1'b1 : 1'b0;

assign b_r1_fwd_s4 = (branch && rw_s4 == 1'b0 && waddr_s4_r1) ? 1'b1 : 1'b0;
assign b_r2_fwd_s4 = (branch && rw_s4 == 1'b0 && waddr_s4_r2) ? 1'b1 : 1'b0;
assign b_r1_fwd_s5 = (branch && rw_s5 == 1'b0 && waddr_s5_r1) ? 1'b1 : 1'b0;
assign b_r2_fwd_s5 = (branch && rw_s5 == 1'b0 && waddr_s5_r2) ? 1'b1 : 1'b0;

endmodule
