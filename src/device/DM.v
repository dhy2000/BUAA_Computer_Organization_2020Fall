`default_nettype none
`include "../include/instructions.v"
`include "../include/exception.v"
`include "../include/memory.v"

/*
 *  Overview: Data Memory
 */
module DM (
    input wire clk,
    input wire reset,
    input wire `WORD pc,
    input wire `WORD addr,
    input wire ce,
    input wire we,
    input wire re,
    input wire [3:0] be,
    input wire `WORD din,
    output wire `WORD dout,
    output wire ready
);

    // SIMULATION-ONLY model, please use BRAM IPCORE if synthesis needed.
    reg `WORD mem [0 : `DM_WORDNUM - 1];
    wire `WORD bitmask = {{8{be[3]}}, {8{be[2]}}, {8{be[1]}}, {8{be[0]}}};

    wire `WORD dwrite = (mem[addr] & (~bitmask)) | (din & bitmask);

    assign dout = mem[addr];
    assign ready = 1'b1;

    integer i;
    
    initial begin
        for (i = 0; i < `DM_WORDNUM; i = i + 1) begin
            mem[i] <= 0;
        end
    end

    always @ (posedge clk) begin
        if (reset) begin
            for (i = 0; i < `DM_WORDNUM; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if (ce) begin
            if (we) begin
                mem[addr] <= dwrite;
                $display("%d@%h: *%h <= %h", $time, pc, addr, dwrite);
            end
        end
    end


endmodule
