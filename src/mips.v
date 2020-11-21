/* 
 * File Name: mips.v
 * Module Name: mips
 * Description: Top Module of CPU
 */
`default_nettype none
`include "instructions.v"
/* ---------- Parts ---------- */
`include "PC.v"
`include "NPC.v"
`include "IM.v"
`include "Decoder.v"
`include "GRF.v"
`include "COMP.v"
`include "ALU.v"
`include "RegWriteSel.v"
`include "DM.v"
`include "WB.v"
`include "pipeline.v"

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
    // PC
    wire [31:0] PC;
    // NPC
    wire [31:0] NPC;
    // IM
    wire [31:0] Code; 
    // --- 
    // Decoder
    wire [`WIDTH_INSTR-1:0] Instr;
    wire [4:0] AddrRs;
    wire [4:0] AddrRt;
    wire [4:0] AddrRd;
    wire [4:0] Shamt;
    wire [15:0] Imm16;
    wire [25:0] JmpAddr;
    // GRF
    wire [31:0] DataRs_GRF; // Raw
    wire [31:0] DataRt_GRF; // Raw
    wire [31:0] DataRs_ID; // forward
    wire [31:0] DataRt_ID; // forward
    // COMP
    wire Cmp;
    // ---
    // ALU
    wire [31:0] DataRs_Alu; // forward
    wire [31:0] DataRt_Alu; // forward
    wire [31:0] AluOut;
    // RegWriteSel
    wire [4:0] RegWriteAddr;
    // ---
    // DM
    wire [31:0] MemWriteData_DM; // forward
    wire [31:0] MemReadData;
    // --- 
    // WB
    wire RegWriteEn;
    wire [31:0] RegWriteData;
    // --- Pipeline Register
    // IF/ID
    wire [31:0] Code_ID;
    wire [31:0] PC_ID;
    // ID/EX
    wire [`WIDTH_INSTR-1:0] Instr_EX;
    wire [31:0] PC_EX;
    wire [31:0] DataRs_EX;
    wire [31:0] DataRt_EX;
    wire [15:0] Imm16_EX;
    wire [4:0] Shamt_EX;
    wire [4:0] AddrRs_EX;
    wire [4:0] AddrRt_EX;
    wire [4:0] AddrRd_EX;
    // EX/MEM
    wire [`WIDTH_INSTR-1:0] Instr_MEM;
    wire [31:0] PC_MEM;
    wire [31:0] AluOut_MEM;
    wire [31:0] MemWriteData_MEM;
    wire [4:0] RegWriteAddr_MEM;
    // MEM/WB
    wire [`WIDTH_INSTR-1:0] Instr_WB;
    wire [31:0] PC_WB;
    wire [31:0] AluOut_WB;
    wire [31:0] MemReadData_WB;
    wire [4:0] RegWriteAddr_WB;

    // TODO: support Data Forward!!!!!

    /* 2. Instantiate Modules */
    // IF
    PC pc (
        .clk(clk), .reset(reset), .En(1'b1),
        .NPC(NPC), .PC(PC)
    );
    NPC npc (
        .instr(Instr), .cmp(Cmp), .PC(PC), .imm16(Imm16), .jmpAddr(JmpAddr), .jmpReg(DataRs_ID),
        .NPC(NPC)
    );
    IM im (
        .PC(PC), .code(Code)
    );
    // IF/ID
    IF_ID if_id (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .code_IF(Code), .code_ID(Code_ID),
        .PC_IF(PC), .PC_ID(PC_ID)
    );
    // ID
    Decoder decd (
        .code(Code_ID),
        .instr(Instr), .rs(AddrRs), .rt(AddrRt), .rd(AddrRd),
        .shamt(Shamt), .imm(Imm16), .jmpaddr(JmpAddr)
    );
    GRF grf (
        // READ@ID
        .RAddr1(AddrRs), .RAddr2(AddrRt),
        .RData1(DataRs_GRF), .RData2(DataRt_GRF),
        // WRITE@WB
        .clk(clk), .reset(reset), .writeEn(RegWriteEn),
        .WAddr(RegWriteAddr_WB), .WData(RegWriteData), 
        .PC(PC_WB)
    );
    COMP cmp (
        .instr(Instr), 
        .dataRs(DataRs_ID), .dataRt(DataRt_ID), 
        .cmp(Cmp)
    );
    // ID/EX
    ID_EX id_ex (   
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .instr_ID(Instr), .instr_EX(Instr_EX), 
        .PC_ID(PC_ID), .PC_EX(PC_EX),
        .dataRs_ID(DataRs_ID), .dataRs_EX(DataRs_EX),
        .dataRt_ID(DataRt_ID), .dataRt_EX(DataRt_EX),
        .imm16_ID(Imm16), .imm16_EX(Imm16_EX),
        .shamt_ID(Shamt), .shamt_EX(Shamt_EX), 
        .addrRs_ID(AddrRs), .addrRs_EX(AddrRs_EX),
        .addrRt_ID(AddrRt), .addrRt_EX(AddrRt_EX),
        .addrRd_ID(AddrRd), .addrRd_EX(AddrRd_EX)
    );
    // EX
    ALU alu (
        .instr(Instr_EX), 
        .dataRs(DataRs_Alu), .dataRt(DataRt_Alu),
        .imm16(Imm16_EX), .shamt(Shamt_EX), 
        .out(AluOut)
    );
    RegWriteSel regwsel (
        .instr(Instr_EX),
        .addrRt(AddrRt_EX), .addrRd(AddrRd_EX),
        .regWriteAddr(RegWriteAddr)
    );
    // EX/MEM
    EX_MEM ex_mem (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .PC_EX(PC_EX), .PC_MEM(PC_MEM), 
        .instr_EX(Instr_EX), .instr_MEM(Instr_MEM),
        .aluOut_EX(AluOut), .aluOut_MEM(AluOut_MEM), 
        .memWriteData_EX(DataRt_Alu), .memWriteData_MEM(MemWriteData_MEM),
        .regWriteAddr_EX(RegWriteAddr), .regWriteAddr_MEM(RegWriteAddr_MEM)
    );
    // MEM
    DM dm (
        .clk(clk), .reset(reset), 
        .instr(Instr_MEM), .Addr(AluOut_MEM), .WData(MemWriteData_DM),
        .PC(PC_MEM), .RData(MemReadData)
    );
    // MEM/WB
    MEM_WB mem_wb (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .PC_MEM(PC_MEM), .PC_WB(PC_WB), 
        .instr_MEM(Instr_MEM), .instr_WB(Instr_WB),
        .aluOut_MEM(AluOut_MEM), .aluOut_WB(AluOut_WB), 
        .memReadData_MEM(MemReadData), .memReadData_WB(MemReadData_WB),
        .regWriteAddr_MEM(RegWriteAddr_MEM), .regWriteAddr_WB(RegWriteAddr_WB)
    );
    // WB
    WB wb (
        .instr(Instr_WB), .PC(PC_WB), 
        .aluOut(AluOut_WB), .memRead(MemReadData_WB), 
        .regWriteData(RegWriteData), .regWriteEn(RegWriteEn)
    );

    /* 3. Select Forward Data */
    // RS@ID, RT@ID, RS@EX, RT@EX
    // TODO: support Forward
    assign DataRs_ID = DataRs_GRF;
    assign DataRt_ID = DataRt_GRF;
    assign DataRs_Alu = DataRs_EX;
    assign DataRt_Alu = DataRt_EX;
    assign MemWriteData_MEM = MemWriteData_DM;
    
endmodule