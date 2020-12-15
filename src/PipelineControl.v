/*
 *  File Name: PipelineControl.v
 *  Module: PipelineControl
 *  Description: Control the stalls and flushes of Pipeline(Forward control is inner the level top module)
 */
`ifndef CPU_PIPELINECONTROL_INCLUDED
`define CPU_PIPELINECONTROL_INCLUDED

`default_nettype none
`include "instructions.v"
`include "IC.v"

module InstrTuseTnew (
    input wire [`WIDTH_INSTR-1:0] instr, 
    output wire [`WIDTH_FUNC-1:0] func, 
    output wire [`WIDTH_T-1:0] Tuse_rs, 
    output wire [`WIDTH_T-1:0] Tuse_rt,
    output wire [`WIDTH_T-1:0] Tnew_ID     // Tnew @ ID
);
    wire [`WIDTH_FORMAT-1:0] format; // wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign Tuse_rs = (
        (instr == `MOVN || instr == `MOVZ) ? 0 : 
        // Calc_R
        (func == `FUNC_CALC_R) ? (
            ((instr == `SLL) || (instr == `SRL) || (instr == `SRA)) ? (`TUSE_INF) : 1
        ) : 
        (func == `FUNC_CALC_I) ? (
            ((instr == `LUI)) ? (`TUSE_INF) : 1
        ) : 
        (func == `FUNC_MEM_READ) ? 1 : 
        (func == `FUNC_MEM_WRITE) ? 1 : 
        (func == `FUNC_BRANCH) ? 0 : 
        (func == `FUNC_JUMP) ? (
            ((instr == `JR) || (instr == `JALR)) ? 0 : (`TUSE_INF)
        ) : 
        (func == `FUNC_MULTDIV) ? (
            ((instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU)) ? 1 : 
            ((instr == `MTHI) || (instr == `MTLO)) ? 1 : 
            (`TUSE_INF)
        ) : 
        (`TUSE_INF)
    );
    assign Tuse_rt = (
        (instr == `MOVN || instr == `MOVZ) ? 0 : 
        (func == `FUNC_CALC_R) ? (
            ((instr == `CLO) || (instr == `CLZ)) ? (`TUSE_INF) : 
            1
        ) : 
        (func == `FUNC_CALC_I) ? (`TUSE_INF) : 
        (func == `FUNC_MEM_READ) ? (`TUSE_INF) : 
        (func == `FUNC_MEM_WRITE) ? 2 : 
        (func == `FUNC_BRANCH) ? (
            ((instr == `BEQ) || (instr == `BNE)) ? 0 : (`TUSE_INF)
        ) : 
        (func == `FUNC_JUMP) ? (`TUSE_INF) : 
        (func == `FUNC_MULTDIV) ? (
            ((instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU)) ? 1 : 
            (`TUSE_INF)
        ) : 
        (`TUSE_INF)
    );

    assign Tnew_ID = (
        (instr == `MOVZ || instr == `MOVN) ? 1 : 
        (func == `FUNC_CALC_R) ? 2 : 
        (func == `FUNC_CALC_I) ? (
            (instr == `LUI) ? 1 : 2
        ) : 
        (func == `FUNC_MEM_READ) ? (
            (instr == `LW) ? 3 : 5
        ) : 
        (func == `FUNC_MEM_WRITE) ? 0 : 
        (func == `FUNC_BRANCH) ? 0 : 
        (func == `FUNC_JUMP) ? (
            ((instr == `JAL) || (instr == `JALR)) ? 1 : 0
        ) : 
        (func == `FUNC_MULTDIV) ? (
            ((instr == `MFLO) || (instr == `MFHI)) ? 2 : 0
        ) : 
        0   // NOP
    );

endmodule

