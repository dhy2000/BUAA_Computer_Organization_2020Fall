`default_nettype none
`include "../include/instructions.vh"
`include "../include/exception.vh"
`include "../include/memory.vh"

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

    // bram sync-read model
    reg `WORD addr_q;
    reg [3:0] count;    // block 1-period per 16 visits.

    reg `WORD mem [0 : `DM_WORDNUM - 1];
    wire `WORD bitmask = {{8{be[3]}}, {8{be[2]}}, {8{be[1]}}, {8{be[0]}}};
    wire [`DM_ADDR_WIDTH - 1 : 2] index = addr[`DM_ADDR_WIDTH - 1 : 2];

    wire `WORD dwrite = (mem[index] & (~bitmask)) | (din & bitmask);

    assign dout = mem[index];
    assign ready = (ce & (re | we)) & (count ? 1'b1 : (addr == addr_q));

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
            addr_q <= 0;
            count <= 0;
        end
        else if (ce) begin
            addr_q <= addr;
            if ((re | we) & ready) begin
                count <= count + 1;
            end
            if (we & ready) begin
                mem[index] <= dwrite;
                $display("%d@%h: *%h <= %h", $time, pc, addr, dwrite);
            end
        end
    end


endmodule
