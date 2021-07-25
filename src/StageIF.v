/* 
 *  Overview: Pipeline Stage F (instruction Fetch)
 */

`default_nettype none
`include "include/instructions.v"
`include "include/memconfig.v"
`include "include/exception.v"

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
    input wire [15:0] imm16,
    input wire [25:0] jmpAddr,
    input wire [31:0] jmpReg,
    // Exception
    input wire `TYPE_ECTRL excCtrl,
    input wire [31:2] EPC,
    // output
    output reg [31:0] PC = `PC_BOOT,
    output wire BD,
    output wire `TYPE_EXC excCode
);
    localparam
        NPC_Order   = 0,
        NPC_Branch  = 1,
        NPC_JmpImm  = 2,
        NPC_JmpReg  = 3,
        NPC_ExcEnt  = 4,
        NPC_ExcRet  = 5,
        NPC_Keep    = 6;
    
    // BD Flag
    assign BD = (ifunc == `I_BRANCH || ifunc == `I_JUMP); // no matter whether really branch

    // Extend Immediate
    wire `WORD extImm, extJmp;
    assign extImm = {{14{imm16[15]}}, imm16, 2'b0};
    assign extJmp = {PC[31:28], jmpAddr, 2'b0};

    // Termination to avoid pc out of range without ending infinite loop
    wire terminated;    // reserved
    assign terminated = (PC == `KTEXT_START - 4);

    // NPC Control
    wire [3 : 0] npcOp;
    assign npcOp = (
        (excCtrl == `E_ENTRY) ? (NPC_ExcEnt) : 
        (excCtrl == `E_ERET) ? (NPC_ExcRet) :
        (terminated) ? (NPC_Keep) :
        (instr == `JALR || instr == `JR) ? (NPC_JmpReg) : 
        (instr == `J    || instr == `JAL) ? (NPC_JmpImm) : 
        ((ifunc == `I_BRANCH) && cmp) ? (NPC_Branch) : 
        (NPC_Order)
    );
    
    // Select data source
    wire [31 : 0] NPC;
    assign NPC = (npcOp == NPC_Order) ? (PC + 4) : 
                (npcOp == NPC_Branch) ? (PC + extImm) : // This PC is After b/j
                (npcOp == NPC_JmpImm) ? (extJmp) : 
                (npcOp == NPC_JmpReg) ? (jmpReg) : 
                (npcOp == NPC_ExcEnt) ? (`KTEXT_START) : 
                (npcOp == NPC_ExcRet) ? ({EPC[31:2], 2'b0}) :
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
    assign excCode = ((!(PC >= `IM_ADDR_START && PC < `IM_ADDR_END)) || (PC[1:0] != 0)) ? (`EXC_ADEL) : 0;

endmodule

module StageIF (
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
    input wire [`WIDTH_ECTRL-1:0]   KCtrl, 
    input wire [31:2]               EPC, 
    /* Data Outputs for Next Pipeline */
    output reg [31:0]               code_ID     = 0, 
    output reg [31:0]               PC_ID       = 0,
    output reg [6:2]                Exc_ID      = 0,
    output reg                      BD_ID       = 0, 
    /* Other Outputs */
    output wire [31:0]              PC_IF, 
    output wire                     BD_IF
);
    /*
        Modules included: 
            PC, NPC, IM
        (Pseudo) Modules:
            
    */
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

    IM im (
        .PC(PC), .code(code)
    );

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
