// test bench for the cpu5
module top_cpu5();

   logic        halt;
   logic        exception;

   logic         clk;
   logic         rst_;
   logic  [31:0] counter;
localparam BITS = 32;
// Register Logic Declarations (32 registers)
logic [BITS-1:0] zero;    // $zero = R0
logic [BITS-1:0] at;      // $at = R1  
logic [BITS-1:0] v0;      // $v0 = R2
logic [BITS-1:0] v1;      // $v1 = R3
logic [BITS-1:0] a0;      // $a0 = R4
logic [BITS-1:0] a1;      // $a1 = R5
logic [BITS-1:0] a2;      // $a2 = R6
logic [BITS-1:0] a3;      // $a3 = R7
logic [BITS-1:0] t0;      // $t0 = R8  
logic [BITS-1:0] t1;      // $t1 = R9
logic [BITS-1:0] t2;      // $t2 = R10
logic [BITS-1:0] t3;      // $t3 = R11
logic [BITS-1:0] t4;      // $t4 = R12
logic [BITS-1:0] t5;      // $t5 = R13
logic [BITS-1:0] t6;      // $t6 = R14
logic [BITS-1:0] t7;      // $t7 = R15
logic [BITS-1:0] s0;      // $s0 = R16
logic [BITS-1:0] s1;      // $s1 = R17
logic [BITS-1:0] s2;      // $s2 = R18
logic [BITS-1:0] s3;      // $s3 = R19
logic [BITS-1:0] s4;      // $s4 = R20
logic [BITS-1:0] s5;      // $s5 = R21
logic [BITS-1:0] s6;      // $s6 = R22
logic [BITS-1:0] s7;      // $s7 = R23
logic [BITS-1:0] t8;      // $t8 = R24
logic [BITS-1:0] t9;      // $t9 = R25
logic [BITS-1:0] k0;      // $k0 = R26
logic [BITS-1:0] k1;      // $k1 = R27
logic [BITS-1:0] gp;      // $gp = R28
logic [BITS-1:0] sp;      // $sp = R29
logic [BITS-1:0] fp;      // $fp = R30
logic [BITS-1:0] ra;      // $ra = R31

// Memory Logic Declarations 
logic [BITS-1:0] mem0;
logic [BITS-1:0] mem1;
logic [BITS-1:0] mem2;
logic [BITS-1:0] mem3;
logic [BITS-1:0] mem4;
logic [BITS-1:0] mem5;
logic [BITS-1:0] mem6;
logic [BITS-1:0] mem7;
logic [BITS-1:0] mem8;
logic [BITS-1:0] mem9;
logic [BITS-1:0] mem10;
logic [BITS-1:0] mem11;
logic [BITS-1:0] mem12;
logic [BITS-1:0] mem13;
logic [BITS-1:0] mem14;
logic [BITS-1:0] mem15;
logic [BITS-1:0] mem16;
logic [BITS-1:0] mem17;
logic [BITS-1:0] mem18;
logic [BITS-1:0] mem19;
logic [BITS-1:0] mem20;

   initial // read the array to load the program
   begin
    cpu5.d_memory.mem[5] = 32'h4000002A;
     $readmemh("i_mem_vals.txt", cpu5.i_memory.mem); // loading the memory
     $display("Program loaded into instruction memory");
     // Optional: Display first few instructions for verification
     for ( integer ind = 0 ; ind < 21 ; ind++ )
        $display("Instruction memory index %d is %h", ind, cpu5.i_memory.mem[ind]);
   end

   // Instantiate the cpu5 with all necessary connections
   cpu5 cpu5( 
     .halt(halt), 
     .exception(exception), 
     .clk(clk), 
     .rst_(rst_) 
   );

   // Clock and reset generation
   initial
   begin
     $display("Starting cpu5 simulation at time %0t", $time);
     clk <= 1'b0;
     rst_ <= 1'b0;      // Assert reset
     counter <= 32'h0;

     #20 rst_ <= 1'b1;  // Release reset after 20 time units
     $display("Reset released at time %0t", $time);

     // Generate clock
     while (1)
     begin
        #10 clk <= 1'b1;
        #10 clk <= 1'b0;
     end
   end

