/*
 *  File Name: DM.v
 *  Module: DM
 *  Inputs: clk, reset, instr, Addr, WData, PC
 *  Outputs: RData
 *  Description: Data Memory
 */

`default_nettype none
`include "memconfig.v"
`include "instructions.v"
`include "IC.v"

module DM (
    input wire clk,
    input wire reset,
    input wire [`WIDTH_INSTR-1:0] instr,
    input wire [31:0] Addr,
    input wire [31:0] WData,
    input wire [31:0] PC,
    output wire [31:0] RData
);
    // inner control signal
    parameter WIDTH_EXT = 1,
            EXT_Zero    = 0,
            EXT_Sign    = 1;
    parameter WIDTH_UNIT    = 2,
            UNIT_Word   = 0,
            UNIT_Half   = 1,
            UNIT_Byte   = 2;
    // memory
    reg [31:0] mem [0: `DM_SIZE_WORD - 1];

    wire [31:0] baseAddr;
    assign baseAddr = Addr - `DATA_STARTADDR;

    wire [`WIDTH_DM_ADDR-1:2] wordIndex;
    assign wordIndex = baseAddr[`WIDTH_DM_ADDR-1:2];

    wire [31:0] memword;
    assign memword = (Addr >= `DATA_STARTADDR && Addr < (`DATA_STARTADDR + `DM_SIZE)) ? mem[wordIndex] : 0;
    
    // Offsets
    wire [1:0] byte_offset; wire half_offset;
    assign byte_offset = baseAddr[1:0];
    assign half_offset = baseAddr[1];
    // halfword and byte
    wire [31:0] word; wire [15:0] half; wire [7:0] byte;
    assign word = memword;
    assign half = memword[half_offset*16+:16];
    assign byte = memword[byte_offset*8+:8];

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

    // store half/byte - insert
    function [31:0] replaceByteToWord;
        input [31:0] word;
        input [7:0] byte;
        input [1:0] offset;
        begin
            replaceByteToWord = word;
            replaceByteToWord[offset*8+:8] = byte;
        end
    endfunction
    function [31:0] replaceHalfToWord;
        input [31:0] word;
        input [15:0] half;
        input offset;
        begin
            replaceHalfToWord = word;
            replaceHalfToWord[offset*16+:16] = half;
        end
    endfunction

    /* Control */
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    wire writeEn ;
    wire [1:0] unit; wire ext;
    assign writeEn = (func == `FUNC_MEM_WRITE);
    assign unit = (
        ((instr == `LW) || (instr == `SW)) ? (UNIT_Word) :
        ((instr == `LH) || (instr == `LHU) || (instr == `SH)) ? (UNIT_Half) : 
        ((instr == `LB) || (instr == `LBU) || (instr == `SB)) ? (UNIT_Byte) : 
        (UNIT_Word) // default
    );
    assign ext = (
        ((instr == `LHU) && (instr == `LBU)) ? (EXT_Zero) : (EXT_Sign)
    );

    // Execute
    // Read Data
    assign RData = (
        (unit == UNIT_Word) ? (word) : 
        (unit == UNIT_Half) ? (extHalf(half, ext)) : 
        (unit == UNIT_Byte) ? (extByte(byte, ext)) : 
        (word) // default
    );
    // Write Data
    wire [31:0] wordToWrite;
    assign wordToWrite = (
        (unit == UNIT_Word) ? (WData) : 
        (unit == UNIT_Half) ? (replaceHalfToWord(memword, WData[15:0], half_offset)) : 
        (unit == UNIT_Byte) ? (replaceByteToWord(memword, WData[7:0], byte_offset)) : 
        (WData) // default
    );

    task writeWordToMem;
        reg [31:0] writeAddr;
        begin
            writeAddr = (wordIndex << 2);
            $display("%d@%h: *%h <= %h", $time, PC, writeAddr, wordToWrite);
            mem[wordIndex] <= wordToWrite;
        end
    endtask

    task resetMem;
        integer i;
        begin
            for (i = 0; i < `DM_SIZE_WORD; i = i + 1) begin
                mem[i] <= 0;
            end
        end
    endtask


    // Time Sequential Logic

    initial begin
        resetMem;
    end

    always @(posedge clk) begin
        if (reset) begin
            resetMem;
        end
        else begin
            if (writeEn) begin
                writeWordToMem;
            end
        end
    end
    
endmodule