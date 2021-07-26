`default_nettype none

`include "include/memconfig.v"

module DM (
    input wire clk, 
    input wire reset, 
    input wire [31:0] PC, 
    input wire [31:2] Addr,  // word-aligned, start at 0
    input wire [31:0] WData, 
    input wire [3:0] WE,    // Write Enable per Byte
    output wire [31:0] RData
);

    reg [31:0] mem [0: `DM_WORDNUM - 1];

    wire [`DM_ADDR_WIDTH-1:2] wordAddr;
    assign wordAddr = Addr[`DM_ADDR_WIDTH-1:2];

    wire [31:0] memword;
    assign memword = mem[wordAddr];
    assign RData = memword;

    function [31:0] replaceWord;
        input [31:0] memword;
        input [31:0] writedata;
        input [3:0] we;
        integer i;
        begin
            replaceWord = 0;
            for (i = 0; i <= 3; i = i + 1) begin
                if (we[i]) begin
                    replaceWord[i*8+:8] = writedata[i*8+:8];
                end
                else begin
                    replaceWord[i*8+:8] = memword[i*8+:8];
                end
            end
        end
    endfunction

    wire [31:0] wordToWrite;
    assign wordToWrite = replaceWord(memword, WData, WE);

    task resetMem;
        integer i;
        begin
            for (i = 0; i < `DM_WORDNUM; i = i + 1) begin
                mem[i] <= 0;
            end
        end
    endtask

    task writeWordToMem;
        reg [31:0] writeAddr;
        begin
            writeAddr = (wordAddr << 2);
            $display("%d@%h: *%h <= %h", $time, PC, writeAddr, wordToWrite);
            mem[wordAddr] <= wordToWrite;
        end
    endtask

    initial begin
        resetMem;
    end

    always @(posedge clk) begin
        if (reset) begin
            resetMem;
        end
        else begin
            if (|WE) begin
                writeWordToMem;
            end
        end
    end
endmodule
