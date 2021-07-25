/*
 *  Overview: Macro defines of supported instruction set, including the identification code and category label of instructions.
 */

`ifndef INC_INSTRUCTION
`define INC_INSTRUCTION

/* ------ Instruction Format ------ */
`define WIDTH_FORMAT    2   // width of the signal
`define TYPE_FORMAT     [`WIDTH_FORMAT - 1 : 0]

`define FORMAT_R        0
`define FORMAT_I        1
`define FORMAT_J        2
/* ------ Function Group ------ */
`define WIDTH_IFUNC     4   // width of the signal
`define TYPE_IFUNC      [`WIDTH_IFUNC - 1 : 0]

`define I_NOP           0
`define I_ALU_R         1
`define I_ALU_I         2
`define I_MEM_R         3   
`define I_MEM_W         4   
`define I_BRANCH        5   
`define I_JUMP          6   
`define I_MD            7
`define I_CP0           8
`define I_OTHER         15  // reserved

/* ------ Tuse / Tnew for stalls in pipeline ------ */
`define WIDTH_T         3
`define TYPE_T          [`WIDTH_T - 1 : 0]
`define TUSE_INF        5

/* ------ Label of Instruction Symbol ------ */
`define WIDTH_INSTR     7
`define TYPE_INSTR      [`WIDTH_INSTR - 1 : 0]
`define NOP     0
// Calculation R-format
`define ADD     1   // rd <= rs, rt
`define SUB     2
`define ADDU    3
`define SUBU    4
`define AND     5
`define OR      6
`define XOR     7
`define NOR     8
`define SLT     9
`define SLTU    10
`define SLL     11  // rd <= rt, shamt, need special judge between NOP
`define SRL     12  // rd <= rt, shamt
`define SRA     13  // rd <= rt, shamt
`define SLLV    14  // rd <= rt, rs
`define SRLV    15  // rd <= rt, rs
`define SRAV    16  // rd <= rt, rs
// Calculation I-format
`define ADDI    17  // rt <= rs, imm
`define ADDIU   18
`define ANDI    19
`define ORI     20
`define XORI    21
`define LUI     22  // rt <= imm
`define SLTI    23  // rt <= rs, imm
`define SLTIU   24  // rt <= rs, imm
// Memory Load (Load memory To grf)
`define LW      25  // rt <= mem[rs + imm]
`define LH      26
`define LHU     27
`define LB      28
`define LBU     29
// Memory Store (store grf to memory)
`define SW      30
`define SH      31
`define SB      32
// Branch
`define BEQ     33
`define BNE     34
`define BGEZ    35
`define BGTZ    36
`define BLEZ    37
`define BLTZ    38
// Jump
`define J       39
`define JAL     40
`define JALR    41
`define JR      42
// Mult/Div
`define MULT    43
`define MULTU   44
`define DIV     45
`define DIVU    46
`define MFHI    47
`define MFLO    48
`define MTHI    49
`define MTLO    50
// Duliu
`define MOVZ    51
`define MOVN    52
`define BGEZAL  53
`define BLTZAL  54
// 
`define CLO     55
`define CLZ     56
// Mult/Div +
`define MADD    57
`define MADDU   58
`define MSUB    59
`define MSUBU   60

// CP0 and Priority
`define MFC0    65
`define MTC0    66
`define ERET    67

`endif