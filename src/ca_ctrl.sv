module ca_ctrl
  #(
   parameter CACHE_ENTRIES = 8,            // how many entries in the cache
   parameter CACHE_ADDR_LEFT=$clog2(CACHE_ENTRIES)-1  // log2 of the number of entries
   )
  (
   output logic cache_read,              // ok to read from the cache
   output logic cache_write_,            // write to clear or set an entry
   output logic [CACHE_ADDR_LEFT:0] cache_w_addr,   // address to clear
   output logic new_valid,               // whether clearing or not
   output logic cache_stall,              // stall waiting for the cache
   
   input cache_hit,                      // cache hit (or miss)
   input cache_full,                     // cache is full
   input branch_or_jump,                 // branching or jumping
   input clk,                            // system clock
   input rst_                            // system reset
   );

   // State machine parameters
   localparam STATE_BITS = 2;
   localparam [STATE_BITS-1:0] IDLE  = 2'h0;      // Idle state
   localparam [STATE_BITS-1:0] LOAD  = 2'h1;      // Load from memory state
   localparam [STATE_BITS-1:0] CLEAR = 2'h2;      // Clear a memory location

   // State variables
   logic [STATE_BITS-1:0] state;
   logic [STATE_BITS-1:0] next_state;
   
   // Counter for determining which entry to clear 
   logic [CACHE_ADDR_LEFT:0] clear_counter;

   // State machine sequential logic
   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         state <= IDLE;
         clear_counter <= {(CACHE_ADDR_LEFT+1){1'b0}};
      end
      else begin
         state <= next_state;
         // Increment counter for next clear operation
         if (state == CLEAR)
            clear_counter <= clear_counter + 1'b1;
      end
   end

   // State machine combinational logic
   always_comb begin
      next_state = state;
 if (branch_or_jump) begin 
   next_state = IDLE;
 end else begin 
      case (state)
         IDLE: begin          
            // On cache miss
            if (!cache_hit && !branch_or_jump) begin
               if (cache_full) begin
                  next_state = CLEAR;
               end
               else begin
                  next_state = LOAD;
               end
            end
         end

         LOAD: begin
            next_state = IDLE;
         end

         CLEAR: begin
            // After clearing, go to LOAD to fetch from memory
            next_state = LOAD;
         end

         default: begin
            next_state = IDLE;
         end
      endcase
     end
   end
   // State machine combinational logic
   always_comb begin
      cache_read = 1'b1;
      cache_write_ = 1'b1;
      cache_w_addr = clear_counter;
      new_valid = 1'b0;
      cache_stall = 1'b0;

      case (state)
         IDLE: begin
            cache_read = 1'b1;
            cache_write_ = 1'b1;
            cache_stall = 1'b0;
            
            // On cache miss
            if (!cache_hit && !branch_or_jump) begin
                  cache_stall = 1'b1;
            end
         end

         LOAD: begin
            // Load state: waiting for data from memory to cache
            // Memory read takes 1 cycle, write to cache takes 1 cycle
            cache_read = 1'b0;
            cache_write_ = 1'b0;
            cache_w_addr = {(CACHE_ADDR_LEFT+1){1'b0}};  // Write to first available
            new_valid = 1'b1;
            cache_stall = 1'b1;
         end

         CLEAR: begin
            // Clear state: clearing an entry to make room for new instruction
            // Takes 1 cycle to clear the entry
            cache_read = 1'b0;
            cache_write_ = 1'b0;
            cache_w_addr = clear_counter;
            new_valid = 1'b0;  // Invalidate the entry being cleared
            cache_stall = 1'b1;
         end
      endcase
   end

endmodule

