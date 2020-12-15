`ifndef CPU_WB_TOP_INCLUDED
`define CPU_WB_TOP_INCLUDED
/* 
 *  File Name: WB_LEVEL.v
 *  Module: (External) GRF
 *  Description: Just Send Data and Instr into GRF
 */
`default_nettype none
`include "CPU/instructions.v"
`include "CPU/IC.v"
`include "CPU/WB/EXTDM.v"

module WB_TOP (
    /* Data Inputs from Previous Pipeline */
    input wire [`WIDTH_INSTR-1:0]   instr_WB            , 
    input wire [31:0]               PC_WB               , 
    input wire [31:0]               memWord_WB          ,
    input wire [1:0]                offset_WB           ,
    input wire [4:0]                regWriteAddr_WB     , 
    input wire [31:0]               regWriteData_WB     ,
    // input wire [`WIDTH_T-1:0]       Tnew_WB             ,
    /* Data Outputs to GRF.Write */
    output wire [4:0] regWriteAddr_GRF, 
    output wire [31:0] regWriteData_GRF,
    output wire [31:0] PC_GRF
);
    /*
        Modules included: 
            GRF(external)
        (Pseudo) Modules:
            
    */
    /* ------ Part 1: Wires Declaration ------ */
    wire [31:0] extMemWord;

    wire [4:0] regWriteAddr;
    wire [31:0] regWriteData;

    /* ------ Part 2: Instantiate Modules ------ */

    EXTDM extdm (
        .memWord(memWord_WB), 
        .offset(offset_WB), 
        .instr(instr_WB), 
        .extWord(extMemWord)
    );


    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_INSTR-1:0] instr;
    assign instr = instr_WB;
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));


    assign regWriteAddr = regWriteAddr_WB;
    assign regWriteData = (
        ((func == `FUNC_MEM_READ)) ? (extMemWord) : 
        (regWriteData_WB)
    );

    /* ------ Part 3: Pipeline Registers ------ */
    assign regWriteAddr_GRF = regWriteAddr;
    assign regWriteData_GRF = regWriteData;
    assign PC_GRF = PC_WB;

endmodule
`endif
