/*
 *  Overview: Pipeline stage W (Write back)
 */

`default_nettype none
`include "../include/instructions.v"
`include "../include/exception.v"
`include "../include/memory.v"

/*
 *  Overview: select byte/halfword from memory word and extend the selected byte/halfword into a word.
 *  Input:
 *      - Mem read instruction
 *      - Word read from memory
 *      - Offset in a word
 *  Output:
 *      - Selected and extended word
 */
module EXTDM (
    input wire `WORD memWord, 
    input wire [1:0] offset, 
    input wire `TYPE_INSTR instr, 
    input wire `TYPE_IFUNC ifunc,
    output wire `WORD extWord
);
    parameter   UNIT_Word   = 0,
                UNIT_Half   = 1,
                UNIT_Byte   = 2;
    parameter   EXT_Zero = 0,
                EXT_Sign = 1;

    wire [1:0] unit;
    wire extop;

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

module StageW (
    /* From previous stage */
    input wire `TYPE_INSTR          instr_W         ,
    input wire `TYPE_IFUNC          ifunc_W         ,
    input wire `WORD                PC_W            ,
    input wire                      regWEn_W        ,
    input wire `TYPE_REG            regWAddr_W      ,
    input wire `WORD                regWData_W      ,
    input wire                      regWValid_W     ,
    input wire `TYPE_T              Tnew_W          ,
    input wire [1:0]                offset_W        ,
    input wire `WORD                memWord_W       ,
    /* GRF Write Port */
    output wire                     regWEn,
    output wire `TYPE_REG           regWAddr,
    output wire `WORD               regWData,
    output wire `WORD               regWPC
);
    /* ------ Wires Declaration ------ */
    // instruction
    wire `TYPE_INSTR instr;
    wire `TYPE_IFUNC ifunc;
    // module output
    wire `WORD extWord;

    /* ------ Instantiate Modules ------ */
    EXTDM extdm (
        .memWord(memWord_W),
        .offset(offset_W),
        .instr(instr),
        .ifunc(ifunc),
        .extWord(extWord)
    );

    /* ------ Combinatinal Logic ------ */
    // instruction
    assign instr = instr_W;
    assign ifunc = ifunc_W;
    // reg write
    assign regWEn = regWEn_W;
    assign regWAddr = regWAddr_W;
    assign regWData = ((ifunc == `I_MEM_R) && ((instr == `LH) || (instr == `LHU) || (instr == `LB) || (instr == `LBU))) ? extWord : regWData_W;
    assign regWPC = PC_W;


endmodule