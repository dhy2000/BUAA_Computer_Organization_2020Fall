/* 
 * File Name: CPU.v
 * Module Name: CPU
 * Description: Top Module of CPU
 */
`default_nettype none
`include "include/instructions.v"
`include "include/exception.v"

/* ---------- Main Body ---------- */
module CPU (
    input wire clk,
    input wire reset,
    /* Ports in P7 */
    output wire [31:0] PC, 
    /* Connect With Bridge */
    output wire [31:0] BrPC, 
    output wire [31:0] BrAddr, 
    output wire [31:0] BrWData, 
    output wire [3:0] BrWE, 
    input wire [31:0] BrRData, 
    input wire [7:2] HWINT 
);
    /*
        5-Level Pipeline: 
        1. IF  2. ID(D)  3. EX(E)  4. MEM(M)  5. WB(W)
    */
    /* 1. Declare Wires */
    // IF
    wire [31:0] Code_ID, PC_ID;
    wire [31:0] PC_IF; 
    wire [6:2] Exc_ID;
    wire BD_ID, BD_IF;
    // ID
    wire `TYPE_INSTR Instr_EX, Instr_NPC, Instr_ID;
    wire `TYPE_IFUNC Func_EX;
    wire Cmp_NPC; 
    wire [31:0] PC_EX, DataRs_EX, DataRt_EX, RegWriteData_EX, JmpReg_NPC;
    wire [4:0] Shamt_EX, RegWriteAddr_EX, RA1_GRF, RA2_GRF;
    wire [4:0] AddrRs_EX, AddrRt_EX, AddrRd_EX;
    wire [4:0] AddrRs_ID, AddrRt_ID;
    wire [15:0] Imm16_EX, Imm16_NPC;
    wire [25:0] JmpAddr_NPC;
    wire [`WIDTH_T-1:0] Tnew_EX;
    wire [6:2] Exc_EX;
    wire BD_EX;
    // GRF
    wire [31:0] RD1_GRF, RD2_GRF;
    // EX
    wire `TYPE_INSTR Instr_MEM;
    wire `TYPE_IFUNC Func_MEM;
    wire [31:0] PC_MEM, ExOut_MEM;
    wire [31:0] DataRt_MEM;
    wire [4:0] AddrRt_MEM, AddrRd_MEM;
    wire [4:0] RegWriteAddr_MEM; 
    wire [31:0] RegWriteData_MEM;
    wire [`WIDTH_T-1:0] Tnew_MEM;
    wire MDBusy_EX;
    wire [6:2] Exc_MEM;
    wire BD_MEM;
    // MEM
    wire `TYPE_INSTR Instr_WB;
    wire `TYPE_IFUNC Func_WB;
    wire [31:0] PC_WB, MemWord_WB;
    wire [1:0] Offset_WB;
    wire [4:0] RegWriteAddr_WB; 
    wire [31:0] RegWriteData_WB;
    wire [`WIDTH_T-1:0] Tnew_WB;
    wire [31:0] DM_PC, DM_Addr, DM_WData;
    wire [3:0] DM_WE;
    wire [`WIDTH_EXLOP-1:0] CP0_KCtrl;
    wire [31:2] CP0_EPC;
    wire CP0_BD;
    // WB
    wire WriteEn_GRF;
    wire [4:0] RegWriteAddr_GRF; 
    wire [31:0] RegWriteData_GRF;
    wire [31:0] PC_GRF;
    // Pipeline Control Unit
    wire [`WIDTH_T-1:0] Tnew_ID;
    wire [`WIDTH_EXLOP-1:0] KCtrl_NPC;
    wire stall_PC, stall_ID, clr_ID, clr_EX;
    wire clr_MEM, clr_WB;
    wire Dis_MULTDIV, Dis_DM, Dis_GRF;
    wire MacroBD;

    /* 2. Instantiate Modules */
    // Attention: GRF

    StageIF ifu (
        .clk(clk), .reset(reset), .stall(stall_ID), .clr(clr_ID), .stallPC(stall_PC),
        .instr(Instr_NPC), .cmp(Cmp_NPC),
        .imm16(Imm16_NPC), .jmpAddr(JmpAddr_NPC), .jmpReg(JmpReg_NPC),
        .KCtrl(KCtrl_NPC), .EPC(CP0_EPC), 
        .code_ID(Code_ID), .PC_ID(PC_ID), .PC_IF(PC_IF), 
        .Exc_ID(Exc_ID), .BD_ID(BD_ID), .BD_IF(BD_IF)
    );

    StageID id (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(clr_EX),
        .code_ID(Code_ID), .PC_ID(PC_ID), .Exc_ID(Exc_ID), .BD_ID(BD_ID), 
        .regaddr_EX(RegWriteAddr_EX), .regdata_EX(RegWriteData_EX), // Forward
        .regaddr_MEM(RegWriteAddr_MEM), .regdata_MEM(RegWriteData_MEM), // Forward
        .Tnew_ID(Tnew_ID), 
        .instr_EX(Instr_EX), .ifunc_EX(Func_EX), .PC_EX(PC_EX), .Exc_EX(Exc_EX), .BD_EX(BD_EX), 
        .dataRs_EX(DataRs_EX), .dataRt_EX(DataRt_EX),
        .imm16_EX(Imm16_EX), .shamt_EX(Shamt_EX),
        .addrRs_EX(AddrRs_EX), .addrRt_EX(AddrRt_EX), .addrRd_EX(AddrRd_EX), 
        .regWriteAddr_EX(RegWriteAddr_EX), .regWriteData_EX(RegWriteData_EX),
        .Tnew_EX(Tnew_EX), 
        .instr_NPC(Instr_NPC), .cmp_NPC(Cmp_NPC),
        .imm16_NPC(Imm16_NPC), .jmpAddr_NPC(JmpAddr_NPC), .jmpReg_NPC(JmpReg_NPC),
        .instr_ID(Instr_ID), .addrRs_ID(AddrRs_ID), .addrRt_ID(AddrRt_ID), 
        .RA1_GRF(RA1_GRF), .RA2_GRF(RA2_GRF),
        .RD1_GRF(RD1_GRF), .RD2_GRF(RD2_GRF)
    );

    StageEX ex (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(clr_MEM),
        .instr_EX(Instr_EX), .ifunc_EX(Func_EX), .PC_EX(PC_EX), .Exc_EX(Exc_EX), .BD_EX(BD_EX), 
        .dataRs_EX(DataRs_EX), .dataRt_EX(DataRt_EX),
        .imm16_EX(Imm16_EX), .shamt_EX(Shamt_EX),
        .addrRs_EX(AddrRs_EX), .addrRt_EX(AddrRt_EX), .addrRd_EX(AddrRd_EX),
        .regWriteAddr_EX(RegWriteAddr_EX), .regWriteData_EX(RegWriteData_EX),
        .Tnew_EX(Tnew_EX), 
        .regaddr_MEM(RegWriteAddr_MEM), .regdata_MEM(RegWriteData_MEM), // Forward
        .regaddr_WB(RegWriteAddr_WB), .regdata_WB(RegWriteData_WB), // Forward
        .dis_MULTDIV(Dis_MULTDIV), 
        .instr_MEM(Instr_MEM), .ifunc_MEM(Func_MEM), .PC_MEM(PC_MEM), .Exc_MEM(Exc_MEM), .BD_MEM(BD_MEM), 
        .exOut_MEM(ExOut_MEM), 
        .addrRt_MEM(AddrRt_MEM), .addrRd_MEM(AddrRd_MEM), .dataRt_MEM(DataRt_MEM),
        .regWriteAddr_MEM(RegWriteAddr_MEM), .regWriteData_MEM(RegWriteData_MEM),
        .Tnew_MEM(Tnew_MEM),
        .MDBusy_EX(MDBusy_EX)
    );

    StageMEM mem (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(clr_WB),
        .instr_MEM(Instr_MEM), .ifunc_MEM(Func_MEM), .PC_MEM(PC_MEM), .Exc_MEM(Exc_MEM), .BD_MEM(BD_MEM), 
        .exOut_MEM(ExOut_MEM), 
        .addrRt_MEM(AddrRt_MEM), .addrRd_MEM(AddrRd_MEM), .dataRt_MEM(DataRt_MEM),
        .regWriteAddr_MEM(RegWriteAddr_MEM), .regWriteData_MEM(RegWriteData_MEM),
        .regaddr_WB(RegWriteAddr_WB), .regdata_WB(RegWriteData_WB),
        .Tnew_MEM(Tnew_MEM), 
        .dis_DM(Dis_DM), .BD_Macro(MacroBD), 
        .instr_WB(Instr_WB), .ifunc_WB(Func_WB), .PC_WB(PC_WB),
        .memWord_WB(MemWord_WB), .offset_WB(Offset_WB),
        .regWriteAddr_WB(RegWriteAddr_WB), .regWriteData_WB(RegWriteData_WB),
        .Tnew_WB(Tnew_WB), 
        .DM_PC(DM_PC), .DM_Addr(DM_Addr), .DM_WData(DM_WData), .DM_WE(DM_WE), .DM_RData(BrRData),
        .CP0_HWINT(HWINT), .CP0_PC(PC), 
        .CP0_KCtrl(CP0_KCtrl), .CP0_EPC(CP0_EPC), .CP0_BD(CP0_BD)
    );

    StageWB wb (
        .instr_WB(Instr_WB), .ifunc_WB(Func_WB), .PC_WB(PC_WB),
        .memWord_WB(MemWord_WB), .offset_WB(Offset_WB), 
        .regWriteAddr_WB(RegWriteAddr_WB), .regWriteData_WB(RegWriteData_WB),
        .dis_GRF(Dis_GRF), 
        .regWriteAddr_GRF(RegWriteAddr_GRF), .regWriteData_GRF(RegWriteData_GRF),
        .PC_GRF(PC_GRF)
    );

    GRF grf (
        .clk(clk), .reset(reset), .PC(PC_GRF),
        .RAddr1(RA1_GRF), .RAddr2(RA2_GRF),
        .WAddr(RegWriteAddr_GRF), .WData(RegWriteData_GRF),
        .RData1(RD1_GRF), .RData2(RD2_GRF)
    );

    PipelineControl pipectrl (
        .PC_IF(PC_IF), .PC_ID(PC_ID), .PC_EX(PC_EX), .PC_MEM(PC_MEM), .PC_WB(PC_WB), 
        .instr_ID(Instr_ID), .instr_EX(Instr_EX), .instr_MEM(Instr_MEM), .instr_WB(Instr_WB), 
        .BD_IF(BD_IF), .BD_ID(BD_ID), .BD_EX(BD_EX), .BD_MEM(BD_MEM), 
        .Exc_ID(Exc_ID), .Exc_EX(Exc_EX), .Exc_MEM(Exc_MEM),
        .addrRs_ID(AddrRs_ID), .addrRt_ID(AddrRt_ID),
        .regWriteAddr_EX(RegWriteAddr_EX), .regWriteAddr_MEM(RegWriteAddr_MEM),
        .Tnew_EX(Tnew_EX), .Tnew_MEM(Tnew_MEM),
        .MDBusy(MDBusy_EX),
        .Tnew_ID(Tnew_ID),
        .KCtrl_CP0(CP0_KCtrl), .BD_CP0(CP0_BD), 
        .MacroPC(PC), .MacroBD(MacroBD), 
        .stall_PC(stall_PC),
        .stall_ID(stall_ID), .clr_ID(clr_ID), 
        .clr_EX(clr_EX), .clr_MEM(clr_MEM), .clr_WB(clr_WB),
        .dis_MULTDIV(Dis_MULTDIV), .dis_DM(Dis_DM), .dis_GRF(Dis_GRF), 
        .KCtrl_NPC(KCtrl_NPC)
    );

    assign BrPC = DM_PC;
    assign BrAddr = DM_Addr;
    assign BrWData = DM_WData;
    assign BrWE = DM_WE;
    // assign DM_RData = BrRData;

endmodule
