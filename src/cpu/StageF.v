/* 
 *  Overview: Pipeline Stage F (instruction Fetch)
 */

`default_nettype none
`include "../include/instructions.vh"
`include "../include/exception.vh"
`include "../include/memory.vh"

/*
 *  Overview: Program Counter
 *  Inputs: Branch/Jump from D, exception/eret from CP0
 */
module PC (
    input wire clk, 
    input wire reset,
    // Pipeline Control
    input wire en,
    // D stage
    input wire `TYPE_INSTR instr,
    input wire `TYPE_IFUNC ifunc,
    input wire cmp,
    input wire `TYPE_IMM imm,
    input wire `TYPE_JADDR jAddr,
    input wire `WORD jReg,
    // Exception
    input wire exl,
    input wire `WORD EXNPC,
    // output
    output reg `WORD PC = `PC_BOOT,
    output wire BD,
    output wire `TYPE_EXC exc
);
    localparam
        NPC_Order   = 0,
        NPC_Branch  = 1,
        NPC_JmpImm  = 2,
        NPC_JmpReg  = 3,
        NPC_Exl     = 4,
        NPC_Keep    = 5;
    
    // BD Flag
    assign BD = (ifunc == `I_BRANCH || ifunc == `I_JUMP); // no matter whether really branch

    // Extend Immediate
    wire `WORD extImm, extJmp;
    assign extImm = {{14{imm[15]}}, imm, 2'b0};
    assign extJmp = {PC[31:28], jAddr, 2'b0};

    // Termination to avoid pc out of range without ending infinite loop
    wire terminated;    // reserved
    assign terminated = (PC == `KTEXT_START - 4);

    // NPC Control
    wire [3 : 0] npcOp;
    assign npcOp = (
        (exl)           ? (NPC_Exl) :
        (terminated)    ? (NPC_Keep) :
        (instr == `JALR || instr == `JR)    ? (NPC_JmpReg) : 
        (instr == `J    || instr == `JAL)   ? (NPC_JmpImm) : 
        ((ifunc == `I_BRANCH) && cmp)       ? (NPC_Branch) : 
        (NPC_Order)
    );
    
    // Select data source
    wire [31 : 0] NPC;
    assign NPC = (npcOp == NPC_Order)   ? (PC + 4) :
                (npcOp == NPC_Branch)   ? (PC + extImm) : // This PC is After b/j
                (npcOp == NPC_JmpImm)   ? (extJmp) :
                (npcOp == NPC_JmpReg)   ? (jReg) :
                (npcOp == NPC_Exl)      ? (EXNPC) :
                (PC);
    
    // State update
    initial begin
        PC <= `PC_BOOT;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            PC <= `PC_BOOT;
        end
        else begin
            if (en) begin
                PC <= NPC;
            end
        end
    end
    
    // Exception: Out of IM range or Not Aligned by Word
    assign exc = ((!(PC >= `IM_ADDR_START && PC <= `IM_ADDR_END)) || (PC[1:0] != 0)) ? (`EXC_ADEL) : 0;

endmodule

module StageF (
    input wire                      clk,
    input wire                      reset,
    /* Input from D (control PC jump) */
    input wire `TYPE_INSTR          instr_D,
    input wire `TYPE_IFUNC          ifunc_D,
    input wire                      cmp_D,
    input wire `TYPE_IMM            imm_D,
    input wire `TYPE_JADDR          jAddr_D,
    input wire `WORD                jReg_D,
    /* Input from CP0 */
    input wire                      exl,
    input wire `WORD                EXNPC,
    /* Interface with IM */
    output wire `WORD               IAddr,
    input wire `WORD                IRData,
    input wire                      IReady,
    /* To next stage */
    output reg `WORD                code_D      = 0,
    output reg `WORD                PC_D        = 0,
    output reg                      BD_D        = 0,
    output reg `TYPE_EXC            EXC_D       = 0,
    /* Interface with Pipeline Controller */
    input wire                      stall,
    input wire                      clear,
    input wire                      enPC,
    output wire                     busyI,
    /* Status of current stage */
    output wire `WORD               PC_F,
    output wire                     BD_F,
    output wire `TYPE_EXC           EXC_F
);

    /* ------ Instantiate Modules ------ */
    PC program_counter (
        .clk(clk), .reset(reset),
        .en(enPC),
        .instr(instr_D),
        .ifunc(ifunc_D),
        .cmp(cmp_D),
        .imm(imm_D),
        .jAddr(jAddr_D),
        .jReg(jReg_D),
        .exl(exl),
        .EXNPC(EXNPC),
        .PC(PC_F),
        .BD(BD_F),
        .exc(EXC_F)
    );

    /* ------ Combinatinal Logic ------ */
    assign IAddr = PC_F;

    assign busyI = (~IReady);

    /* ------ Pipeline Registers ------ */
    always @(posedge clk) begin
        if (reset) begin
            code_D      <=  0;
            PC_D        <=  0;
            BD_D        <=  0;
            EXC_D       <=  0;
        end
        else begin
            if (clear & (~stall)) begin
                code_D      <=  0;
                PC_D        <=  0;
                BD_D        <=  0;
                EXC_D       <=  0;
            end
            else if (~stall) begin
                code_D      <=  IRData;
                PC_D        <=  PC_F;
                BD_D        <=  BD_F;
                EXC_D       <=  EXC_F;
            end
        end
    end

endmodule
