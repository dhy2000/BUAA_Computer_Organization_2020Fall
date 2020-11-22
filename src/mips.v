/* 
 * File Name: mips.v
 * Module Name: mips
 * Description: Top Module of CPU
 */
`default_nettype none
`include "instructions.v"
/* ---------- Parts ---------- */
`include "IF_LEVEL.v"
`include "ID_LEVEL.v"
`include "EX_LEVEL.v"
`include "MEM_LEVEL.v"
`include "WB_LEVEL.v"
`include "GRF.v"

/* ---------- Main Body ---------- */
module mips (
    input wire clk,
    input wire reset
);
    /*
        5-Level Pipeline: 
        1. IF  2. ID(D)  3. EX(E)  4. MEM(M)  5. WB(W)
    */
    /* 1. Declare Wires */
    // IF
    wire [31:0] Code_ID, PC_ID;
    // ID
    wire [`WIDTH_INSTR-1:0] Instr_EX, Instr_NPC;
    wire Cmp_NPC; 
    wire [31:0] PC_EX, DataRs_EX, DataRt_EX, RegWriteData_EX, JmpReg_NPC;
    wire [4:0] Shamt_EX, RegWriteAddr_EX, RA1_GRF, RA2_GRF;
    wire [15:0] Imm16_EX, Imm16_NPC;
    wire [25:0] JmpAddr_NPC;
    // GRF
    wire [31:0] RD1_GRF, RD2_GRF;
    // EX
    wire [`WIDTH_INSTR-1:0] Instr_MEM;
    wire [31:0] PC_MEM, AluOut_MEM, MemWriteData_MEM;
    wire [4:0] RegWriteAddr_MEM; 
    wire [31:0] RegWriteData_MEM;
    // MEM
    wire [`WIDTH_INSTR-1:0] Instr_WB;
    wire [31:0] PC_WB, MemReadData_WB;
    wire [4:0] RegWriteAddr_WB; 
    wire [31:0] RegWriteData_WB;
    // WB
    wire WriteEn_GRF;
    wire [4:0] RegWriteAddr_GRF; 
    wire [31:0] RegWriteData_GRF;
    wire [31:0] PC_GRF;

    /* 2. Instantiate Modules */
    // Attention: GRF

    IF_LEVEL ifu (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .instr(Instr_NPC), .cmp(Cmp_NPC),
        .imm16(Imm16_NPC), .jmpAddr(JmpAddr_NPC), .jmpReg(JmpReg_NPC),
        .code_ID(Code_ID), .PC_ID(PC_ID)
    );

    ID_LEVEL id (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .code_ID(Code_ID), .PC_ID(PC_ID),
        .regaddr_EX(RegWriteAddr_EX), .regdata_EX(RegWriteData_EX), // Forward
        .regaddr_MEM(RegWriteAddr_MEM), .regdata_MEM(RegWriteData_MEM), // Forward
        .instr_EX(Instr_EX), .PC_EX(PC_EX),
        .dataRs_EX(DataRs_EX), .dataRt_EX(DataRt_EX),
        .imm16_EX(Imm16_EX), .shamt_EX(Shamt_EX),
        .regWriteAddr_EX(RegWriteAddr_EX), .regWriteData_EX(RegWriteData_EX),
        .instr_NPC(Instr_NPC), .cmp_NPC(Cmp_NPC),
        .imm16_NPC(Imm16_NPC), .jmpAddr_NPC(JmpAddr_NPC), .jmpReg_NPC(JmpReg_NPC),
        .RA1_GRF(RA1_GRF), .RA2_GRF(RA2_GRF),
        .RD1_GRF(RD1_GRF), .RD2_GRF(RD2_GRF)
    );

    EX_LEVEL ex (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .instr_EX(Instr_EX), .PC_EX(PC_EX),
        .dataRs_EX(DataRs_EX), .dataRt_EX(DataRt_EX),
        .imm16_EX(Imm16_EX), .shamt_EX(Shamt_EX),
        .regWriteAddr_EX(RegWriteAddr_EX), .regWriteData_EX(RegWriteData_EX),
        .regaddr_MEM(RegWriteAddr_MEM), .regdata_MEM(RegWriteData_MEM), // Forward
        .regaddr_WB(RegWriteAddr_WB), .regdata_WB(RegWriteData_WB), // Forward
        .instr_MEM(Instr_MEM), .PC_MEM(PC_MEM),
        .aluOut_MEM(AluOut_MEM), .memWriteData_MEM(MemWriteData_MEM),
        .regWriteAddr_MEM(RegWriteAddr_MEM), .regWriteData_MEM(RegWriteData_MEM)
    );

    MEM_LEVEL mem (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .instr_MEM(Instr_MEM), .PC_MEM(PC_MEM),
        .aluOut_MEM(AluOut_MEM), .memWriteData_MEM(MemWriteData_MEM),
        .regWriteAddr_MEM(RegWriteAddr_MEM), .regWriteData_MEM(RegWriteData_MEM),
        .regaddr_WB(RegWriteAddr_WB), .regdata_WB(RegWriteData_WB),
        .instr_WB(Instr_WB), .PC_WB(PC_WB),
        .memReadData_WB(MemReadData_WB),
        .regWriteAddr_WB(RegWriteAddr_WB), .regWriteData_WB(RegWriteData_WB)
    );

    WB_LEVEL wb (
        .instr_WB(Instr_WB), .PC_WB(PC_WB),
        .memReadData_WB(MemReadData_WB),
        .regWriteAddr_WB(RegWriteAddr_WB), .regWriteData_WB(RegWriteData_WB),
        .writeEn_GRF(WriteEn_GRF),
        .regWriteAddr_GRF(RegWriteAddr_GRF), .regWriteData_GRF(RegWriteData_GRF),
        .PC_GRF(PC_GRF)
    );

    GRF grf (
        .clk(clk), .reset(reset), .PC(PC_GRF),
        .RAddr1(RA1_GRF), .RAddr2(RA2_GRF),
        .writeEn(WriteEn_GRF), .WAddr(RegWriteAddr_GRF), .WData(RegWriteData_GRF),
        .RData1(RD1_GRF), .RData2(RD2_GRF)
    );

    
endmodule