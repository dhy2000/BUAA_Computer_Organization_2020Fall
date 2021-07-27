`default_nettype none
`include "../include/memory.v"

/*
 *  Overview: General Register File, with 2 read ports and 1 write port
 */
module GRF (
    input wire clk,
    input wire reset,
    // Read Port 1
    input wire `TYPE_REG RAddr1,
    output wire `WORD RData1,
    // Read Port 2
    input wire `TYPE_REG RAddr2,
    output wire `WORD RData2,
    // Write Port
    input wire en, // control by pipeline
    input wire `WORD WPC,
    input wire WEn,
    input wire `TYPE_REG WAddr,
    input wire `WORD WData
);
    
    reg `WORD grf [0: 31];

    // Read
    assign RData1 = ((WAddr != 0) && (RAddr1 == WAddr)) ? WData : grf[RAddr1];
    assign RData2 = ((WAddr != 0) && (RAddr2 == WAddr)) ? WData : grf[RAddr2];

    // Write
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i <= 31; i = i + 1) begin
                grf[i] <= 0;
            end
        end
        else begin
            if (en & WEn & (WAddr != 0)) begin
                grf[WAddr] <= WData;
                $display("%d@%h: $%d <= %h", $time, WPC, WAddr, WData);
            end
        end
    end

endmodule
