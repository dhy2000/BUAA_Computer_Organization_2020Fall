/* 
 *  Overview: Macro defines of configuration for Memories.
 */

`ifndef INC_MEMORY_CONFIGURATION
`define INC_MEMORY_CONFIGURATION

/* ------ Memory Address ------ */
/* DM */
`define DM_ADDR_START       32'h0000_0000
`define DM_WORDNUM_WIDTH    12          // 4096 Words
`define DM_ADDR_WIDTH       (`DM_WORDNUM_WIDTH + 2)
`define DM_WORDNUM          (1 << `DM_WORDNUM_WIDTH)
`define DM_SIZE             (`DM_WORDNUM << 2)
`define DM_ADDR_END         32'h0000_3000

/* IM */
`define IM_ADDR_START       32'h0000_3000
`define IM_WORDNUM_WIDTH    12          // 4096 Words
`define IM_ADDR_WIDTH       (`IM_WORDNUM_WIDTH + 2)
`define IM_WORDNUM          (1 << `IM_WORDNUM_WIDTH)
`define IM_SIZE             (`IM_WORDNUM << 2)
`define IM_ADDR_END         32'h0000_5000

/* ------ Segments ------*/
`define PC_BOOT             32'h0000_3000

`define KTEXT_START         32'h0000_4180
`define KTEXT_END           32'h0000_4ffc // [start, end)

/* ------ Memory Initialize ------ */
`define CODE_FILE           "code.txt"  // hextext
`define HANDLER_FILE        "code_handler.txt" // hextext


/* ------ Device Address ------ */
`define TIMER0_ADDR_START    32'h0000_7F00
`define TIMER0_ADDR_END      32'h0000_7F0B

`define TIMER1_ADDR_START    32'h0000_7F10
`define TIMER1_ADDR_END      32'h0000_7F1B

`endif