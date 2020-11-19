/*
 *  File Name: RegWriteSel.v
 *  Module: RegWriteSel
 *  Input: addrRt, addrRd
 *  Output: RegWriteAddr
 */

`default_nettype none
`include "instructions.v"
`include "IC.v"

module RegWriteSel (
    /* Input */
    // Control
    input wire [`WIDTH_INSTR-1:0] instr,
    // Data Source
    input wire [4:0] addrRt, 
    input wire [4:0] addrRd,
    /* Output */
    output wire [4:0] regWriteAddr
);
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));
    // This module contains only a MUX
    assign regWriteAddr = (format == `FORMAT_R) ? addrRd : addrRt;
endmodule