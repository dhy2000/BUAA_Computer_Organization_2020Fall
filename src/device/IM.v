module IM (
    input wire [31:0] PC,
    output wire [31:0] code
);
    // Memory
    reg [31:0] mem [0: `IM_WORDNUM - 1];
    wire [31:0] baseAddr;
    assign baseAddr = PC - `IM_ADDR_START;
    wire [`IM_ADDR_WIDTH-1:2] wordIndex;
    assign wordIndex = baseAddr[`IM_ADDR_WIDTH-1:2];

    wire [31:0] memword;
    assign memword = (PC >= `IM_ADDR_START && PC < (`IM_ADDR_START + `IM_SIZE)) ? mem[wordIndex] : 0;

    assign code = (^memword === 1'bx) ? 0 : memword;

    initial begin
        $readmemh(`CODE_FILE, mem);
        $readmemh(`HANDLER_FILE, mem, 
            ((`KTEXT_START - `IM_ADDR_START) >> 2), 
            ((`KTEXT_END - `IM_ADDR_START) >> 2)
        );
    end

endmodule