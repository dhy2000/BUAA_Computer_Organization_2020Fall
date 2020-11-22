/* 
 *  File Name: IF_LEVEL.v
 *  Module: NPC, PC, IM
 *  Description: Pack (NPC, PC, IM) into a top module 
 */

`default_nettype none
`include "instructions.v"
`include "memconfig.v"
`include "IC.v"

/*
 *  Module: PC
 *  Inputs: clk, reset, En, NPC
 *  Outputs: PC
 *  Description: Program Counter
 */
module PC (
    input wire clk, 
    input wire reset,
    // control
    input wire En,  // Write Enable, 0 if the pipeline stalls
    // data
    input wire [31:0] NPC, // next PC
    // output
    output wire [31:0] PC
);
    reg [31:0] pc = `TEXT_STARTADDR;
    assign PC = pc;
    
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

/*
 *  Module: NPC
 *  Inputs: (instr, cmp), (PC, imm16, jmpaddr, jmpreg)
 *  Outputs: NPC
 *  Description: Next PC Source Calculator and Selector
 */
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

    assign NPC = (npcOp == NPC_Order) ? (PC + 4) : 
                (npcOp == NPC_Branch) ? (PC + extImm) : // This PC is After b/j
                (npcOp == NPC_JmpImm) ? (extJmp) : 
                (npcOp == NPC_JmpReg) ? (jmpReg) : 
                (PC + 4);
    // assign PCToLink = PC + 8; // Delay Slot.
endmodule

/* Module: IM , from IM.v */
`include "IM.v"

module IF_LEVEL (
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
    /* Data Outputs for Next Pipeline */
    output reg [31:0]               code_ID     = 0, 
    output reg [31:0]               PC_ID       = 0
);
    /*
        Modules included: 
            PC, NPC, IM
        (Pseudo) Modules:
            
    */
    /* ------ Part 1: Wires Declaration ------ */
    wire [31:0] NPC, PC, code;

    /* ------ Part 2: Instantiate Modules ------ */

    NPC npc (
        .PC(PC), .instr(instr),
        .imm16(imm16), .cmp(cmp),
        .jmpAddr(jmpAddr), .jmpReg(jmpReg),
        .NPC(NPC)
    );
    
    PC pc (
        .clk(clk), .reset(reset),
        .En(~stallPC), // 
        .NPC(NPC), .PC(PC)
    );

    IM im (
        .PC(PC), .code(code)
    );

    /* ------ Part 3: Pipeline Registers ------ */
    always @(posedge clk) begin
        if (reset | clr) begin
            code_ID         <=  0;
            PC_ID           <=  0;
        end
        else if (!stall) begin
            code_ID         <=  code;
            PC_ID           <=  PC;
        end
    end

endmodule