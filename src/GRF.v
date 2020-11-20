/*
 *  File Name: GRF.v
 *  Module: GRF
 *  Inputs: (RAddr1, RAddr2), (clk, reset, writeEn, PC, WAddr, WData)
 *  Outputs: (RData1, RData2)
 *  Description: General Register File
 */

`default_nettype none

module GRF (
    input wire clk,
    input wire reset,
    input wire [4:0] RAddr1, 
    input wire [4:0] RAddr2,
    input wire writeEn,
    input wire [4:0] WAddr,
    input wire [31:0] WData,
    input wire [31:0] PC,
    output wire [31:0] RData1,
    output wire [31:0] RData2
);
    // Memory Declaration
    reg [31:0] grf [0: 31];
    // Inner Transmit Forward
    assign RData1 = (writeEn && (RAddr1 == WAddr) && (WAddr != 0)) ? WData : grf[RAddr1];
    assign RData2 = (writeEn && (RAddr2 == WAddr) && (WAddr != 0)) ? WData : grf[RAddr2];

    task resetReg;
        integer i;
        begin
            for (i = 0; i <= 31; i = i + 1) begin
                grf[i] <= 0;
            end
        end
    endtask

    task writeToReg;
        input [4:0] addr;
        input [31:0] data;
        input [31:0] pc;
        begin
            if (addr != 0) begin
                $display($time, "@%h: $%d <= %h", pc, addr, data);
                grf[addr] <= data;
            end
            else begin
                grf[addr] <= 0;
            end
        end
    endtask

    initial begin
        resetReg;
    end

    always @(posedge clk) begin
        if (reset) begin
            resetReg;
        end
        else begin
            if (writeEn) begin
                writeToReg(WAddr, WData, PC);
            end
        end
    end

endmodule