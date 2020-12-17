/* 
 * File Name: memconfig.h
 * Description: Macro defines of configuration for Memories.
 */

`ifndef MEMORY_CONFIGURATION_INCLUDED
`define MEMORY_CONFIGURATION_INCLUDED

/* ------ DATA MEMORY ------ */
`define DATA_STARTADDR      32'h0000_0000
`define WIDTH_DM_ADDR_WORD  12  // 12: 4096 * 4 Bytes
`define WIDTH_DM_ADDR       (`WIDTH_DM_ADDR_WORD + 2)
`define DM_SIZE_WORD        (1 << `WIDTH_DM_ADDR_WORD)
`define DM_SIZE             (`DM_SIZE_WORD << 2)
`define DATA_ENDADDR        32'h0000_2ffc

/* ------ TEXT MEMORY ------ */
`define TEXT_STARTADDR      32'h0000_3000
`define WIDTH_IM_ADDR_WORD  12  // 12: 4096 * 4 Bytes
`define WIDTH_IM_ADDR       (`WIDTH_IM_ADDR_WORD + 2)
`define IM_SIZE_WORD        (1 << `WIDTH_IM_ADDR_WORD)
`define IM_SIZE             (`IM_SIZE_WORD << 2)
`define TEXT_ENDADDR        32'h0000_4ffc
/* ------ Exception Handler ------ */
`define KTEXT_STARTADDR 32'h0000_4180
`define KTEXT_ENDADDR   32'h0000_4ffc

`define CODE_FILE       "code.txt"  // hextext
`define HANDLER_FILE    "code_handler.txt" // hextext


/* ------ Device Address ------ */
`define TIMER0_STARTADDR    32'h0000_7F00
`define TIMER0_ENDADDR      32'h0000_7F08

`define TIMER1_STARTADDR    32'h0000_7F10
`define TIMER1_ENDADDR      32'h0000_7F18



`endif