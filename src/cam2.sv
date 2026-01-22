// Cache using cam2
module cam2
  #(
   parameter WORDS=8,                   // default number of words
   parameter BITS=8,                    // default number of bits per word
   parameter ADDR_LEFT=$clog2(WORDS)-1, // log base 2 of the number of words
                                        // which is # of bits needed to address
                                        // the memory for read and write
   parameter TAG_SZ=8                   // size of the tag
   )
   (
   output logic [BITS-1:0]    cache_data,  // the data
   output logic               cache_hit,   // was in the cam2
   output logic               cache_full,  // if CAM is full

   input  [TAG_SZ-1:0]        check_tag,   // the tag to match
   input                      read,        // read signal

   input                      write_,      // write_ signal
   input  [ADDR_LEFT:0]       w_addr,      // address to write
   input  [BITS-1:0]          wdata,       // data to write
   input  [TAG_SZ-1:0]        new_tag,     // the new tag
   input                      new_valid,   // new valid bit

   input                      clk,         // system clock
   input                      rst_         // system reset
   );

   `include "cam_params.vh"

   logic [BITS-1:0]   data_mem[0:WORDS-1]; // data memory
   logic [TAG_SZ-1:0] tag_mem[0:WORDS-1];  // tag memory
   logic [WORDS-1:0]  val_mem;             // valid memory

   integer rst_idx;                        // for the loop
   logic [ADDR_LEFT:0] match_index;        // where we found it
   logic found;                            // did we find it 
   integer index;
 
   integer windex;                         // for write search loop
   logic [ADDR_LEFT:0] write_index;        // Where we found an empty spot
   logic write_found;                      // found an empty spot

 always @(posedge clk or negedge rst_)
  begin
    if (!rst_)                             // Active-low reset
    begin
                                           // On reset, initialize all entries to be invalid
      for (rst_idx = 0; rst_idx < WORDS; rst_idx = rst_idx + 1)
      begin
        val_mem[rst_idx] <= 1'b0;
                                           // Clear memory
        data_mem[rst_idx] <= {BITS{1'b0}};
        tag_mem[rst_idx]  <= {TAG_SZ{1'b0}};
      end
    end
    else if (!write_)                      // Active-low write enable 
    begin
     if (new_valid) begin
      if (!cache_full) begin
                                          // Write the new tag, data, and valid bit to the specified address
      data_mem[write_index] <= wdata;    
      tag_mem[write_index]  <= new_tag;  
      val_mem[write_index]  <= 1'b1;
      end
    end
    else begin 
     val_mem[w_addr] <= 1'b0;
     data_mem[w_addr] <= {BITS{1'b0}};
     tag_mem[w_addr] <= {TAG_SZ{1'b0}};
    end
  end
 end

  always @ ( * ) begin
    found = 1'b0;
    match_index = INDEX[0][ADDR_LEFT:0];
   if (read) begin
    for ( index = 0 ; index < WORDS ; index++ )
    begin
       if ( val_mem[index] && ( tag_mem[index] == check_tag ) )
       begin
         match_index = INDEX[index][ADDR_LEFT:0];
         found = 1'b1;
       end
    end
   end
  end

  always @ ( * ) begin
    write_found = 1'b0;
    cache_full = 1'b1;
    write_index = INDEX[0];
    for ( windex = 0 ; windex < WORDS ; windex++ )
    begin
       if ( !val_mem[windex] && !write_found )
       begin
         //if (!write_found) begin
           write_index = INDEX[windex];
           write_found = 1'b1;
           cache_full = 1'b0;
        // end
       end
   end
  end

   assign cache_data = found ? data_mem[match_index] : { BITS { 1'b0 } };
   assign cache_hit = found;
   //assign full = !write_found ? 1'b1 : 1'b0;

endmodule
