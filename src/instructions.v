/* ------ MIPS-32 Instructions (Added Into CPU) ------ */
`ifndef INSTRUCTION_SET_INCLUDED
`define INSTRUCTION_SET_INCLUDED
/* ------ Instruction Format ------ */
`define FORMAT_WIDTH     2
`define FORMAT_R         0
`define FORMAT_I         1
`define FORMAT_J         2

/* ------ Instruction Type by Function ------ */
`define FUNCTYPE_WIDTH      3
`define FUNC_ARITH      0
`define FUNC_LOGICAL    1
`define FUNC_SHIFT      2
`define FUNC_MEMLOAD    3
`define FUNC_MEMSTORE   4
`define FUNC_BRANCH     5
`define FUNC_JUMP       6

/* ------ Instruction Identity Symbol ------ */
`define InstrID_WIDTH   6

`define NOP           0
// R-Type Arithmetic or Logical
`define ADD           1   
`define ADDU          2   
`define SUB           3   
`define SUBU          4   
`define SLT           5   
`define SLTU          6   
`define AND           7   
`define OR            8   
`define XOR           9   
`define NOR           10  
`define SLLV          22  
`define SRLV          23  
`define SRAV          24  
// R-Type Shift Instruction
`define SLL           19  
`define SRL           20  
`define SRA           21  
// I-Type Arithmetic or Logical
`define ADDI          11  
`define ADDIU         12  
`define ANDI          13  
`define ORI           14  
`define XORI          15  
`define LUI           16  
`define SLTI          17  
`define SLTIU         18  
// I-Type Memory Load / Store
`define LW            25  
`define SW            26  
`define LB            27  
`define LBU           28  
`define SB            29  
`define LH            30  
`define LHU           31  
`define SH            32  
// I-Type Branch
`define BEQ           33  
`define BNE           34  
`define BGEZ          35  
`define BGTZ          36  
`define BLEZ          37  
`define BLTZ          38  
// R/J-Type Jump
`define J             39  
`define JAL           40  
`define JALR          41  
`define JR            42  

`endif
