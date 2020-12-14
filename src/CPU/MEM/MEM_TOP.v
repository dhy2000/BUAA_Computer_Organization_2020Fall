/* 
 *  File Name: MEM_LEVEL.v
 *  Module: DM
 *  Description: Pack DM and forward logic and pipeline register into a top module
 */

`default_nettype none
`include "instructions.v"
`include "IC.v"

/* Module: DM, from DM.v */
`include "DM.v"

module MEM_TOP (
    /* Global Inputs */
    // Time Sequence
    input wire                      clk, 
    input wire                      reset, 
    // Pipeline Registers
    input wire                      stall, 
    input wire                      clr, 
    /* Data Inputs from Previous Pipeline */
    input wire [`WIDTH_INSTR-1:0]   instr_MEM           , 
    input wire [31:0]               PC_MEM              , 
    input wire [31:0]               aluOut_MEM          ,
    input wire [31:0]               memWriteData_MEM    ,
    input wire [4:0]                addrRt_MEM          ,
    input wire [4:0]                regWriteAddr_MEM    , 
    input wire [31:0]               regWriteData_MEM    ,
    input wire [`WIDTH_T-1:0]       Tnew_MEM            ,
    /* Data Inputs from Forward (Data to Write back to GRF) */
    input wire [4:0]                regaddr_WB, 
    input wire [31:0]               regdata_WB, 
    /* Data Outputs to Next Pipeline */
    // instruction
    output reg [`WIDTH_INSTR-1:0]   instr_WB            = 0, 
    output reg [31:0]               PC_WB               = 0, 
    // DM
    output reg [31:0]               memReadData_WB      = 0,
    // regwrite
    output reg [4:0]                regWriteAddr_WB     = 0, 
    output reg [31:0]               regWriteData_WB     = 0
);
    
    /*
        Modules included: 
            DM
        (Pseudo) Modules:
            Sel(regWriteAddr), Sel(regWriteData), 
            Forward Selector
    */
    /* ------ Part 1: Wires Declaration ------ */
    wire [31:0] memReadData;

    // Hazard may use
    wire [4:0] regWriteAddr;
    wire [31:0] regWriteData;
    wire [`WIDTH_T-1:0] Tnew;

    /* ------ Part 1.5: Select Data Source(Forward) ------ */
    wire [31:0] memWriteData_use;
    assign memWriteData_use = (
        (regaddr_WB == addrRt_MEM && regaddr_WB != 0) ? (regdata_WB) : 
        (memWriteData_MEM)
    );
    
    assign Tnew = (Tnew_MEM >= 1) ?  (Tnew_MEM - 1) : 0;

    /* ------ Part 2: Instantiate Modules ------ */
    DM dm (
        .clk(clk), .reset(reset), .instr(instr_MEM),
        .Addr(aluOut_MEM), .WData(memWriteData_use), .PC(PC_MEM),
        .RData(memReadData)
    );

    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_INSTR-1:0] instr;
    assign instr = instr_MEM;
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign regWriteAddr = regWriteAddr_MEM;
    assign regWriteData = (
        ((func == `FUNC_MEM_READ)) ? (memReadData) :
        (regWriteData_MEM) // not mem-load instruction, use previous
    );

    /* ------ Part 3: Pipeline Registers ------ */
    always @(posedge clk) begin
        if (reset | clr) begin
            instr_WB                <=  0;
            PC_WB                   <=  0;
            memReadData_WB          <=  0;
            regWriteAddr_WB         <=  0;
            regWriteData_WB         <=  0;
        end
        else if (!stall) begin
            instr_WB                <=  instr_MEM;
            PC_WB                   <=  PC_MEM;
            memReadData_WB          <=  memReadData;
            regWriteAddr_WB         <=  regWriteAddr;
            regWriteData_WB         <=  regWriteData;
        end
    end
endmodule
