/*
 *  File Name: HazardUnit.v
 *  Module: HazardUnit
 *  Description: Control the stalls of Pipeline(Forward control is inner the level top module)
 */

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

module HazardUnit (
    input wire [`WIDTH_INSTR-1:0] instr_ID, 
    input wire [`WIDTH_INSTR-1:0] instr_EX,
    input wire [`WIDTH_INSTR-1:0] instr_MEM, 
    input wire [4:0] addrRs_ID, // use
    input wire [4:0] addrRt_ID, // use
    input wire [4:0] regWriteAddr_EX,  // new
    input wire [4:0] regWriteAddr_MEM, // new
    input wire [`WIDTH_T-1:0] Tnew_EX, 
    input wire [`WIDTH_T-1:0] Tnew_MEM,
    // input wire [`WIDTH_T-1:0] Tnew_WB, 
    input wire MDBusy,     // multdiv unit
    // Output Tnew to pipeline
    output wire [`WIDTH_T-1:0] Tnew_ID, 
    // Output Stall Signals
    output wire stall_PC, 
    output wire stall_ID, 
    output wire clr_EX
);
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

    // TODO: mult/div stalls

    assign {stall_PC, stall_ID, clr_EX} = (stall_rs || stall_rt || stall_md) ? 3'b111 : 3'b000;

endmodule
