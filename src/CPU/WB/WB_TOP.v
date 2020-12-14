/* 
 *  File Name: WB_LEVEL.v
 *  Module: (External) GRF
 *  Description: Just Send Data and Instr into GRF
 */
`default_nettype none
`include "instructions.v"

module WB_TOP (
    /* Data Inputs from Previous Pipeline */
    input wire [`WIDTH_INSTR-1:0]   instr_WB            , 
    input wire [31:0]               PC_WB               , 
    input wire [31:0]               memReadData_WB      ,
    input wire [4:0]                regWriteAddr_WB     , 
    input wire [31:0]               regWriteData_WB     ,
    /* Data Outputs to GRF.Write */
    // output wire writeEn_GRF, 
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


    /* ------ Part 2: Instantiate Modules ------ */
    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_INSTR-1:0] instr;
    assign instr = instr_WB;
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    /* ------ Part 3: Pipeline Registers ------ */
    assign regWriteAddr_GRF = regWriteAddr_WB;
    assign regWriteData_GRF = regWriteData_WB;
    assign PC_GRF = PC_WB;

endmodule