`default_nettype none
`include "../instructions.v"
`include "../IC.v"

module COMP (
    /* Input */
    input wire [`WIDTH_INSTR-1:0] instr,
    input wire [31:0] dataRs,
    input wire [31:0] dataRt,
    output wire cmp
);

    function compare;
        input [31:0] rs;
        input [31:0] rt;
        input [`WIDTH_INSTR-1:0] instr;
        begin
            case (instr) 
            `BEQ:   compare = (rs == rt);
            `BNE:   compare = (rs != rt);
            `BGEZ:  compare = (rs[31] == 0);
            `BGTZ:  compare = (rs[31] == 0) && (rs != 0);
            `BLEZ:  compare = (rs[31] == 1) || (rs == 0);
            `BLTZ:  compare = (rs[31] == 1);
            `BGEZAL: compare = (rs[31] == 0);
            `BLTZAL: compare = (rs[31] == 1);
            `MOVZ:  compare = (rt == 0);
            `MOVN:  compare = (rt != 0);
            default: compare = 0;
            endcase
        end
    endfunction

    assign cmp = compare(dataRs, dataRt, instr);
    
endmodule