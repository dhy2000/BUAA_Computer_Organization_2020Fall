/* 
 *  Overview: Macro defines of behaviors on exception (and interrupt)
 */

`ifndef INC_EXCEPTION
`define INC_EXCEPTION

/* ---- CP0 Control the PipeLine ---- */
`define WIDTH_KCTRL     2
`define TYPE_KCTRL      [`WIDTH_KCTRL-1:0]
`define KCTRL_NONE      0
`define KCTRL_KTEXT     1
`define KCTRL_ERET      2


/* ---- Exception Codes ---- */
`define EXC_ADEL        4
`define EXC_ADES        5
`define EXC_RI          10
`define EXC_OV          12

/* ---- Support Switch ---- */
`define SUPPORT_EXC     1

`endif