module PipelineControl (
    input wire [31:0] PC_IF,
    input wire [31:0] PC_ID, 
    input wire [31:0] PC_EX, 
    input wire [31:0] PC_MEM, 
    input wire [31:0] PC_WB, 
    input wire [`WIDTH_INSTR-1:0] instr_ID, 
    input wire [`WIDTH_INSTR-1:0] instr_EX,
    input wire [`WIDTH_INSTR-1:0] instr_MEM, 
    input wire [`WIDTH_INSTR-1:0] instr_WB, 
    /* Hazard Stall */
    input wire [4:0] addrRs_ID, // use
    input wire [4:0] addrRt_ID, // use
    input wire [4:0] regWriteAddr_EX,  // new
    input wire [4:0] regWriteAddr_MEM, // new
    input wire [`WIDTH_T-1:0] Tnew_EX, 
    input wire [`WIDTH_T-1:0] Tnew_MEM,
    input wire MDBusy,     // multdiv unit
    /* Control by CP0 */
    input wire [`WIDTH_KCTRL-1:0] KCtrl_CP0, 
    // Output Tnew to pipeline
    output wire [`WIDTH_T-1:0] Tnew_ID, 
    // Macro PC
    output wire [31:0] MacroPC, 
    // Output Pipeline Control Signals
    output wire stall_PC, 
    output wire stall_ID, 
    output wire clr_ID, 
    output wire clr_EX, 
    output wire clr_MEM, 
    output wire clr_WB, 
    // Disable Function Parts to prevent write
    output wire dis_MULTDIV, 
    output wire dis_DM, 
    // NPC Ctrl
    output wire [`WIDTH_KCTRL-1:0] KCtrl_NPC
);
    /* Part 1. Pipeline Stall */
    wire [`WIDTH_FUNC-1:0] func_ID;
    wire [`WIDTH_T-1:0] Tuse_rs, Tuse_rt;
    InstrTuseTnew tusetnew (
        .instr(instr_ID),
        .func(func_ID),
        .Tuse_rs(Tuse_rs),
        .Tuse_rt(Tuse_rt),
        .Tnew_ID(Tnew_ID)
    );

    wire stall_rs, stall_rt;
    assign stall_rs = (addrRs_ID != 0) && (
        (Tnew_EX > Tuse_rs && regWriteAddr_EX == addrRs_ID) || 
        (Tnew_MEM > Tuse_rs && regWriteAddr_MEM == addrRs_ID)
    );
    assign stall_rt = (addrRt_ID != 0) && (
        (Tnew_EX > Tuse_rt && regWriteAddr_EX == addrRt_ID) || 
        (Tnew_MEM > Tuse_rt && regWriteAddr_MEM == addrRt_ID)
    );

    wire stall_md;
    assign stall_md = (MDBusy) && (func_ID == `FUNC_MULTDIV);

    wire stall_stallPC, stall_clrEX, stall_stallID;

    assign {stall_stallPC, stall_stallID, stall_clrEX} = (stall_rs || stall_rt || stall_md) ? 3'b111 : 3'b000;

    /* Part 2. Interrupt and Exception by CP0 */
    wire cp0_clrEX;
    wire flushAll = (KCtrl_CP0 == `KCTRL_KTEXT || KCtrl_CP0 == `KCTRL_ERET);
    assign KCtrl_NPC = KCtrl_CP0;

    assign {clr_ID, cp0_clrEX, clr_MEM, clr_WB} = (flushAll) ? 4'b1111 : 4'b0000;


    /* Part 3. Macro PC */
    // instantiate an IC
    wire [`WIDTH_FUNC-1:0] func_WB;
    IC ic (.instr(instr_WB), .format(), .func(func_WB));

    assign MacroPC = ((func_WB == `FUNC_BRANCH) || (func_WB == `FUNC_JUMP)) ? (PC_WB) :  // Branch Delay Slot
                        (PC_MEM) ? (PC_MEM) : 
                        (PC_EX) ? (PC_EX) : 
                        (PC_ID) ? (PC_ID) : 
                        (PC_IF) ? (PC_IF) : 0;
    /* Merge output signals */
    assign stall_PC = (!flushAll) && (stall_stallPC);
    assign stall_ID = (!flushAll) && (stall_stallID);
    assign clr_EX = stall_clrEX | cp0_clrEX; // Two things controlls clearing ID/EX pipeline register


endmodule

`endif 
