/* Memory Config */

`ifndef MEMORY_CONFIGURATION_INCLUDED
`define MEMORY_CONFIGURATION_INCLUDED

`define DATA_STARTADDR 0
`define TEXT_STARTADDR 'h3000
`define HEXCODE_FILE "code.txt"

// DM_SIZE = 1 << (DM_ADDR_WIDTH + 2)
`define DM_ADDR_WIDTH 12 // byte address
`define DM_SIZE 1024 // 1 << 10, word size
`define IM_ADDR_WIDTH 12 // byte address
`define IM_SIZE 1024 // 1 << 10, word size

`endif
