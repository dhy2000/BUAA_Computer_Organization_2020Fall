/* Instruction Categorizer */
`ifndef INSTRUCTION_CATEGORIZER_INCLUDED
`define INSTRUCTION_CATEGORIZER_INCLUDED
/* 
 * params:
 * instr: instruction identity symbol,
 * returns:
 * format: (R, I or J)
 * func: category by function
*/

`default_nettype none
`include "instructions.v"

module InstrCategorizer (
    input wire [`InstrID_WIDTH-1:0] instr_id,
    output wire [`FORMAT_WIDTH-1:0] format,
    output wire [`FUNCTYPE_WIDTH-1:0] functype
);
    /* Format */
    wire format_r, format_i, format_j;
    assign format_j = ((instr_id == `J) || (instr_id == `JAL));
    assign format_r = ((instr_id == `ADD ) || 
                    (instr_id == `ADDU) || 
                    (instr_id == `SUB ) || 
                    (instr_id == `SUBU) || 
                    (instr_id == `SLT ) || 
                    (instr_id == `SLTU) || 
                    (instr_id == `AND ) || 
                    (instr_id == `OR  ) || 
                    (instr_id == `XOR ) || 
                    (instr_id == `NOR ) ||
                    // ------ 
                    (instr_id == `SLL ) ||
                    (instr_id == `SRL ) ||
                    (instr_id == `SRA ) ||
                    (instr_id == `SLLV) ||
                    (instr_id == `SRLV) ||
                    (instr_id == `SRAV) ||
                    // ------
                    (instr_id == `JALR) ||
                    (instr_id == `JR  ) 
    );
    assign format_i = ((instr_id == `ADDI ) ||
                    (instr_id == `ADDIU) ||
                    (instr_id == `ANDI ) ||
                    (instr_id == `ORI  ) ||
                    (instr_id == `XORI ) ||
                    (instr_id == `LUI  ) ||
                    (instr_id == `SLTI ) ||
                    (instr_id == `SLTIU) ||
                    // ------
                    (instr_id == `BEQ )  ||
                    (instr_id == `BNE )  ||
                    (instr_id == `BGEZ)  ||
                    (instr_id == `BGTZ)  ||
                    (instr_id == `BLEZ)  ||
                    (instr_id == `BLTZ)  ||
                    // ------
                    (instr_id == `LW )   ||
                    (instr_id == `SW )   ||
                    (instr_id == `LB )   ||
                    (instr_id == `LBU)   ||
                    (instr_id == `SB )   ||
                    (instr_id == `LH )   ||
                    (instr_id == `LHU)   ||
                    (instr_id == `SH )   
    );
    assign format = (format_j) ? (`FORMAT_J) : 
                    (format_i) ? (`FORMAT_I) : (`FORMAT_R) ;
    /* Function */
    wire func_arith, func_logical, func_shift ;
    wire func_memr, func_memw, func_branch, func_jump ;
    // Imm-Sign-Ext
    assign func_arith = (
        (instr_id == `ADD   ) || 
        (instr_id == `ADDU  ) || 
        (instr_id == `SUB   ) || 
        (instr_id == `SUBU  ) || 
        (instr_id == `SLT   ) || 
        (instr_id == `SLTU  ) || 
        (instr_id == `ADDI  ) || 
        (instr_id == `ADDIU ) || 
        (instr_id == `SLTI  ) || 
        (instr_id == `SLTIU ) || 
        (instr_id == `SLLV  ) || 
        (instr_id == `SRLV  ) || 
        (instr_id == `SRAV  )
    );
    // Imm-Zero-Ext
    assign func_logical = (
        (instr_id == `AND   ) || 
        (instr_id == `OR    ) || 
        (instr_id == `XOR   ) || 
        (instr_id == `NOR   ) || 
        (instr_id == `ANDI  ) || 
        (instr_id == `ORI   ) || 
        (instr_id == `XORI  ) || 
        (instr_id == `LUI   )
    );
    // Use-Shamt
    assign func_shift = (
        (instr_id == `SLL   ) || 
        (instr_id == `SRL   ) || 
        (instr_id == `SRA   )
    );
    // memory load and store
    assign func_memr = (
        (instr_id == `LW    ) || 
        (instr_id == `LB    ) || 
        (instr_id == `LBU   ) || 
        (instr_id == `LH    ) || 
        (instr_id == `LHU   )
    );
    assign func_memw = (
        (instr_id == `SW    ) || 
        (instr_id == `SB    ) || 
        (instr_id == `SH    )
    );
    assign func_branch = (
        (instr_id == `BEQ   ) || 
        (instr_id == `BNE   ) || 
        (instr_id == `BGEZ  ) || 
        (instr_id == `BGTZ  ) || 
        (instr_id == `BLEZ  ) || 
        (instr_id == `BLTZ  )
    );
    assign func_jump = (
        (instr_id == `J     ) || 
        (instr_id == `JAL   ) || 
        (instr_id == `JALR  ) || 
        (instr_id == `JR    )
    );

    assign functype = (func_arith) ? (`FUNC_ARITH) : 
                    (func_logical) ? (`FUNC_LOGICAL) : 
                    (func_shift) ? (`FUNC_SHIFT) : 
                    (func_memr) ? (`FUNC_MEMLOAD) : 
                    (func_memw) ? (`FUNC_MEMSTORE) : 
                    (func_branch) ? (`FUNC_BRANCH) : 
                    (func_jump) ? (`FUNC_JUMP) : 
                    (`FUNC_ARITH); 

endmodule


`endif
