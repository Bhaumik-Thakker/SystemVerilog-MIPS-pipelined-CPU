localparam BITS      = 32;
localparam I_MEM_WORDS  = 1024;
localparam D_MEM_WORDS  = 1024;
localparam I_MEM_BASE_ADDR = 0;
localparam D_MEM_BASE_ADDR = 32'h4000_0000;
localparam REG_WORDS  = 32;
localparam REG_ADDR_LEFT=$clog2(REG_WORDS)-1; // log base 2 of the number of words
                                              // which is # of bits needed to address
                                              // the memory for read and write
localparam SHIFT_BITS=5;                      // bits needed to define shift amount

localparam OP_BITS    = 4;
localparam JMP_LEFT   = 25;
localparam IMM_LEFT = BITS / 2;               // number of bits in immediate field
