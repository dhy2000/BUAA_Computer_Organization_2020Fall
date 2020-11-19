/* -------- Data Memory -------- */

`default_nettype none
`include "instructions.v"
`include "memconfig.v"

module DM (
    // input
    // time sequential
    input wire clk, 
    input wire rst, 
    // addr and data
    input wire [31:0] Addr, 
    input wire [31:0] WData, 
    // controls
    input wire [`InstrID_WIDTH-1:0] Instr, 
    input wire [31:0] pc, 
    // outputs
    output wire [31:0] RData
);
// Parameters
parameter   ZERO_EXT = 0,
            SIGN_EXT = 1
;
parameter   UNIT_WORD = 0,
            UNIT_HALF = 1,
            UNIT_BYTE = 2
;

    // define memory
    reg [31:0] mem [0: `DM_SIZE - 1];

    task resetMem;
        integer i;
        begin
            for (i = 0; i <= `DM_SIZE - 1; i = i + 1) begin
                mem[i] <= 0;
            end
        end
    endtask

    wire [`DM_ADDR_WIDTH-3:0] word_addr;
    assign word_addr = Addr[`DM_ADDR_WIDTH-1:2];
    wire [31:0] word;
    assign word = mem[word_addr];
    // byte and halfword
    wire [1:0] byte_offset;
    wire halfword_offset;
    assign byte_offset = Addr[1:0];
    assign halfword_offset = Addr[1];
    // lh, lb
    function [7:0] fetchByteFromWord;
        input [31:0] word;
        input [1:0] offset;
        begin
            fetchByteFromWord = word[offset*8+:8];
        end
    endfunction
    function [15:0] fetchHalfFromWord;
        input [31:0] word;
        input offset;
        begin
            fetchHalfFromWord = word[offset*16+:16];
        end
    endfunction
    // lhu, lbu
    function [31:0] extByte;
        input [7:0] byte;
        input extop;
        begin
            if (extop == ZERO_EXT)
                extByte = {24'b0, byte};
            else 
                extByte = {{24{byte[7]}}, byte};
        end
    endfunction
    function [31:0] extHalfWord;
        input [15:0] halfword;
        input extop;
        begin
            if (extop == ZERO_EXT)
                extHalfWord = {16'b0, halfword};
            else 
                extHalfWord = {{16{halfword[15]}}, halfword};
        end
    endfunction
    // sh, sb
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
        input [15:0] halfword;
        input offset;
        begin
            replaceHalfToWord = word;
            replaceHalfToWord[offset*16+:16] = halfword;
        end
    endfunction

    /* Control Part */
    wire WEnable;
    wire [1:0] unit; 
    wire extop;
    assign WEnable = (
        (Instr == `SW) || (Instr == `SH) || (Instr == `SB)
    );
    assign unit = (
        ((Instr == `LW) || (Instr == `SW)) ? (UNIT_WORD) :
        ((Instr == `LH) || (Instr == `LHU) || (Instr == `SH)) ? (UNIT_HALF) : 
        ((Instr == `LB) || (Instr == `LBU) || (Instr == `SB)) ? (UNIT_BYTE) :
        (UNIT_WORD) // default
    );
    assign extop = (
        ((Instr == `LHU) || (Instr == `LBU)) ? (ZERO_EXT) : (SIGN_EXT)
    );

    task writeWordToMem;
        input [`DM_ADDR_WIDTH-3:0] wordaddr;
        input [31:0] worddata;
        input [31:0] pc;
        reg [31:0] writeaddr;
        begin
            writeaddr = wordaddr;
            writeaddr = writeaddr << 2;
            $display("@%h: *%h <= %h", pc, writeaddr, worddata);
            mem[wordaddr] <= worddata;
        end
    endtask

    /* Read Result: Combinatial*/
    assign RData = (
        (unit == UNIT_WORD) ? (word) : 
        (unit == UNIT_HALF) ? (extHalfWord(fetchHalfFromWord(word, halfword_offset), extop)) : 
        (unit == UNIT_BYTE) ? (extByte(fetchByteFromWord(word, byte_offset), extop)) : 
        (word) // default
    );

    /* Write Result: Sequential */
    wire [31:0] wordToWrite;
    assign wordToWrite = (
        (unit == UNIT_WORD) ? (WData) : 
        (unit == UNIT_HALF) ? (replaceHalfToWord(word, WData[15:0], halfword_offset)) : 
        (unit == UNIT_BYTE) ? (replaceByteToWord(word, WData[7:0], byte_offset)) : 
        (WData) // default
    );



    // initialize
    initial begin
        resetMem;
    end

    /* Time Sequence Logic */
    always @(posedge clk /* or posedge rst */ ) begin
        if (rst) begin
            resetMem;
        end
        else begin
            if (WEnable) begin
                writeWordToMem (word_addr, wordToWrite, pc);
            end
        end
    end

    
endmodule


