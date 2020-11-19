/* ------- Branch Comparator ------- */

`default_nettype none

`include "instructions.v"
`include "InstrCategorizer.v"

module COMP (
    // Input
    // data
    input wire [31:0] DataRs, 
    input wire [31:0] DataRt, 
    // control
    input wire [`InstrID_WIDTH-1:0] Instr, 
    // output
    output wire result
);
    
    // Instantiate Categorizer
    wire [`FUNCTYPE_WIDTH-1:0] functype;
    InstrCategorizer categorizer (
        .instr_id(Instr), 
        .format(), .functype(functype)
    );

    function compare;
        input [31:0] a;
        input [31:0] b;
        input [`InstrID_WIDTH-1:0] Instr;
        begin
            case (Instr) 
            `BEQ    : compare = (a == b);
            `BNE    : compare = (a != b);
            `BGEZ   : compare = (a[31] == 0);
            `BGTZ   : compare = ((a[31] == 0) && (a != 0));
            `BLEZ   : compare = ((a == 0) || (a[31] == 1));
            `BLTZ   : compare = ((a[31] == 1));
            default : compare = 0;
            endcase
        end
    endfunction

    assign result = compare(DataRs, DataRt, Instr);

endmodule
