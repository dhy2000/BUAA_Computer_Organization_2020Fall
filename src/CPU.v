/* 
 * File Name: CPU.v
 * Module Name: CPU
 * Description: Top Module of CPU
 */
`ifndef CPU_CPU_INCLUDED
`define CPU_CPU_INCLUDED

`default_nettype none
`include "instructions.v"
/* ---------- Parts ---------- */
`include "IF_TOP.v"
`include "ID_TOP.v"
`include "EX_TOP.v"
`include "MEM_TOP.v"
`include "WB_TOP.v"
`include "GRF.v"

`include "PipelineControl.v"

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
    input wire [31:0] BrRData
);
    /*
        5-Level Pipeline: 
        1. IF  2. ID(D)  3. EX(E)  4. MEM(M)  5. WB(W)
    */
    /* 1. Declare Wires */
    // IF
    wire [31:0] Code_ID, PC_ID;
    wire [31:0] PC_IF; 
    // ID
    wire [`WIDTH_INSTR-1:0] Instr_EX, Instr_NPC, Instr_ID;
    wire Cmp_NPC; 
    wire [31:0] PC_EX, DataRs_EX, DataRt_EX, RegWriteData_EX, JmpReg_NPC;
    wire [4:0] Shamt_EX, RegWriteAddr_EX, RA1_GRF, RA2_GRF;
    wire [4:0] AddrRs_EX, AddrRt_EX, AddrRd_EX;
    wire [4:0] AddrRs_ID, AddrRt_ID;
    wire [15:0] Imm16_EX, Imm16_NPC;
    wire [25:0] JmpAddr_NPC;
    wire [`WIDTH_T-1:0] Tnew_EX;
    // GRF
    wire [31:0] RD1_GRF, RD2_GRF;
    // EX
    wire [`WIDTH_INSTR-1:0] Instr_MEM;
    wire [31:0] PC_MEM, AluOut_MEM;
    wire [31:0] DataRt_MEM;
    wire [4:0] AddrRt_MEM, AddrRd_MEM;
    wire [4:0] RegWriteAddr_MEM; 
    wire [31:0] RegWriteData_MEM;
    wire [`WIDTH_T-1:0] Tnew_MEM;
    wire MDBusy_EX;
    // MEM
    wire [`WIDTH_INSTR-1:0] Instr_WB;
    wire [31:0] PC_WB, MemWord_WB;
    wire [1:0] Offset_WB;
    wire [4:0] RegWriteAddr_WB; 
    wire [31:0] RegWriteData_WB;
    wire [`WIDTH_T-1:0] Tnew_WB;
    wire [31:0] DM_PC, DM_Addr, DM_WData;
    wire [3:0] DM_WE;
    wire [`WIDTH_KCTRL-1:0] CP0_KCtrl;
    wire [31:2] CP0_EPC;
    // WB
    wire WriteEn_GRF;
    wire [4:0] RegWriteAddr_GRF; 
    wire [31:0] RegWriteData_GRF;
    wire [31:0] PC_GRF;
    // Pipeline Control Unit
    wire [`WIDTH_T-1:0] Tnew_ID;
    wire [`WIDTH_KCTRL-1:0] KCtrl_NPC;
    wire stall_PC, stall_ID, clr_ID, clr_EX;
    wire clr_MEM, clr_WB;
    wire Dis_MULTDIV, Dis_DM;

    /* 2. Instantiate Modules */
    // Attention: GRF

    IF_TOP ifu (
        .clk(clk), .reset(reset), .stall(stall_ID), .clr(1'b0), .stallPC(stall_PC),
        .instr(Instr_NPC), .cmp(Cmp_NPC),
        .imm16(Imm16_NPC), .jmpAddr(JmpAddr_NPC), .jmpReg(JmpReg_NPC),
        .KCtrl(KCtrl_NPC), .EPC(CP0_EPC), 
        .code_ID(Code_ID), .PC_ID(PC_ID), .PC_IF(PC_IF)
    );

    ID_TOP id (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(clr_EX),
        .code_ID(Code_ID), .PC_ID(PC_ID),
        .regaddr_EX(RegWriteAddr_EX), .regdata_EX(RegWriteData_EX), // Forward
        .regaddr_MEM(RegWriteAddr_MEM), .regdata_MEM(RegWriteData_MEM), // Forward
        .Tnew_ID(Tnew_ID), 
        .instr_EX(Instr_EX), .PC_EX(PC_EX),
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

    EX_TOP ex (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .instr_EX(Instr_EX), .PC_EX(PC_EX),
        .dataRs_EX(DataRs_EX), .dataRt_EX(DataRt_EX),
        .imm16_EX(Imm16_EX), .shamt_EX(Shamt_EX),
        .addrRs_EX(AddrRs_EX), .addrRt_EX(AddrRt_EX), .addrRd_EX(AddrRd_EX),
        .regWriteAddr_EX(RegWriteAddr_EX), .regWriteData_EX(RegWriteData_EX),
        .Tnew_EX(Tnew_EX), 
        .regaddr_MEM(RegWriteAddr_MEM), .regdata_MEM(RegWriteData_MEM), // Forward
        .regaddr_WB(RegWriteAddr_WB), .regdata_WB(RegWriteData_WB), // Forward
        .instr_MEM(Instr_MEM), .PC_MEM(PC_MEM),
        .aluOut_MEM(AluOut_MEM), 
        .addrRt_MEM(AddrRt_MEM), .addrRd_MEM(AddrRd_MEM), .dataRt_MEM(DataRt_MEM),
        .regWriteAddr_MEM(RegWriteAddr_MEM), .regWriteData_MEM(RegWriteData_MEM),
        .Tnew_MEM(Tnew_MEM),
        .MDBusy_EX(MDBusy_EX)
    );

    MEM_TOP mem (
        .clk(clk), .reset(reset), .stall(1'b0), .clr(1'b0),
        .instr_MEM(Instr_MEM), .PC_MEM(PC_MEM),
        .aluOut_MEM(AluOut_MEM), 
        .addrRt_MEM(AddrRt_MEM), .addrRd_MEM(AddrRd_MEM), .dataRt_MEM(DataRt_MEM),
        .regWriteAddr_MEM(RegWriteAddr_MEM), .regWriteData_MEM(RegWriteData_MEM),
        .regaddr_WB(RegWriteAddr_WB), .regdata_WB(RegWriteData_WB),
        .Tnew_MEM(Tnew_MEM), 
        .instr_WB(Instr_WB), .PC_WB(PC_WB),
        .memWord_WB(MemWord_WB), .offset_WB(Offset_WB),
        .regWriteAddr_WB(RegWriteAddr_WB), .regWriteData_WB(RegWriteData_WB),
        .Tnew_WB(Tnew_WB), 
        .DM_PC(DM_PC), .DM_Addr(DM_Addr), .DM_WData(DM_WData), .DM_WE(DM_WE), .DM_RData(BrRData),
        .CP0_KCtrl(CP0_KCtrl), .CP0_EPC(CP0_EPC)
    );

    WB_TOP wb (
        .instr_WB(Instr_WB), .PC_WB(PC_WB),
        .memWord_WB(MemWord_WB), .offset_WB(Offset_WB), 
        .regWriteAddr_WB(RegWriteAddr_WB), .regWriteData_WB(RegWriteData_WB),
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
        .addrRs_ID(AddrRs_ID), .addrRt_ID(AddrRt_ID),
        .regWriteAddr_EX(RegWriteAddr_EX), .regWriteAddr_MEM(RegWriteAddr_MEM),
        .Tnew_EX(Tnew_EX), .Tnew_MEM(Tnew_MEM),
        .MDBusy(MDBusy_EX),
        .Tnew_ID(Tnew_ID),
        .KCtrl_CP0(CP0_KCtrl),
        .MacroPC(PC), 
        .stall_PC(stall_PC),
        .stall_ID(stall_ID), .clr_ID(clr_ID), 
        .clr_EX(clr_EX), .clr_MEM(clr_MEM), .clr_WB(clr_WB),
        .dis_MULTDIV(Dis_MULTDIV), .dis_DM(Dis_DM), 
        .KCtrl_NPC(KCtrl_NPC)
    );

    assign BrPC = DM_PC;
    assign BrAddr = DM_Addr;
    assign BrWData = DM_WData;
    assign BrWE = DM_WE;
    // assign DM_RData = BrRData;

endmodule

`endif