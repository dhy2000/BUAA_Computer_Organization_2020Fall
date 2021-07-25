/* 
 *  Overview: Macro defines of behaviors on exception (and interrupt)
 */

`ifndef INC_EXCEPTION
`define INC_EXCEPTION

/* ---- Exception Control Signal ---- */
`define WIDTH_ECTRL     2
`define TYPE_ECTRL      [`WIDTH_ECTRL-1:0]
`define E_NONE      0
`define E_ENTRY     1
`define E_ERET      2


/* ---- Exception Codes ---- */
`define TYPE_EXC        [6:2]

`define EXC_ADEL        4
`define EXC_ADES        5
`define EXC_RI          10
`define EXC_OV          12

`endif