/*
 *  File Name: PipelineControl.v
 *  Module: PipelineControl
 *  Description: Control the stalls and flushes of Pipeline(Forward control is inner the level top module)
 */
`default_nettype none
`include "include/instructions.v"
`include "include/exception.v"

module InstrTuseTnew (
    input wire `TYPE_INSTR instr, 
    output wire `TYPE_IFUNC ifunc, 
    output wire [`WIDTH_T-1:0] Tuse_rs, 
    output wire [`WIDTH_T-1:0] Tuse_rt,
    output wire [`WIDTH_T-1:0] Tnew_ID     // Tnew @ ID
);
    wire `TYPE_FORMAT format; // wire `TYPE_IFUNC ifunc;
    IC ic (.instr(instr), .format(format), .ifunc(ifunc));

    assign Tuse_rs = (
        (instr == `MOVN || instr == `MOVZ) ? 0 : 
        // Calc_R
        (ifunc == `I_ALU_R) ? (
            ((instr == `SLL) || (instr == `SRL) || (instr == `SRA)) ? (`TUSE_INF) : 1
        ) : 
        (ifunc == `I_ALU_I) ? (
            ((instr == `LUI)) ? (`TUSE_INF) : 1
        ) : 
        (ifunc == `I_MEM_R) ? 1 : 
        (ifunc == `I_MEM_W) ? 1 : 
        (ifunc == `I_BRANCH) ? 0 : 
        (ifunc == `I_JUMP) ? (
            ((instr == `JR) || (instr == `JALR)) ? 0 : (`TUSE_INF)
        ) : 
        (ifunc == `I_MD) ? (
            ((instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU)) ? 1 : 
            ((instr == `MTHI) || (instr == `MTLO)) ? 1 : 
            (`TUSE_INF)
        ) : 
        (ifunc == `I_CP0) ? (`TUSE_INF) : 
        (`TUSE_INF)
    );
    assign Tuse_rt = (
        (instr == `MOVN || instr == `MOVZ) ? 0 : 
        (ifunc == `I_ALU_R) ? (
            ((instr == `CLO) || (instr == `CLZ)) ? (`TUSE_INF) : 
            1
        ) : 
        (ifunc == `I_ALU_I) ? (`TUSE_INF) : 
        (ifunc == `I_MEM_R) ? (`TUSE_INF) : 
        (ifunc == `I_MEM_W) ? 2 : 
        (ifunc == `I_BRANCH) ? (
            ((instr == `BEQ) || (instr == `BNE)) ? 0 : (`TUSE_INF)
        ) : 
        (ifunc == `I_JUMP) ? (`TUSE_INF) : 
        (ifunc == `I_MD) ? (
            ((instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU)) ? 1 : 
            (`TUSE_INF)
        ) : 
        (ifunc == `I_CP0) ? (
            (instr == `MTC0) ? 2 : (`TUSE_INF)
        ) : 
        (`TUSE_INF)
    );

    assign Tnew_ID = (
        (instr == `MOVZ || instr == `MOVN) ? 1 : 
        (ifunc == `I_ALU_R) ? 2 : 
        (ifunc == `I_ALU_I) ? (
            (instr == `LUI) ? 1 : 2
        ) : 
        (ifunc == `I_MEM_R) ? (
            (instr == `LW) ? 3 : 5
        ) : 
        (ifunc == `I_MEM_W) ? 0 : 
        (ifunc == `I_BRANCH) ? 0 : 
        (ifunc == `I_JUMP) ? (
            ((instr == `JAL) || (instr == `JALR)) ? 1 : 0
        ) : 
        (ifunc == `I_MD) ? (
            ((instr == `MFLO) || (instr == `MFHI)) ? 2 : 0
        ) : 
        (ifunc == `I_CP0) ? (
            (instr == `MFC0) ? 3 : 0
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
    input wire `TYPE_INSTR instr_ID, 
    input wire `TYPE_INSTR instr_EX,
    input wire `TYPE_INSTR instr_MEM, 
    input wire `TYPE_INSTR instr_WB, 
    input wire BD_IF, 
    input wire BD_ID, 
    input wire BD_EX, 
    input wire BD_MEM, 
    // Exception Code on every stage
    input wire [6:2] Exc_ID, 
    input wire [6:2] Exc_EX,
    input wire [6:2] Exc_MEM, 
    /* Hazard Stall */
    input wire [4:0] addrRs_ID, // use
    input wire [4:0] addrRt_ID, // use
    input wire [4:0] regWriteAddr_EX,  // new
    input wire [4:0] regWriteAddr_MEM, // new
    input wire [`WIDTH_T-1:0] Tnew_EX, 
    input wire [`WIDTH_T-1:0] Tnew_MEM,
    input wire MDBusy,     // multdiv unit
    /* Control by CP0 */
    input wire [`WIDTH_EXLOP-1:0] KCtrl_CP0, 
    input wire BD_CP0, 
    // Output Tnew to pipeline
    output wire [`WIDTH_T-1:0] Tnew_ID, 
    // Macro PC
    output wire [31:0] MacroPC, 
    output wire MacroBD, // BD flag sync with MacroPC
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
    output wire dis_GRF, 
    // NPC Ctrl
    output wire [`WIDTH_EXLOP-1:0] KCtrl_NPC
);
    /* Part 1. Pipeline Stall */
    wire `TYPE_IFUNC ifunc_ID;
    wire [`WIDTH_T-1:0] Tuse_rs, Tuse_rt;
    InstrTuseTnew tusetnew (
        .instr(instr_ID),
        .ifunc(ifunc_ID),
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
    assign stall_md = (MDBusy) && (ifunc_ID == `I_MD);

    wire stall_stallPC, stall_clrEX, stall_stallID;

    assign {stall_stallPC, stall_stallID, stall_clrEX} = (stall_rs || stall_rt || stall_md) ? 3'b111 : 3'b000;

    /* Part 2. Interrupt and Exception by CP0 */
    wire cp0_clrEX;
    wire flushAll = (KCtrl_CP0 == `EPC_ENTRY || KCtrl_CP0 == `EPC_ERET);
    assign KCtrl_NPC = KCtrl_CP0;
    assign {dis_MULTDIV, dis_DM} = (flushAll)? 2'b11 : 2'b00;
    // assign dis_GRF = (flushAll && BD_CP0) ? 1'b1 : 1'b0;
    assign dis_GRF = 0;
    assign {clr_ID, cp0_clrEX, clr_MEM, clr_WB} = (flushAll) ? 4'b1111 : 4'b0000;


    /* Part 3. Macro PC */
    // instantiate an IC
    wire `TYPE_IFUNC ifunc_WB;
    IC ic (.instr(instr_WB), .format(), .ifunc(ifunc_WB));

    assign MacroPC = (PC_MEM || Exc_MEM) ? (PC_MEM) : 
                        (PC_EX || Exc_EX) ? (PC_EX) : 
                        (PC_ID || Exc_ID) ? (PC_ID) : 
                        (PC_IF) ? (PC_IF) : 0;
    assign MacroBD = (PC_MEM || Exc_MEM) ? (BD_MEM) : 
                        (PC_EX || Exc_EX) ? (BD_EX) : 
                        (PC_ID || Exc_ID) ? (BD_ID) : 
                        (PC_IF) ? (BD_IF) : 0;

    /* Merge output signals */
    assign stall_PC = (!flushAll) && (stall_stallPC);
    assign stall_ID = (!flushAll) && (stall_stallID);
    assign clr_EX = stall_clrEX | cp0_clrEX; // Two things controlls clearing ID/EX pipeline register


endmodule
