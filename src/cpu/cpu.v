/*
 *  Overview: Top module of CPU core.
 */

`default_nettype none
`include "../include/instructions.vh"
`include "../include/exception.vh"
`include "../include/memory.vh"

/*
 *  Overview: CPU top module, connect with bridge.
 */

module CPU (
    input wire clk,
    input wire reset,
    /* I Port */
    output wire `WORD IAddr,
    input wire `WORD IData,
    input wire IReady,
    /* D Port */
    output wire `WORD DPC,
    output wire `WORD DAddr,
    output wire DREn,
    output wire DWEn,
    output wire [3:0] DByteEn,
    output wire `WORD DWData,
    input wire `WORD DRData,
    input wire DReady,
    /* Hardware Interrupt */
    input wire `TYPE_INT HWINT,
    /* Macro Status (for P7) */
    output wire `WORD PC
);
    /* ------ Wires Declaration ------ */
    // F
    wire `WORD PC_F;
    wire BD_F;
    wire `TYPE_EXC EXC_F;

    // D
    wire `TYPE_INSTR Instr_D;
    wire `TYPE_IFUNC Ifunc_D;
    wire `WORD PC_D;
    wire BD_D;
    wire `TYPE_EXC EXC_D;
    wire `TYPE_T Tnew_D;

    wire UseRs_D, UseRt_D;
    wire `TYPE_REG AddrRs_D, AddrRt_D, AddrRd_D;
    wire `WORD DataRs_D, DataRt_D;

    wire RegWEn_D;
    wire `TYPE_REG RegWAddr_D;
    wire `WORD RegWData_D;
    wire RegWValid_D;

    wire `WORD Code_D;
    wire Cmp_D;
    wire `TYPE_IMM Imm_D;
    wire `TYPE_JADDR JAddr_D;
    wire `TYPE_SHAMT Shamt_D;
    wire `WORD JReg_D;

    wire `TYPE_T TuseRs_D, TuseRt_D;

    // E
    wire `TYPE_INSTR Instr_E;
    wire `TYPE_IFUNC Ifunc_E;
    wire `WORD PC_E;
    wire BD_E;
    wire `TYPE_EXC EXC_E;
    wire `TYPE_T Tnew_E;

    wire UseRs_E, UseRt_E;
    wire `TYPE_REG AddrRs_E, AddrRt_E, AddrRd_E;
    wire `WORD DataRs_E, DataRt_E;

    wire RegWEn_E;
    wire `TYPE_REG RegWAddr_E;
    wire `WORD RegWData_E;
    wire RegWValid_E;

    wire `WORD ExtImm_E, ExtShamt_E;

    // M
    wire `TYPE_INSTR Instr_M;
    wire `TYPE_IFUNC Ifunc_M;
    wire `WORD PC_M;
    wire BD_M;
    wire `TYPE_EXC EXC_M;
    wire `TYPE_T Tnew_M;

    wire UseRt_M;
    wire `TYPE_REG AddrRt_M, AddrRd_M;
    wire `WORD DataRt_M;

    wire RegWEn_M;
    wire `TYPE_REG RegWAddr_M;
    wire `WORD RegWData_M;
    wire RegWValid_M;

    wire `WORD AluOut_M;

    // W
    wire `TYPE_INSTR Instr_W;
    wire `TYPE_IFUNC Ifunc_W;
    wire `WORD PC_W;
    wire `TYPE_T Tnew_W;

    wire RegWEn_W;
    wire `TYPE_REG RegWAddr_W;
    wire `WORD RegWData_W;
    wire RegWValid_W;

    wire [1:0] Offset_W;
    wire `WORD MemWord_W;

    wire RegWEn;
    wire `TYPE_REG RegWAddr;
    wire `WORD RegWData;
    wire `WORD RegWPC;

    // CP0
    wire `TYPE_EXC CP0EXC;
    wire Exl;
    wire `TYPE_REG CP0reg;
    wire `WORD CP0WData, CP0RData;
    wire `WORD EXNPC;

    // Pipeline Control
    wire Stall_D, Stall_E, Stall_M, Stall_W;
    wire Clear_D, Clear_E, Clear_M, Clear_W;
    wire EnPC, EnMD, EnD, EnGRF;
    wire BusyI, BusyMD, BusyD;

    // Macro status
    wire `WORD MPC;
    wire MBD;

    /* ------ Instantiate Modules ------ */
    StageF f (
        .clk(clk), .reset(reset),
        .instr_D(Instr_D), .ifunc_D(Ifunc_D), .cmp_D(Cmp_D), .imm_D(Imm_D), .jAddr_D(JAddr_D), .jReg_D(JReg_D),
        .exl(Exl), .EXNPC(EXNPC),
        .IAddr(IAddr), .IRData(IData), .IReady(IReady),
        .code_D(Code_D), .PC_D(PC_D), .BD_D(BD_D), .EXC_D(EXC_D),
        .stall(Stall_D), .clear(Clear_D), .enPC(EnPC), .busyI(BusyI),
        .PC_F(PC_F), .BD_F(BD_F), .EXC_F(EXC_F)
    );

    StageD d (
        .clk(clk), .reset(reset),
        .code_D(Code_D), .PC_D(PC_D), .BD_D(BD_D), .EXC_D(EXC_D),
        .instr_E(Instr_E), .ifunc_E(Ifunc_E), .PC_E(PC_E), .BD_E(BD_E), .EXC_E(EXC_E),
        .addrRs_E(AddrRs_E), .useRs_E(UseRs_E), .dataRs_E(DataRs_E),
        .addrRt_E(AddrRt_E), .useRt_E(UseRt_E), .dataRt_E(DataRt_E), 
        .addrRd_E(AddrRd_E),
        .extImm_E(ExtImm_E), .extShamt_E(ExtShamt_E),
        .regWEn_E(RegWEn_E), .regWAddr_E(RegWAddr_E), .regWData_E(RegWData_E), .regWValid_E(RegWValid_E), .Tnew_E(Tnew_E),
        .regWEn_M(RegWEn_M), .regWAddr_M(RegWAddr_M), .regWData_M(RegWData_M), .regWValid_M(RegWValid_M),
        .instr_D(Instr_D), .ifunc_D(Ifunc_D),
        .useRs_D(UseRs_D), .addrRs_D(AddrRs_D), .dataRs_D(DataRs_D),
        .useRt_D(UseRt_D), .addrRt_D(AddrRt_D), .dataRt_D(DataRt_D),
        .addrRd_D(AddrRd_D),
        .cmp_D(Cmp_D), .imm_D(Imm_D), .shamt_D(Shamt_D), .jAddr_D(JAddr_D), .jReg_D(JReg_D),
        .TuseRs_D(TuseRs_D), .TuseRt_D(TuseRt_D), .Tnew_D(Tnew_D),
        .regWEn_D(RegWEn_D), .regWAddr_D(RegWAddr_D), .regWData_D(RegWData_D), .regWValid_D(RegWValid_D),
        .stall(Stall_E), .clear(Clear_E)
    );

    StageE e (
        .clk(clk), .reset(reset),
        .instr_E(Instr_E), .ifunc_E(Ifunc_E), .PC_E(PC_E), .BD_E(BD_E), .EXC_E(EXC_E),
        .addrRs_E(AddrRs_E), .useRs_E(UseRs_E), .dataRs_E(DataRs_E),
        .addrRt_E(AddrRt_E), .useRt_E(UseRt_E), .dataRt_E(DataRt_E),
        .addrRd_E(AddrRd_E),
        .extImm_E(ExtImm_E), .extShamt_E(ExtShamt_E),
        .regWEn_E(RegWEn_E), .regWAddr_E(RegWAddr_E), .regWData_E(RegWData_E), .regWValid_E(RegWValid_E), .Tnew_E(Tnew_E),
        .instr_M(Instr_M), .ifunc_M(Ifunc_M), .PC_M(PC_M), .BD_M(BD_M), .EXC_M(EXC_M),
        .useRt_M(UseRt_M), .addrRt_M(AddrRt_M), .dataRt_M(DataRt_M),
        .addrRd_M(AddrRd_M),
        .aluOut_M(AluOut_M),
        .regWEn_M(RegWEn_M), .regWAddr_M(RegWAddr_M), .regWData_M(RegWData_M), .regWValid_M(RegWValid_M), .Tnew_M(Tnew_M),
        .regWEn_W(RegWEn_W), .regWAddr_W(RegWAddr_W), .regWData_W(RegWData_W), .regWValid_W(RegWValid_W),
        .stall(Stall_M), .clear(Clear_M), .enMD(EnMD), .busyMD(BusyMD)
    );

    StageM m (
        .clk(clk), .reset(reset),
        .instr_M(Instr_M), .ifunc_M(Ifunc_M), .PC_M(PC_M), .BD_M(BD_M), .EXC_M(EXC_M),
        .useRt_M(UseRt_M), .addrRt_M(AddrRt_M), .dataRt_M(DataRt_M),
        .addrRd_M(AddrRd_M),
        .aluOut_M(AluOut_M),
        .regWEn_M(RegWEn_M), .regWAddr_M(RegWAddr_M), .regWData_M(RegWData_M), .regWValid_M(RegWValid_M), .Tnew_M(Tnew_M),
        .instr_W(Instr_W), .ifunc_W(Ifunc_W), .PC_W(PC_W),
        .regWEn_W(RegWEn_W), .regWAddr_W(RegWAddr_W), .regWData_W(RegWData_W), .regWValid_W(RegWValid_W), .Tnew_W(Tnew_W),
        .offset_W(Offset_W), .memWord_W(MemWord_W),
        .DPC(DPC), .DAddr(DAddr), .DREn(DREn), .DWEn(DWEn), .DByteEn(DByteEn), .DWData(DWData), .DRData(DRData), .DReady(DReady),
        .CP0reg(CP0reg), .CP0WData(CP0WData), .CP0RData(CP0RData), .CP0EXC(CP0EXC),
        .stall(Stall_W), .clear(Clear_W), .enD(EnD), .busyD(BusyD)
    );

    StageW w (
        .instr_W(Instr_W), .ifunc_W(Ifunc_W), .PC_W(PC_W),
        .regWEn_W(RegWEn_W), .regWAddr_W(RegWAddr_W), .regWData_W(RegWData_W), .regWValid_W(RegWValid_W), .Tnew_W(Tnew_W),
        .offset_W(Offset_W), .memWord_W(MemWord_W),
        .regWEn(RegWEn), .regWAddr(RegWAddr), .regWData(RegWData), .regWPC(RegWPC)
    );

    GRF grf (
        .clk(clk), .reset(reset), .en(EnGRF),
        .RAddr1(AddrRs_D), .RData1(DataRs_D),
        .RAddr2(AddrRt_D), .RData2(DataRt_D),
        .WPC(RegWPC), .WEn(RegWEn), .WAddr(RegWAddr), .WData(RegWData)
    );

    CP0 cp0 (
        .clk(clk), .reset(reset),
        .MPC(MPC), .MBD(MBD),
        .instr(Instr_M),
        .regid(CP0reg), .WData(CP0WData), .RData(CP0RData),
        .HWINT(HWINT), .EXC(CP0EXC),
        .exl(Exl), .EXNPC(EXNPC)
    );

    PipelineControl ctrl (
        .instr_D(Instr_D), .ifunc_D(Ifunc_D),
        .useRs_D(UseRs_D), .addrRs_D(AddrRs_D),
        .useRt_D(UseRt_D), .addrRt_D(AddrRt_D),
        .useRs_E(UseRs_E), .addrRs_E(AddrRs_E),
        .useRt_E(UseRt_E), .addrRt_E(AddrRt_E),
        .useRt_M(UseRt_M), .addrRt_M(AddrRt_M),
        .regWEn_D(RegWEn_D), .regWAddr_D(RegWAddr_D), .regWValid_D(RegWValid_D),
        .regWEn_E(RegWEn_E), .regWAddr_E(RegWAddr_E), .regWValid_E(RegWValid_E),
        .regWEn_M(RegWEn_M), .regWAddr_M(RegWAddr_M), .regWValid_M(RegWValid_M),
        .regWEn_W(RegWEn_W), .regWAddr_W(RegWAddr_W), .regWValid_W(RegWValid_W),
        .TuseRs_D(TuseRs_D), .TuseRt_D(TuseRt_D),
        .Tnew_D(Tnew_D), .Tnew_E(Tnew_E), .Tnew_M(Tnew_M), .Tnew_W(Tnew_W),
        .busyI(BusyI), .busyD(BusyD), .busyMD(BusyMD),
        .exl(Exl),
        .enPC(EnPC), .enMD(EnMD), .enD(EnD), .enGRF(EnGRF),
        .stall_D(Stall_D), .clear_D(Clear_D),
        .stall_E(Stall_E), .clear_E(Clear_E),
        .stall_M(Stall_M), .clear_M(Clear_M),
        .stall_W(Stall_W), .clear_W(Clear_W)
    );

    /* ------ Combinatinal Logic ------ */
    // macro status
    assign {MPC, MBD} = (PC_M || EXC_M) ? ({PC_M, BD_M}) :
                        (PC_E || EXC_E) ? ({PC_E, BD_E}) :
                        (PC_D || EXC_D) ? ({PC_D, BD_D}) :
                        ({PC_F, BD_F});

    assign PC = MPC;


endmodule
