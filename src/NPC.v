/* ------- NEXT PC -------- */

`default_nettype none
`include "instructions.v"
`include "InstrCategorizer.v"



module NPC (
    // inputs
    // data inputs
    input wire [31:0] PC, 
    input wire [15:0] Imm16, 
    input wire [25:0] JmpAddr, 
    input wire [31:0] JmpReg, 
    // Control Signals
    input wire [`InstrID_WIDTH-1:0] Instr, 
    input wire BranchCmp, // by branch comparator
    // outputs
    output wire [31:0] NextPC, 
    output wire [31:0] PCInOrder // PC + 4 or PC + 8, depends on whether the Delay-Slot is on
);

parameter NPC_Ctrl_WIDTH = 2;
parameter   NPC_Inorder = 0,
            NPC_Branch  = 1,
            NPC_JumpImm = 2,
            NPC_JumpReg = 3
;

    assign PCInOrder = PC + 4; // PC + 4 if Single-Cycle, PC + 8 if Pipeline

    /* Instantiate a Categorizer module */
    wire [`FUNCTYPE_WIDTH-1:0] functype;
    InstrCategorizer categorizer (
        .instr_id(Instr), 
        .format(), .functype(functype)
    );
    // Control Signal
    wire [NPC_Ctrl_WIDTH-1:0] ctrl;
    assign ctrl = (
        ((functype == `FUNC_BRANCH) && (BranchCmp)) ? (NPC_Branch) : 
        ((functype == `FUNC_JUMP)) ? (
            ((Instr == `J) || (Instr == `JAL)) ? (NPC_JumpImm) : (NPC_JumpReg)
        ) : 
        (NPC_Inorder) // default
    );

    wire [31:0] ExtBranchImm;
    assign ExtBranchImm = {{14{Imm16[15]}}, Imm16, 2'b0}; // sign extend and left shift 2
    wire [31:0] ExtJmpAddr;
    assign ExtJmpAddr = {PCInOrder[31:28], JmpAddr, 2'b0};

    assign NextPC = (
        (ctrl == NPC_Branch) ? (PCInOrder + ExtBranchImm) : 
        (ctrl == NPC_JumpImm) ? (ExtJmpAddr) : 
        (ctrl == NPC_JumpReg) ? (JmpReg) : 
        (PCInOrder)
    );

    
endmodule