/* 
 * File Name: memconfig.h
 * Description: Macro defines of configuration for Memories.
 */

`ifndef MEMORY_CONFIGURATION_INCLUDED
`define MEMORY_CONFIGURATION_INCLUDED

/* ------ DATA MEMORY ------ */
`define DATA_STARTADDR  32'h0000_0000
`define WIDTH_DM_ADDR_WORD  12  // 10: 1024 * 4 Bytes
`define WIDTH_DM_ADDR       (`WIDTH_DM_ADDR_WORD + 2)
`define DM_SIZE_WORD        (1 << `WIDTH_DM_ADDR_WORD)
`define DM_SIZE             (`DM_SIZE_WORD << 2)

/* ------ TEXT MEMORY ------ */
`define TEXT_STARTADDR  32'h0000_3000
`define WIDTH_IM_ADDR_WORD  10  // 10: 1024 * 4 Bytes
`define WIDTH_IM_ADDR       (`WIDTH_IM_ADDR_WORD + 2)
`define IM_SIZE_WORD        (1 << `WIDTH_IM_ADDR_WORD)
`define IM_SIZE             (`IM_SIZE_WORD << 2)

`define CODE_FILE       "code.txt"  // hextext



`endif