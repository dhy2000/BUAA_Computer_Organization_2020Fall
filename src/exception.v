/* 
 *  File Name: exception.v
 *  Description: Macro defines of behaviors on exception (and interrupt)
 */

`ifndef EXCEPTION_DECLARATION_INCLUDED
`define EXCEPTION_DECLARATION_INCLUDED

/* ---- CP0 Control the PipeLine ---- */
`define WIDTH_KCTRL     2
`define KCTRL_NONE      0
`define KCTRL_KTEXT     1
`define KCTRL_ERET      2


/* ---- Exception Codes ---- */
`define EXC_ADEL        4
`define EXC_ADES        5
`define EXC_RI          10
`define EXC_OV          12


`endif