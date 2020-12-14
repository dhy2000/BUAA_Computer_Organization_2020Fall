/*
 *  Module: NPC
 *  Inputs: (instr, cmp), (PC, imm16, jmpaddr, jmpreg)
 *  Outputs: NPC
 *  Description: Next PC Source Calculator and Selector
 */
`default_nettype none
`include "../instructions.v"
`include "../IC.v"
`include "../../memconfig.v"


module NPC (
    input wire [`WIDTH_INSTR-1:0] instr,
    input wire cmp,
    input wire [31:0] PC,
    input wire [15:0] imm16,
    input wire [25:0] jmpAddr,
    input wire [31:0] jmpReg,
    output wire [31:0] NPC
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

    wire [31:0] extImm, extJmp;
    assign extImm = {{14{imm16[15]}}, imm16, 2'b0};
    assign extJmp = {PC[31:28], jmpAddr, 2'b0};

    wire terminated;
    assign terminated = (PC == `KTEXT_STARTADDR - 4);

    assign NPC = (terminated) ? (PC) : 
                (npcOp == NPC_Order) ? (PC + 4) : 
                (npcOp == NPC_Branch) ? (PC + extImm) : // This PC is After b/j
                (npcOp == NPC_JmpImm) ? (extJmp) : 
                (npcOp == NPC_JmpReg) ? (jmpReg) : 
                (PC + 4);
    // assign PCToLink = PC + 8; // Delay Slot.
endmodule
