`ifndef CPU_IF_TOP_INCLUDED
`define CPU_IF_TOP_INCLUDED
/* 
 *  File Name: IF_LEVEL.v
 *  Module: NPC, PC, IM
 *  Description: Pack (NPC, PC, IM) into a top module 
 */

`default_nettype none
`include "instructions.v"
`include "memconfig.v"
`include "exception.v"

module PC (
    input wire clk, 
    input wire reset,
    // control
    input wire En,  // Write Enable, 0 if the pipeline stalls
    // data
    input wire [31:0] NPC, // next PC
    // output
    output wire [31:0] PC,
    // exception flag
    output wire [6:2] exc
);
    reg [31:0] pc = `TEXT_STARTADDR;
    assign PC = pc;

    // Exception
    assign exc = ((!(PC >= `TEXT_STARTADDR && PC < `TEXT_ENDADDR)) || (PC[1:0] != 0)) ? (`EXC_ADEL) : 0;
    
    initial begin
        pc <= `TEXT_STARTADDR;
    end
    
    always @(posedge clk ) begin
        if (reset) begin
            pc <= `TEXT_STARTADDR;
        end
        else begin
            if (En) begin
                pc <= NPC;
            end
            else begin
                pc <= pc;
            end
        end
    end

endmodule

module NPC (
    input wire [`WIDTH_INSTR-1:0] instr,
    input wire cmp,
    input wire [31:0] PC,
    input wire [15:0] imm16,
    input wire [25:0] jmpAddr,
    input wire [31:0] jmpReg,
    /* Control by CP0 */
    input wire [`WIDTH_KCTRL-1:0] KCtrl, 
    input wire [31:2] EPC, 
    output wire [31:0] NPC,
    output wire isJmp
);
    parameter WIDTH_NPC = 2,
            NPC_Order   = 0,
            NPC_Branch  = 1,
            NPC_JmpImm  = 2,
            NPC_JmpReg  = 3;
    // control
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));
    wire [WIDTH_NPC-1:0] npcOp;
    assign npcOp = (
        (instr == `JALR || instr == `JR) ? (NPC_JmpReg) : 
        (instr == `J    || instr == `JAL) ? (NPC_JmpImm) : 
        ((func == `FUNC_BRANCH) && cmp) ? (NPC_Branch) : 
        (NPC_Order)
    );

    assign isJmp = (func == `FUNC_BRANCH || func == `FUNC_JUMP);

    wire [31:0] extImm, extJmp;
    assign extImm = {{14{imm16[15]}}, imm16, 2'b0};
    assign extJmp = {PC[31:28], jmpAddr, 2'b0};

    wire terminated;
    assign terminated = (PC == `KTEXT_STARTADDR - 4);

    assign NPC = (KCtrl == `KCTRL_KTEXT) ? (`KTEXT_STARTADDR) : 
                (KCtrl == `KCTRL_ERET) ? ({EPC[31:2], 2'b0}) : 
                (terminated) ? (PC) : 
                (npcOp == NPC_Order) ? (PC + 4) : 
                (npcOp == NPC_Branch) ? (PC + extImm) : // This PC is After b/j
                (npcOp == NPC_JmpImm) ? (extJmp) : 
                (npcOp == NPC_JmpReg) ? (jmpReg) : 
                (PC + 4);

endmodule

module IF_TOP (
    /* Global Inputs */
    // Time Sequence
    input wire                      clk, 
    input wire                      reset, 
    // Pipeline Registers
    input wire                      stall, 
    input wire                      clr, 
    input wire                      stallPC, 
    /* Data Inputs from Branch or Jump */
    input wire [`WIDTH_INSTR-1:0]   instr,
    input wire                      cmp,
    input wire [15:0]               imm16,
    input wire [25:0]               jmpAddr,
    input wire [31:0]               jmpReg,
    /* Input from CP0 */
    input wire [`WIDTH_KCTRL-1:0]   KCtrl, 
    input wire [31:2]               EPC, 
    /* Data Outputs for Next Pipeline */
    output reg [31:0]               code_ID     = 0, 
    output reg [31:0]               PC_ID       = 0,
    output reg [6:2]                Exc_ID      = 0,
    output reg                      BD_ID       = 0, 
    /* Interfaces for IM */
    output wire [31:0]              IM_PC, 
    input wire [31:0]               IM_code, 
    /* Other Outputs */
    output wire [31:0]              PC_IF, 
    output wire                     BD_IF
);
    /* ------ Part 1: Wires Declaration ------ */
    wire [31:0] NPC, PC, code;
    wire isJmp;
    wire [6:2] excPC;
    wire BD; // is Branching Delay

    /* ------ Part 2: Instantiate Modules ------ */

    NPC npc (
        .PC(PC), .instr(instr),
        .imm16(imm16), .cmp(cmp),
        .jmpAddr(jmpAddr), .jmpReg(jmpReg),
        .KCtrl(KCtrl), .EPC(EPC), 
        .NPC(NPC), .isJmp(isJmp)
    );
    
    PC pc (
        .clk(clk), .reset(reset),
        .En(~stallPC), // 
        .NPC(NPC), .PC(PC), 
        .exc(excPC)
    );

    assign IM_PC = PC;
    assign code = IM_code;

    assign PC_IF = PC;
    assign BD = isJmp;
    assign BD_IF = BD;

    /* ------ Part 3: Pipeline Registers ------ */
    always @(posedge clk) begin
        if (reset | clr) begin
            code_ID         <=  0;
            PC_ID           <=  0;
            Exc_ID          <=  0;
            BD_ID           <=  0;
        end
        else if (!stall) begin
            code_ID         <=  code;
            PC_ID           <=  PC;
            Exc_ID          <=  excPC;
            BD_ID           <=  BD;
        end
    end

endmodule
`endif
