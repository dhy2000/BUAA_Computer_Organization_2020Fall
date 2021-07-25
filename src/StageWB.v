/* 
 *  File Name: StageWB.v
 *  Module: ExtDM, (External) GRF
 *  Description: Top module of pipeline stage WB.
 */
`default_nettype none
`include "include/instructions.v"

module EXTDM (
    input wire [31:0] memWord, 
    input wire [1:0] offset, 
    input wire [`WIDTH_INSTR-1:0] instr, 
    input wire `TYPE_IFUNC ifunc,
    output wire [31:0] extWord
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


module StageWB (
    /* Data Inputs from Previous Pipeline */
    input wire [`WIDTH_INSTR-1:0]   instr_WB            , 
    input wire `TYPE_IFUNC          ifunc_WB             ,
    input wire [31:0]               PC_WB               , 
    input wire [31:0]               memWord_WB          ,
    input wire [1:0]                offset_WB           ,
    input wire [4:0]                regWriteAddr_WB     , 
    input wire [31:0]               regWriteData_WB     ,
    input wire                      dis_GRF             ,
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
        .instr(instr_WB), .ifunc(ifunc_WB),
        .extWord(extMemWord)
    );


    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_INSTR-1:0] instr;
    assign instr = instr_WB;
    wire `TYPE_IFUNC ifunc;
    assign ifunc = ifunc_WB;


    assign regWriteAddr = (dis_GRF) ? 0 : regWriteAddr_WB;
    assign regWriteData = (
        ((ifunc == `I_MEM_R)) ? (extMemWord) : 
        (regWriteData_WB)
    );

    /* ------ Part 3: Pipeline Registers ------ */
    assign regWriteAddr_GRF = regWriteAddr;
    assign regWriteData_GRF = regWriteData;
    assign PC_GRF = PC_WB;

endmodule
