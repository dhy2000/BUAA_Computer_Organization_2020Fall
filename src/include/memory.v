/* 
 *  Overview: Macro defines of configuration for Memories.
 */

`ifndef INC_MEMORY
`define INC_MEMORY

/* ------ Mem Unit ------ */
`define WIDTH_WORD          32
`define WORD                [`WIDTH_WORD - 1 : 0]
`define BYTE                [7:0]

/* ------ Registers ------ */
`define WIDTH_REG           5
`define TYPE_REG            [`WIDTH_REG - 1 : 0]

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
// Timer0
`define TIMER0_ADDR_START   32'h0000_7F00
`define TIMER0_ADDR_END     32'h0000_7F0B

`define TIMER0_CTRL         32'h0000_7F00   // R/W, Word
`define TIMER0_PRESET       32'h0000_7F04   // R/W, Word
`define TIMER0_COUNT        32'h0000_7F08   // R,   Word

// Timer1
`define TIMER1_ADDR_START   32'h0000_7F10
`define TIMER1_ADDR_END     32'h0000_7F1B

`define TIMER1_CTRL         32'h0000_7F10   // R/W, Word
`define TIMER1_PRESET       32'h0000_7F14   // R/W, Word
`define TIMER1_COUNT        32'h0000_7F18   // R/W, Word

`endif