/*
 *  File Name: IC.v
 *  Module: IC
 *  Inputs: Symbol of an instruction
 *  Outputs: Format and Function class of the instruction
 *  Description: Classify the instruction by format and function.
 */

`ifndef INSTR_CLASSIFIER_INCLUDED
`define INSTR_CLASSIFIER_INCLUDED

`default_nettype none
`include "instructions.v"

module IC (
    /* Input */
    input wire [`WIDTH_INSTR-1:0] instr,
    /* Output */
    output wire [`WIDTH_FORMAT-1:0] format,
    output wire [`WIDTH_FUNC-1:0] func 
);
    // format
    assign format = 0;
    // func
    wire calc_r, calc_i, mem_r, mem_w, br, jmp, md, cp0;
    assign calc_r = (
        (instr == `NOP ) || 
        (instr == `ADD ) || (instr == `SUB ) || (instr == `ADDU) || (instr == `SUBU) || (instr == `AND ) || (instr == `OR  ) || (instr == `XOR ) || (instr == `NOR ) || (instr == `SLT ) || (instr == `SLTU) || (instr == `SLL ) || (instr == `SRL ) || (instr == `SRA ) || (instr == `SLLV) || (instr == `SRLV) || (instr == `SRAV)
        // (instr == `CLO) || (instr == `CLZ)
    );
    assign calc_i = (
        (instr == `ADDI ) || (instr == `ADDIU) || (instr == `ANDI ) || (instr == `ORI  ) || (instr == `XORI ) || (instr == `LUI  ) || (instr == `SLTI ) || (instr == `SLTIU) 
    );
    assign mem_r = (
        (instr == `LW ) || (instr == `LH ) || (instr == `LHU) || (instr == `LB ) || (instr == `LBU)
    );
    assign mem_w = (
        (instr == `SW) || (instr == `SH) || (instr == `SB) 
    );
    assign br = (
        (instr == `BEQ ) || (instr == `BNE ) || (instr == `BGEZ) || (instr == `BGTZ) || (instr == `BLEZ) || (instr == `BLTZ)
        // (instr == `BGEZAL) || (instr == `BLTZAL)
    );
    assign jmp = (
        (instr == `J   ) || (instr == `JAL ) || (instr == `JALR) || (instr == `JR  ) 
    );
    // assign md = (
    //     (instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU) ||
    //     (instr == `MFHI) || (instr == `MFLO ) || (instr == `MTHI)|| (instr == `MTLO) ||
    //     (instr == `MADD) || (instr == `MADDU) || (instr == `MSUB) || (instr == `MSUBU)
    // );
    assign cp0 = (
        (instr == `MFC0 || instr == `MTC0 || instr == `ERET)
    );

    assign func =   (calc_r) ? (`FUNC_CALC_R) : 
                    (calc_i) ? (`FUNC_CALC_I) : 
                    (mem_r) ? (`FUNC_MEM_READ) : 
                    (mem_w) ? (`FUNC_MEM_WRITE) : 
                    (br) ? (`FUNC_BRANCH) : 
                    (jmp) ? (`FUNC_JUMP) : 
                    // (md) ? (`FUNC_MULTDIV) : 
                    (cp0) ? (`FUNC_CP0) : 
                    (`FUNC_OTHER) ;
    // 

endmodule

`endif