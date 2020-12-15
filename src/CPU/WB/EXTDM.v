`ifndef CPU_WB_EXTDM_INCLUDED
`define CPU_WB_EXTDM_INCLUDED

`default_nettype none
`include "CPU/instructions.v"
`include "CPU/IC.v"

module EXTDM (
    input wire [31:0] memWord, 
    input wire [1:0] offset, 
    input wire [`WIDTH_INSTR-1:0] instr, 
    output wire [31:0] extWord
);
    parameter   UNIT_Word   = 0,
                UNIT_Half   = 1,
                UNIT_Byte   = 2;
    parameter   EXT_Zero = 0,
                EXT_Sign = 1;

    wire [1:0] unit;
    wire extop;

    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));
    assign extop = (
        ((instr == `LHU) || (instr == `LBU)) ? (EXT_Zero) : (EXT_Sign)
    );
    assign unit = (
        ((instr == `LW) || (instr == `SW)) ? (UNIT_Word) :
        ((instr == `LH) || (instr == `LHU) || (instr == `SH)) ? (UNIT_Half) : 
        ((instr == `LB) || (instr == `LBU) || (instr == `SB)) ? (UNIT_Byte) : 
        (UNIT_Word) // default
    );

    wire [15:0] halfword;
    assign halfword = memWord[offset[1] * 16 +: 16];
    wire [7:0] byte;
    assign byte = memWord[offset * 8 +: 8];

    // extend
    function [31:0] extByte;
        input [7:0] byte;
        input ext;
        begin
            if (ext == EXT_Zero)
                extByte = {24'b0, byte};
            else 
                extByte = {{24{byte[7]}}, byte};
        end
    endfunction
    function [31:0] extHalf;
        input [15:0] half;
        input ext;
        begin
            if (ext == EXT_Zero) 
                extHalf = {16'b0, half};
            else 
                extHalf = {{16{half[15]}}, half};
        end
    endfunction


    assign extWord = (
        (unit == UNIT_Word) ? (memWord) : 
        (unit == UNIT_Half) ? (extHalf(halfword, extop)) : 
        (unit == UNIT_Byte) ? (extByte(byte, extop)) : 
        (memWord) // default
    );
    
endmodule

`endif
