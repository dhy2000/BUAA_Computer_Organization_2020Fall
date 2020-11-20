/*
 * File Name: ALU.v
 * Module:  ALU
 * Inputs: (Control: instr), (Data source: dataRs, dataRt, shamt, imm16), 
 * Outputs: out
 */
`default_nettype none
`include "instructions.v"
`include "IC.v"

module ALU (
    /* Input */
    // Control
    input wire [`WIDTH_INSTR-1:0] instr,
    // Data
    input wire [31:0] dataRs, 
    input wire [31:0] dataRt, 
    input wire [15:0] imm16, 
    input wire [4:0] shamt,
    /* Output */
    output wire [31:0] out
);
    /* Inner control signal */
    parameter WIDTH_Ext = 1,
        Zero_Ext = 0,
        Sign_Ext = 1;
    parameter WIDTH_Alu = 5,
        Alu_Zero    = 0,
        Alu_A       = 1,
        Alu_B       = 2,
        Alu_Add     = 3,
        Alu_Sub     = 4,
        Alu_And     = 5,
        Alu_Or      = 6,
        Alu_Xor     = 7,
        Alu_Nor     = 8,
        Alu_Slt     = 9,
        Alu_Sltu    = 10,
        Alu_Sll     = 11,
        Alu_Srl     = 12,
        Alu_Sra     = 13,
        Alu_Lui     = 14;
    /* Control */
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    wire [WIDTH_Ext-1:0] extOp;
    wire [WIDTH_Alu-1:0] aluOp;
    
    assign extOp = (
        (func == `FUNC_MEM_READ || func == `FUNC_MEM_WRITE) ? (Sign_Ext) :
        ((instr == `ANDI) || (instr == `ORI) || (instr == `XORI) || (instr == `LUI)) ? (Zero_Ext) : 
        (Sign_Ext) // default
    );

    assign aluOp = (
        (func == `FUNC_MEM_READ || func == `FUNC_MEM_WRITE) ? (Alu_Add) : 
        (instr == `ADD || instr == `ADDU || instr == `ADDIU || instr == `ADDI) ? (Alu_Add) : 
        (instr == `SUB || instr == `SUBU) ? (Alu_Sub) : 
        (instr == `AND || instr == `ANDI) ? (Alu_And) : 
        (instr == `OR || instr == `ORI) ? (Alu_Or) : 
        (instr == `XOR || instr == `XORI) ? (Alu_Xor) : 
        (instr == `NOR) ? (Alu_Nor) : 
        (instr == `SLT || instr == `SLTI) ? (Alu_Slt) : 
        (instr == `SLTU || instr == `SLTIU) ? (Alu_Sltu) : 
        (instr == `SLL || instr == `SLLV) ? (Alu_Sll) : 
        (instr == `SRL || instr == `SRLV) ? (Alu_Srl) : 
        (instr == `SRA || instr == `SRAV) ? (Alu_Sra) : 
        (instr == `LUI) ? (Alu_Lui) : 
        (Alu_Zero) // default 
    );

    /* Execute */
    wire [31:0] extImm;
    assign extImm = (extOp == Sign_Ext) ? ({{16{imm16[15]}}, imm16}) : ({16'b0, imm16});

    wire [31:0] srca, srcb;
    assign srca = ((instr == `SLL || instr == `SRL || instr == `SRA)) ? {27'b0, shamt} : dataRs;
    assign srcb = (format == `FORMAT_I) ? extImm : dataRt;

    function [31:0] alu;
        input [31:0] a;
        input [31:0] b;
        input [WIDTH_Alu-1:0] op;
        begin
            case (op)
            Alu_Zero:   alu = 0;
            Alu_A:      alu = a;
            Alu_B:      alu = b;
            Alu_Add:    alu = a + b;
            Alu_Sub:    alu = a - b;
            Alu_And:    alu = a & b;
            Alu_Or:     alu = a | b;
            Alu_Xor:    alu = a ^ b;
            Alu_Nor:    alu = ~(a | b);
            Alu_Slt:    alu = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            Alu_Sltu:   alu = (a < b) ? 32'b1 : 32'b0;
            Alu_Sll:    alu = (b << a[4:0]);
            Alu_Srl:    alu = (b >> a[4:0]);
            Alu_Sra:    alu = ($signed($signed(b) >>> a[4:0]));
            Alu_Lui:    alu = {b, 16'b0};
            default:    alu = 0;
            endcase
        end
    endfunction

    assign out = alu(srca, srcb, aluOp);

endmodule