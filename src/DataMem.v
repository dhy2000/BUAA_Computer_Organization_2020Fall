/* 
 * File Name: DataMem.v
 * Module Name: DataMem
 * Description: Data Memory
 */
`default_nettype none

`include "memconfig.v"

module DataMem (
    input wire clk_m, 
    input wire rst_n, 
    input wire [31:0] PC, 
    input wire [31:2] Addr,  // word-aligned, start at 0
    input wire [31:0] WData, 
    input wire [3:0] WE,    // Write Enable per Byte
    output wire [31:0] RData
);

    reg [31:0] mem [0: `DM_SIZE_WORD - 1];

    wire [`WIDTH_DM_ADDR-1:2] wordAddr;
    assign wordAddr = Addr[`WIDTH_DM_ADDR-1:2];

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
            for (i = 0; i < `DM_SIZE_WORD; i = i + 1) begin
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

    always @(posedge clk_m or negedge rst_n) begin
        if (!rst_n) begin
            resetMem;
        end
        else begin
            if (|WE) begin
                writeWordToMem;
            end
        end
    end
endmodule
