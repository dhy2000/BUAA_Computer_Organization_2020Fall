/* 
 *  File Name: IF_LEVEL.v
 *  Module: NPC, PC, IM
 *  Description: Pack (NPC, PC, IM) into a top module 
 */

`default_nettype none
`include "../instructions.v"
`include "../../memconfig.v"
`include "../IC.v"
`include "../exception.v"

/* Module: IM , from IM.v */
`include "IM.v"
`include "NPC.v"
`include "PC.v"

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
    /* Other Outputs */
    output wire [31:0]              PC_IF
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
        .KCtrl(KCtrl), .EPC(EPC), 
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

    assign PC_IF = PC;

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