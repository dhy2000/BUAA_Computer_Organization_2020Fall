`default_nettype none
`include "include/instructions.v"

/*
 *  Overview: Classify the instruction by format and function.
 */
module IC (
    /* Input */
    input wire [`WIDTH_INSTR-1:0] instr,
    /* Output */
    output wire `TYPE_FORMAT format,
    output wire `TYPE_IFUNC ifunc 
);
    // format
    wire r, i, j;
    assign r = (
        (instr == `NOP ) ||
        (instr == `ADD ) || (instr == `SUB ) || (instr == `ADDU) || (instr == `SUBU) || 
        (instr == `AND ) ||(instr == `OR  ) || (instr == `XOR ) || (instr == `NOR ) || 
        (instr == `SLT ) ||(instr == `SLTU) || (instr == `SLL ) || (instr == `SLLV) || 
        (instr == `SRL ) || (instr == `SRLV) ||(instr == `SRA ) || (instr == `SRAV) ||
        (instr == `CLO) || (instr == `CLZ)
    );
    assign i = (
        (instr == `ADDI ) || (instr == `ADDIU) || (instr == `ANDI ) || (instr == `ORI  ) || 
        (instr == `XORI ) || (instr == `LUI  ) || (instr == `SLTI ) || (instr == `SLTIU) || 
        (instr == `LW   ) || (instr == `LH   ) || (instr == `LHU  ) || (instr == `LB   ) || 
        (instr == `LBU  ) || (instr == `SW   ) || (instr == `SH   ) || (instr == `SB   ) || 
        (instr == `BEQ  ) || (instr == `BNE  ) || (instr == `BLEZ ) || (instr == `BGTZ ) || (instr == `BGEZ ) || (instr == `BLTZ ) ||
        (instr == `BGEZAL) || (instr == `BLTZAL)
    );
    assign j = (
        (instr == `J ) || (instr == `JAL)
    );
    assign format = (r) ? (`FORMAT_R) : 
                    (i) ? (`FORMAT_I) : 
                    (j) ? (`FORMAT_J) : 
                    (`FORMAT_R) ;
    // ifunc
    wire alu_r, alu_i, mem_r, mem_w, br, jmp, md, cp0;
    assign alu_r = (
        (instr == `NOP ) || 
        (instr == `ADD ) || (instr == `SUB ) || (instr == `ADDU) || (instr == `SUBU) || 
        (instr == `AND ) || (instr == `OR  ) || (instr == `XOR ) || (instr == `NOR ) || 
        (instr == `SLT ) || (instr == `SLTU) || (instr == `SLL ) || (instr == `SRL ) || 
        (instr == `SRA ) || (instr == `SLLV) || (instr == `SRLV) || (instr == `SRAV) ||
        (instr == `CLO) || (instr == `CLZ)
    );
    assign alu_i = (
        (instr == `ADDI ) || (instr == `ADDIU) || (instr == `ANDI ) || (instr == `ORI  ) || 
        (instr == `XORI ) || (instr == `LUI  ) || (instr == `SLTI ) || (instr == `SLTIU) 
    );
    assign mem_r = (
        (instr == `LW ) || (instr == `LH ) || (instr == `LHU) || (instr == `LB ) || (instr == `LBU)
    );
    assign mem_w = (
        (instr == `SW) || (instr == `SH) || (instr == `SB) 
    );
    assign br = (
        (instr == `BEQ ) || (instr == `BNE ) || (instr == `BGEZ) || (instr == `BGTZ) || (instr == `BLEZ) || (instr == `BLTZ) ||
        (instr == `BGEZAL) || (instr == `BLTZAL)
    );
    assign jmp = (
        (instr == `J   ) || (instr == `JAL ) || (instr == `JALR) || (instr == `JR  ) 
    );
    assign md = (
        (instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU) ||
        (instr == `MFHI) || (instr == `MFLO ) || (instr == `MTHI)|| (instr == `MTLO) ||
        (instr == `MADD) || (instr == `MADDU) || (instr == `MSUB) || (instr == `MSUBU)
    );
    assign cp0 = (
        (instr == `MFC0 || instr == `MTC0 || instr == `ERET)
    );

    assign ifunc =   (alu_r) ? (`I_ALU_R) : 
                    (alu_i) ? (`I_ALU_I) : 
                    (mem_r) ? (`I_MEM_R) : 
                    (mem_w) ? (`I_MEM_W) : 
                    (br) ? (`I_BRANCH) : 
                    (jmp) ? (`I_JUMP) : 
                    (md) ? (`I_MD) : 
                    (cp0) ? (`I_CP0) : 
                    (`I_OTHER) ;

endmodule
