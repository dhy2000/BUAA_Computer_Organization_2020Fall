`default_nettype none
`include "memconfig.v"

module InstrMem (
    input wire clk_m, 
    input wire [31:0] PC,
    output wire [31:0] code
);  
    
    wire [31:0] baseAddr;
    assign baseAddr = PC - `TEXT_STARTADDR;
    wire [`WIDTH_IM_ADDR-1:2] wordIndex;
    assign wordIndex = baseAddr[`WIDTH_IM_ADDR-1:2];

    IM_BlockROM im (
        .address(wordIndex), .clock(clk_m), .q(code)
    );
    // Memory
    /*reg [31:0] mem [0: `IM_SIZE_WORD - 1];
    wire [31:0] baseAddr;
    assign baseAddr = PC - `TEXT_STARTADDR;
    wire [`WIDTH_IM_ADDR-1:2] wordIndex;
    assign wordIndex = baseAddr[`WIDTH_IM_ADDR-1:2];

    wire [31:0] memword;
    assign memword = (PC >= `TEXT_STARTADDR && PC < (`TEXT_STARTADDR + `IM_SIZE)) ? mem[wordIndex] : 0;

    assign code = (^memword === 1'bx) ? 0 : memword;

    initial begin
        $readmemh(`CODE_FILE, mem);
        $readmemh(`HANDLER_FILE, mem, 
            ((`KTEXT_STARTADDR - `TEXT_STARTADDR) >> 2), 
            ((`KTEXT_ENDADDR - `TEXT_STARTADDR) >> 2)
        );
    end*/

endmodule
