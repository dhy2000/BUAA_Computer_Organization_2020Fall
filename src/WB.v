/* ------- Write Back Driver ------- */

`default_nettype none

`include "instructions.v"
`include "InstrCategorizer.v"

module WriteBack (
    // input
    // data source
    input wire [31:0] ALUOut, 
    input wire [31:0] MemRead, 
    input wire [31:0] PCInOrder, 
    // Control
    input wire [`InstrID_WIDTH-1:0] Instr, 
    // output
    output wire [31:0] RegWriteData
);
    /* Instantiate a Categorizer module */
    wire [`FUNCTYPE_WIDTH-1:0] functype;
    InstrCategorizer categorizer (
        .instr_id(Instr), 
        .format(), .functype(functype)
    );
    assign RegWriteData = (
        ((functype == `FUNC_MEMLOAD)) ? (MemRead) : 
        ((Instr == `JAL) || (Instr == `JALR)) ? (PCInOrder) : 
        (ALUOut) // default
    );

endmodule
