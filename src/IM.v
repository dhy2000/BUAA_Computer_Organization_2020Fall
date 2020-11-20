/*
 *  File Name: IM.v
 *  Module: IM
 *  Inputs: PC
 *  Outputs: Hex Code of Instruction
 *  Description: Instruction Memory
 */

`default_nettype none

`include "memconfig.v"

module IM (
    input wire [31:0] PC,
    output wire [31:0] code
);
    // Memory
    reg [31:0] mem [0: `IM_SIZE_WORD - 1];
    wire [31:0] baseAddr;
    assign baseAddr = PC - `TEXT_STARTADDR;
    wire [`WIDTH_IM_ADDR-1:2] wordIndex;
    assign wordIndex = baseAddr[`WIDTH_IM_ADDR-1:2];

    wire [31:0] memword;
    assign memword = (PC >= `TEXT_STARTADDR && PC < (`TEXT_STARTADDR + `IM_SIZE)) ? mem[wordIndex] : 0;

    assign code = memword;

    initial begin
        $readmemh(`CODE_FILE, mem);
    end

    
endmodule