// Register Assign Statements
assign zero = cpu5.regfile.mem[0];    // $zero = R0
assign at   = cpu5.regfile.mem[1];    // $at = R1
assign v0   = cpu5.regfile.mem[2];    // $v0 = R2
assign v1   = cpu5.regfile.mem[3];    // $v1 = R3
assign a0   = cpu5.regfile.mem[4];    // $a0 = R4
assign a1   = cpu5.regfile.mem[5];    // $a1 = R5
assign a2   = cpu5.regfile.mem[6];    // $a2 = R6
assign a3   = cpu5.regfile.mem[7];    // $a3 = R7
assign t0   = cpu5.regfile.mem[8];    // $t0 = R8
assign t1   = cpu5.regfile.mem[9];    // $t1 = R9
assign t2   = cpu5.regfile.mem[10];   // $t2 = R10
assign t3   = cpu5.regfile.mem[11];   // $t3 = R11
assign t4   = cpu5.regfile.mem[12];   // $t4 = R12
assign t5   = cpu5.regfile.mem[13];   // $t5 = R13
assign t6   = cpu5.regfile.mem[14];   // $t6 = R14
assign t7   = cpu5.regfile.mem[15];   // $t7 = R15
assign s0   = cpu5.regfile.mem[16];   // $s0 = R16
assign s1   = cpu5.regfile.mem[17];   // $s1 = R17
assign s2   = cpu5.regfile.mem[18];   // $s2 = R18
assign s3   = cpu5.regfile.mem[19];   // $s3 = R19
assign s4   = cpu5.regfile.mem[20];   // $s4 = R20
assign s5   = cpu5.regfile.mem[21];   // $s5 = R21
assign s6   = cpu5.regfile.mem[22];   // $s6 = R22
assign s7   = cpu5.regfile.mem[23];   // $s7 = R23
assign t8   = cpu5.regfile.mem[24];   // $t8 = R24
assign t9   = cpu5.regfile.mem[25];   // $t9 = R25
assign k0   = cpu5.regfile.mem[26];   // $k0 = R26
assign k1   = cpu5.regfile.mem[27];   // $k1 = R27
assign gp   = cpu5.regfile.mem[28];   // $gp = R28
assign sp   = cpu5.regfile.mem[29];   // $sp = R29
assign fp   = cpu5.regfile.mem[30];   // $fp = R30
assign ra   = cpu5.regfile.mem[31];   // $ra = R31

