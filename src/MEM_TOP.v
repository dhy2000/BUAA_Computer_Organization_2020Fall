`ifndef CPU_MEM_TOP_INCLUDED
`define CPU_MEM_TOP_INCLUDED
/* 
 *  File Name: MEM_LEVEL.v
 *  Module: DM
 *  Description: Pack DM and forward logic and pipeline register into a top module
 */

`default_nettype none
`include "instructions.v"
// `include "IC.v"
`include "memconfig.v"
`include "exception.v"

module CP0 (
    input wire clk, 
    input wire reset,
    input wire [31:0] PC,       // Macro PC?
    // input wire [31:0] PC_WB,    // Maybe not needed?
    input wire [31:0] WData, 
    input wire [4:0] CP0id,     // addrRd
    input wire [`WIDTH_INSTR-1:0] instr, 
    input wire [`WIDTH_INSTR-1:0] instr_WB, // to check delay slot
    // Interrupt and Exception Control
    input wire [7:2] HWInt, 
    input wire [6:2] Exc,
    output wire [`WIDTH_KCTRL-1:0] KCtrl,       // control signal send to Pipeline Controller
    output reg [31:2] EPC = (`TEXT_STARTADDR >> 2), 
    output wire [31:0] RData
);
parameter   idSR    = 12, 
            idCause = 13,
            idEPC   = 14,
            idPrID  = 15;
    // SR, Cause, PrID
    // SR
    reg [7:2] IM = 6'b111111;
    reg EXL = 0, IE = 1;
    wire [31:0] SR = {16'b0, IM, 8'b0, EXL, IE};
    // Cause
    reg [7:2] IP = 6'b000000;
    reg [6:2] ExcCode = 6'b000000;
    reg BD = 0;
    wire [31:0] Cause = {BD, 15'b0, IP, 3'b0, ExcCode, 2'b0};
    // PrID
    reg [31:0] PrID = 32'hbaad_face;
    
    // Interrupt Handler
    wire Interrupt;
    assign Interrupt = (IM[7:2] & HWInt[7:2]) & IE & (!EXL);
    // Exception Handler
    // assert: exception will NOT happen in kernel text
    wire Exception;
    assign Exception = (Exc != 0);

    // Total Kernal Entry
    assign KCtrl = (Interrupt || Exception) ? (`KCTRL_KTEXT) : 
                    (instr == `ERET) ? (`KCTRL_ERET) : (`KCTRL_NONE);

    // support MFC0, MTC0, ERET
    // MFC0 - Read
    assign RData = (instr == `MFC0) ? (
        (CP0id == idSR) ? (SR) : 
        (CP0id == idCause) ? (Cause) : 
        (CP0id == idEPC) ? (EPC) : 
        (CP0id == idPrID) ? (PrID) : 
        0
    ) : 0;

    // Check Branching Delay Slot
    wire [`WIDTH_FUNC-1:0] func_WB;
    IC ic_wb (.instr(instr_WB), .format(), .func(func_WB));
    wire isDelayBranch = (func_WB == `FUNC_BRANCH || func_WB == `FUNC_JUMP);

    always @ (posedge clk) begin
        if (reset) begin
            EXL <= 0;
            IE <= 1;
            IM <= 6'b111111;
            IP <= 0;
            ExcCode <= 0;
            BD <= 0;
            EPC <= (`TEXT_STARTADDR >> 2);
        end
        else begin
            // SR
            if (instr == `ERET) begin // Kernel State, no interrupt
                EXL <= 0;
            end
            else if (Interrupt || Exception) begin
                EXL <= 1;
            end
            else if (instr == `MTC0 && CP0id == idSR) 
                {IM, EXL, IE} <= {WData[15:10], WData[1], WData[0]};
            // Cause
            IP <= HWInt;
            if (instr == `ERET) begin
                ExcCode <= 0;
                BD <= 0;
            end
            else if (Interrupt || Exception) begin
                ExcCode <= Exc;
                BD <= isDelayBranch;
            end
            // EPC
            if (Interrupt || Exception) begin
                EPC <= isDelayBranch ? (PC - 4) : PC;
            end
            else if (instr == `MTC0 && CP0id == idEPC) begin
                EPC <= WData;
            end

            // PrID
            // cannot write
        end
    end


endmodule

module PREDM (
    input wire [`WIDTH_INSTR-1:0] instr, 
    input wire [31:0] Addr, 
    input wire [31:0] WData, 
    input wire [31:0] PC, 
    // Link To DM
    output wire [31:0] DM_PC, 
    output wire [31:2] DM_Addr, 
    output wire [3:0] DM_WE, 
    output wire [31:0] DM_WData, 
    // output inside cpu
    output wire [1:0] offset
);
    // split the address
    assign DM_Addr = Addr[31:2];
    assign offset = Addr[1:0];
    
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign DM_WE = (func == `FUNC_MEM_WRITE) ? (
        (instr == `SW) ? (4'b1111) : 
        (instr == `SH) ? (4'b0011 << ({1'b0, offset[1]} << 1)) : 
        (instr == `SB) ? (4'b0001 << (offset)) : 
        (4'b0000)
    ) : 0;
    
    assign DM_PC = PC;
    assign DM_WData = (instr == `SH) ? (WData << ({4'b0, offset[1]} << 4)) : 
                    (instr == `SB) ? (WData << ({3'b0, offset} << 3)) : 
                    (WData);

endmodule

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
    input wire [31:0]               CP0_PC, 
    input wire [7:2]                CP0_HWInt,
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
        .clk(clk), .reset(reset), .PC(CP0_PC),
        .WData(dataRt_use), .CP0id(addrRd_MEM), 
        .instr(instr_MEM), .instr_WB(instr_WB), 
        .HWInt(CP0_HWInt), .Exc(5'b0), 
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
`endif
