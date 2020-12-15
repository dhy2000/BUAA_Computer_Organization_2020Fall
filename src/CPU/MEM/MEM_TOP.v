/* 
 *  File Name: MEM_LEVEL.v
 *  Module: DM
 *  Description: Pack DM and forward logic and pipeline register into a top module
 */

`default_nettype none
`include "../instructions.v"
`include "../IC.v"

`include "PREDM.v"
`include "CP0.v"

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
    input wire [31:0]               dataRt_MEM          ,
    input wire [4:0]                addrRt_MEM          ,
    input wire [4:0]                addrRd_MEM          ,
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
    output reg [31:0]               memWord_WB          = 0,
    output reg [1:0]                offset_WB           = 0,
    // regwrite
    output reg [4:0]                regWriteAddr_WB     = 0, 
    output reg [31:0]               regWriteData_WB     = 0,
    // Tnew
    output reg [`WIDTH_T-1:0]       Tnew_WB             = 0,
    /* -------- Connect with Real DM -------- */
    output wire [31:0]              DM_PC, 
    output wire [31:0]              DM_Addr, 
    output wire [31:0]              DM_WData, 
    output wire [3:0]               DM_WE, 
    input wire [31:0]               DM_RData, 
    /* -------- IOs for CP0 -------- */
    output wire [`WIDTH_KCTRL-1:0]  CP0_KCtrl, 
    output wire [31:2]              CP0_EPC
);
    
    /*
        Modules included: 
            DM
        (Pseudo) Modules:
            Sel(regWriteAddr), Sel(regWriteData), 
            Forward Selector
    */
    /* ------ Part 1: Wires Declaration ------ */
    // predm
    wire [1:0] offset;
    // real dm
    wire [31:0] memWord;
    // CP0
    wire [1:0] KCtrl;
    wire [31:2] EPC;
    wire [31:0] CP0Data;

    // Hazard may use
    wire [4:0] regWriteAddr;
    wire [31:0] regWriteData;
    wire [`WIDTH_T-1:0] Tnew;

    /* ------ Part 1.5: Select Data Source(Forward) ------ */
    wire [31:0] dataRt_use;
    assign dataRt_use = (
        (regaddr_WB == addrRt_MEM && regaddr_WB != 0) ? (regdata_WB) : 
        (dataRt_MEM)
    );
    
    assign Tnew = (Tnew_MEM >= 1) ?  (Tnew_MEM - 1) : 0;

    /* ------ Part 2: Instantiate Modules ------ */

    PREDM predm (
        .instr(instr_MEM), 
        .Addr(aluOut_MEM), .WData(dataRt_use), .PC(PC_MEM), 
        .DM_PC(DM_PC), .DM_Addr(DM_Addr[31:2]), .DM_WE(DM_WE), .DM_WData(DM_WData), 
        .offset(offset)
    );
    assign DM_Addr[1:0] = 0;

    assign memWord = DM_RData;

    // CP0
    CP0 cp0 (
        .clk(clk), .reset(reset), .PC(PC_MEM), // TODO: the CP0.PC should be Macro PC
        .WData(dataRt_use), .CP0id(addrRd_MEM), 
        .instr(instr_MEM), .instr_WB(instr_WB), 
        .HWInt(), .Exc(), 
        .KCtrl(KCtrl), .EPC(EPC), .RData(CP0Data)
    );

    assign CP0_KCtrl = KCtrl;
    assign CP0_EPC = EPC;


    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_INSTR-1:0] instr;
    assign instr = instr_MEM;
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign regWriteAddr = regWriteAddr_MEM;
    assign regWriteData = (
        ((func == `FUNC_MEM_READ)) ? (memWord) :
        (regWriteData_MEM) // not mem-load instruction, use previous
    );

    /* ------ Part 3: Pipeline Registers ------ */
    always @(posedge clk) begin
        if (reset | clr) begin
            instr_WB                <=  0;
            PC_WB                   <=  0;
            memWord_WB              <=  0;
            offset_WB               <=  0;
            regWriteAddr_WB         <=  0;
            regWriteData_WB         <=  0;
            Tnew_WB                 <=  0;
        end
        else if (!stall) begin
            instr_WB                <=  instr_MEM;
            PC_WB                   <=  PC_MEM;
            memWord_WB              <=  memWord;
            offset_WB               <=  offset;
            regWriteAddr_WB         <=  regWriteAddr;
            regWriteData_WB         <=  regWriteData;
            Tnew_WB                 <=  Tnew;
        end
    end
endmodule
