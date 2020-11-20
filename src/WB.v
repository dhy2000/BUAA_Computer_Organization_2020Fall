/*
 *  File Name: WB.v
 *  Module: WB
 *  Description: connect to the write logic of grf, generate Write Enable signal and select Data to Write to GRF
 */

`default_nettype none

`include "instructions.v"
`include "IC.v"

module WB (
    input wire [`WIDTH_INSTR-1:0] instr,
    // GRF Write Data Source
    input wire [31:0] aluOut,
    input wire [31:0] memRead,
    input wire [31:0] PCToLink,
    // Output 
    output wire [31:0] regWriteData,
    output wire regWriteEn
);
    // Control
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign regWriteEn = (
        ((func == `FUNC_CALC_R) || (func == `FUNC_CALC_I) || (func == `FUNC_MEM_READ)) ? 1 : 
        ((instr == `JAL) || (instr == `JALR)) ? 1 : 
        0
    );
    
    assign regWriteData = (
        ((func == `FUNC_MEM_READ)) ? (memRead) : 
        ((instr == `JAL) || (instr == `JALR)) ? (PCToLink) : 
        (aluOut) // default
    );


endmodule