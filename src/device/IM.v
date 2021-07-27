`default_nettype none
`include "../include/instructions.v"
`include "../include/exception.v"
`include "../include/memory.v"

/*
 *  Overview: Instruction Memory, read-only inside
 */
module IM (
    input wire clk,
    input wire reset,
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
    reg `WORD mem [0 : `IM_WORDNUM - 1];
    wire [`IM_ADDR_WIDTH - 1 : 2] index = addr[`IM_ADDR_WIDTH - 1 : 2];

    assign dout = mem[index];
    assign ready = 1'b1;

    initial begin
        $readmemh(`CODE_FILE, mem);
        $readmemh(`HANDLER_FILE, mem, ((`KTEXT_START - `IM_ADDR_START) >> 2), ((`KTEXT_END - `IM_ADDR_START) >> 2));
    end

endmodule