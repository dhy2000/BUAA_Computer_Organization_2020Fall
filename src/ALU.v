/* ------ ALU ------ */

`default_nettype none
`include "instructions.v"
`include "InstrCategorizer.v"

module ALU (
    /* Inputs */
    // Instruction
    input wire [`InstrID_WIDTH-1:0] Instr,
    // Data Source
    input wire [31:0] DataRs, 
    input wire [31:0] DataRt,
    input wire [15:0] Imm16,
    input wire [4:0] shamt,
    // Reg Addr
    input wire [4:0] AddrRt, 
    input wire [4:0] AddrRd, 
    // Output
    output wire [31:0] Out, 
    // For Pipeline
    output wire [4:0] RegWriteAddr,
    output wire [31:0] MemWriteData
);
// Parameters
/* ALU Operator Signal */
parameter ALU_Oper_WIDTH = 5;
parameter   ALU_Zero    = 0,
            ALU_A       = 1,
            ALU_B       = 2,
            ALU_Add     = 3,
            ALU_Sub     = 4,
            ALU_And     = 5,
            ALU_Or      = 6,
            ALU_Nor     = 7,
            ALU_Xor     = 8,
            ALU_Lui     = 9,
            ALU_Slt     = 10,
            ALU_Sltu    = 11,
            ALU_Sll     = 12,
            ALU_Srl     = 13,
            ALU_Sra     = 14
;
/* ALU Extend Immediate Signal */
parameter ALU_EXT_WIDTH = 1;
parameter   EXT_Zero    = 0,
            EXT_Sign    = 1
;
    /* ------------ Control ------------ */
    // Instantiate an InstrCategorizer
    wire [`FORMAT_WIDTH-1:0] format;
    wire [`FUNCTYPE_WIDTH-1:0] functype;
    InstrCategorizer categorizer (
        .instr_id(Instr), 
        .format(format), .functype(functype)
    );
    wire [ALU_Oper_WIDTH-1:0] ALUOp;
    wire [ALU_EXT_WIDTH-1:0] EXTOp;

    assign ALUOp = (
        ((functype == `FUNC_MEMLOAD) || (functype == `FUNC_MEMSTORE)) ? (ALU_Add) : 
        // 
        ((Instr == `ADD) || (Instr == `ADDU) || (Instr == `ADDI) || (Instr == `ADDIU)) ? (ALU_Add) : 
        ((Instr == `SUB) || (Instr == `SUBU)) ? (ALU_Sub) : 
        ((Instr == `AND) || (Instr == `ANDI)) ? (ALU_And) : 
        ((Instr == `OR)  || (Instr == `ORI )) ? (ALU_Or)  : 
        ((Instr == `XOR) || (Instr == `XORI)) ? (ALU_Xor) : 
        ((Instr == `NOR)) ? (ALU_Nor) : 
        ((Instr == `SLT) || (Instr == `SLTI)) ? (ALU_Slt) : 
        ((Instr == `SLTU) || (Instr == `SLTIU)) ? (ALU_Sltu) : 
        ((Instr == `SLL) || (Instr == `SLLV)) ? (ALU_Sll) : 
        ((Instr == `SRL) || (Instr == `SRLV)) ? (ALU_Srl) :
        ((Instr == `SRA) || (Instr == `SRAV)) ? (ALU_Sra) : 
        ((Instr == `LUI)) ? (ALU_Lui) : 
        /* Add New Instruction Here */
        (ALU_Zero)
    );
    assign EXTOp = (
        ((functype == `FUNC_LOGICAL)) ? (EXT_Zero) : 
        /* Add Instruction/functype Here */
        (EXT_Sign)
    );
    /* ----------- Execute ----------- */
    function [31:0] imm_extend;
        input [15:0] imm16;
        input [ALU_EXT_WIDTH-1:0] extop;
        begin
            imm_extend = 0;
            case (extop) 
            EXT_Zero: imm_extend = {16'b0, imm16};
            EXT_Sign: imm_extend = {{16{imm16[15]}}, imm16};
            endcase
        end
    endfunction
    wire [31:0] Imm32;
    assign Imm32 = imm_extend(Imm16, EXTOp);

    wire [31:0] SrcA, SrcB;
    assign SrcA = (functype == `FUNC_SHIFT) ? ({27'b0, shamt}) : (DataRs);
    assign SrcB = (format == `FORMAT_I) ? (Imm32) : (DataRt);
    
    assign RegWriteAddr = (Instr == `JAL) ? (5'd31) : ((format == `FORMAT_R)) ? (AddrRd) : (AddrRt);

    assign MemWriteData = (DataRt);

    function [31:0] alu;
        input [31:0] a;
        input [31:0] b;
        input [ALU_Oper_WIDTH-1:0] op;
        begin
            case (op)
            ALU_Zero    : alu = 0;
            ALU_A       : alu = a;
            ALU_B       : alu = b;
            ALU_Add     : alu = a + b;
            ALU_Sub     : alu = a - b;
            ALU_And     : alu = a & b;
            ALU_Or      : alu = a | b;
            ALU_Nor     : alu = ~(a | b);
            ALU_Xor     : alu = a ^ b;
            ALU_Lui     : alu = (b << 16);
            ALU_Slt     : alu = ($signed($signed(a) < $signed(b))) ? 1 : 0; // Attention!!!!
            ALU_Sltu    : alu = (a < b) ? 1 : 0;
            ALU_Sll     : alu = (b << (a[4:0]));
            ALU_Srl     : alu = (b >> (a[4:0]));
            ALU_Sra     : alu = ($signed($signed(b) >>> (a[4:0])));
            default     : alu = 0;
            endcase
        end
    endfunction

    assign Out = alu(SrcA, SrcB, ALUOp);
endmodule