// Memory Assign Statements
assign mem0 = cpu5.d_memory.mem[0];
assign mem1 = cpu5.d_memory.mem[1];
assign mem2 = cpu5.d_memory.mem[2];
assign mem3 = cpu5.d_memory.mem[3];
assign mem4 = cpu5.d_memory.mem[4];
assign mem5 = cpu5.d_memory.mem[5];
assign mem6 = cpu5.d_memory.mem[6];
assign mem7 = cpu5.d_memory.mem[7];
assign mem8 = cpu5.d_memory.mem[8];
assign mem9 = cpu5.d_memory.mem[9];
assign mem10 = cpu5.d_memory.mem[10];
assign mem11 = cpu5.d_memory.mem[11];
assign mem12 = cpu5.d_memory.mem[12];
assign mem13 = cpu5.d_memory.mem[13];
assign mem14 = cpu5.d_memory.mem[14];
assign mem15 = cpu5.d_memory.mem[15];
assign mem16 = cpu5.d_memory.mem[16];
assign mem17 = cpu5.d_memory.mem[17];
assign mem18 = cpu5.d_memory.mem[18];
assign mem19 = cpu5.d_memory.mem[19];
assign mem20 = cpu5.d_memory.mem[20];

   // Exception monitoring 
   always @(*)
   begin 
      if ((rst_ == 1'b1) && (exception == 1'b1) && (halt == 1'b0))
         $display("Illegal Instruction detected @ cycle %d at time %0t", counter, $time);
   end

   // Halt detection - end simulation when cpu5 halts
   always @(posedge clk)
   begin
      if (halt == 1'b1) begin
         $display("cpu5 halted at cycle %d at time %0t", counter, $time);
         
         // Display register contents before finishing
         $display("\n=== Final Register File Contents ===");
         for (integer index = 0; index < 32; index++)
            $display("Register %2d (x%2d): %h", index, index, cpu5.regfile.mem[index]);
         
         $display("\n=== Final cpu5 State ===");
         $display("PC Address: %h", cpu5.pc_addr);
         $display("Total Cycles: %d", counter);
         $display("Simulation ended at time: %0t", $time);
         
         #10; // Small delay before finishing
         $finish;
      end
   end

   // Cycle counter and exception/halt handling
   always @(negedge clk)
   begin
     if (rst_ == 1'b1) begin
       counter <= counter + 1;
       // Optional: Display cycle information for debugging 
       if (counter % 100 == 0 && counter > 0)
         $display("Completed %d cycles", counter);
     end

     if (halt || exception) begin
       $display("Simulation ending due to %s at cycle %d", 
                halt ? "halt" : "exception", counter);
       
       // Display register contents before finishing (if not already displayed)
       if (halt) begin
         $display("\n=== Final Register File Contents ===");
         for (integer index = 0; index < 32; index++)
            $display("Register %2d (x%2d): %h", index, index, cpu5.regfile.mem[index]);
         
         $display("\n=== Final cpu5 State ===");
         $display("PC Address: %h", cpu5.pc_addr);
         $display("Total Cycles: %d", counter);
         $display("Simulation ended at time: %0t", $time);
       end
       
       #5;
       $finish;
     end
   end

   // Watchdog timer to prevent infinite loops
   initial begin
     #10000; // Wait for 100,000 time units
     $display("Watchdog timeout - ending simulation");
     $finish;
   end

   integer miss_count = 0;
   integer replacement_count = 0;

   always @(posedge clk) begin
       if (rst_) begin 

           if (cpu5.ca_ctrl.state == 0 && !cpu5.ca_ctrl.cache_hit && !cpu5.ca_ctrl.branch_or_jump) begin
               
               miss_count++;

               if (cpu5.ca_ctrl.cache_full) begin
                   replacement_count++;
               end
           end
       end
   end
/*
always @(posedge clk or negedge rst_) begin
  if (!rst_) begin
    miss_count        <= 0;
    replacement_count <= 0;
  end else begin
    if (cpu5.ca_ctrl.state == 0 && !cpu5.ca_ctrl.cache_hit && !cpu5.ca_ctrl.branch_or_jump) begin
      miss_count++;
      if (cpu5.ca_ctrl.cache_full)
        replacement_count++;
    end
  end
end*/

   // Dump register file contents at end of simulation
   final
   begin
     $display("\n=== Final Register File Contents ===");
     for (integer index = 0; index < 32; index++)
        $display("Register %2d (x%2d): %h", index, index, cpu5.regfile.mem[index]);

     $display("\n=== Final cpu5 State ===");
     $display("PC Address: %h", cpu5.pc_addr);
     $display("Total Cycles: %d", counter);
     $display("Simulation ended at time: %0t", $time);
     $display("Total Misses:       %0d", miss_count);
     $display("Total Replacements: %0d", replacement_count);
   end

   initial
   begin
     $dumpfile("cpu5_waves.vcd");      // dump the waves to view on your laptop
     $dumpvars(0, top_cpu5);           // dump all variables in this module
     $display("Waveform dumping enabled - output file: cpu5_waves.vcd");
   end

endmodule
