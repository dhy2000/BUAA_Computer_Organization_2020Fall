/* --------- Instruction Memory --------- */

`default_nettype none

`include "memconfig.v"


module IM (
    input wire [31:0] PC,
    output wire [31:0] Instr_Hex
);
    reg [31:0] mem [0: `IM_SIZE - 1];

    wire [31:0] Addr;
    assign Addr = PC - `TEXT_STARTADDR;
    wire [`IM_ADDR_WIDTH-1:0] wordaddr;
    assign wordaddr = Addr[`IM_ADDR_WIDTH-1:2];

    wire [31:0] word;
    assign word = (PC >= `TEXT_STARTADDR && PC < `TEXT_STARTADDR + (`IM_SIZE << 2) && wordaddr < `IM_SIZE) ? mem[wordaddr] : 0;

    // assign Instr_Hex = (((^word) !== 1'b1) && ((^word) !== 1'b0)) ? word : 0;
    assign Instr_Hex = word;

    initial begin
        $readmemh(`HEXCODE_FILE, mem);
    end

endmodule