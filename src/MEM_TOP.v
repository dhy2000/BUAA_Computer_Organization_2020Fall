/* 
 *  File Name: MEM_LEVEL.v
 *  Module: DM
 *  Description: Pack DM and forward logic and pipeline register into a top module
 */

`default_nettype none
`include "instructions.v"
`include "memconfig.v"
`include "exception.v"

module CP0 (
    input wire clk, 
    input wire rst_n,
    input wire [31:0] PC,       // Macro PC?
    // input wire [31:0] PC_WB,    // Maybe not needed?
    input wire [31:0] WData, 
    input wire [4:0] CP0id,     // addrRd
    input wire [`WIDTH_INSTR-1:0] instr, 
    // input wire [`WIDTH_INSTR-1:0] instr_WB, // to check delay slot
    input wire BDFlag, 
    // Interrupt and Exception Control
    input wire [7:2] HWInt, 
    input wire [6:2] Exc,
    output wire [`WIDTH_KCTRL-1:0] KCtrl,       // control signal send to Pipeline Controller
    output wire isBD,                           // whether the exception instr is in the delay slot
    output wire [31:2] EPC,
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
    // EPC
    reg [31:0] epc = (`TEXT_STARTADDR);
    assign EPC = epc[31:2];
    // PrID
    reg [31:0] PrID = 32'hbaad_face;
    
    // Interrupt Handler
    wire Interrupt;
    assign Interrupt = (IM[7:2] & HWInt[7:2]) && IE && (!EXL);
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
        (CP0id == idEPC) ? ({EPC, 2'b0}) : 
        (CP0id == idPrID) ? (PrID) : 
        0
    ) : 0;

    // Check Branching Delay Slot
    // wire [`WIDTH_FUNC-1:0] func_WB;
    // IC ic_wb (.instr(instr_WB), .format(), .func(func_WB));
    wire isDelayBranch = BDFlag;

    assign isBD = (Interrupt || Exception) ? BDFlag : 0;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            EXL <= 0;
            IE <= 1;
            IM <= 6'b111111;
            IP <= 0;
            ExcCode <= 0;
            BD <= 0;
            epc <= (`TEXT_STARTADDR);
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
                ExcCode <= (Interrupt) ? 0 : Exc;
                BD <= isDelayBranch;
            end
            // EPC
            if (Interrupt || Exception) begin
                epc <= ((isDelayBranch ? (PC - 4) : PC) << 2) >> 2;
            end
            else if (instr == `MTC0 && CP0id == idEPC) begin
                epc <= {WData[31:2], 2'b00};
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
    // control signal
    input wire enable, 
    // Link To DM
    output wire [31:0] DM_PC, 
    output wire [31:2] DM_Addr, 
    output wire [3:0] DM_WE, 
    output wire [31:0] DM_WData, 
    // output inside cpu
    output wire [1:0] offset, 
    // exception
    output wire [6:2] exc
);
    // split the address
    assign DM_Addr = Addr[31:2];
    assign offset = Addr[1:0];
    
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign DM_WE = (!enable) ? 0 : 
        (func == `FUNC_MEM_WRITE) ? (
        (instr == `SW) ? (4'b1111) : 
        (instr == `SH) ? (4'b0011 << ({1'b0, offset[1]} << 1)) : 
        (instr == `SB) ? (4'b0001 << (offset)) : 
        (4'b0000)
    ) : 0;
    
    assign DM_PC = PC;
    assign DM_WData = (instr == `SH) ? (WData << ({4'b0, offset[1]} << 4)) : 
                    (instr == `SB) ? (WData << ({3'b0, offset} << 3)) : 
                    (WData);

    // Exceptions
    assign exc = (
        ((instr == `LW) && (Addr[1:0] != 0)) ? (`EXC_ADEL) : // load not-aligned word
        ((instr == `LH || instr == `LHU) && (Addr[0] != 0)) ? (`EXC_ADEL) : // load not-aligned halfword
        ((instr == `LH || instr == `LHU || instr == `LB || instr == `LBU) && !(Addr >= `DATA_STARTADDR && Addr < `DATA_ENDADDR)) ? (`EXC_ADEL) : // load non-whole word on timer register
        ((func == `FUNC_MEM_READ) && !(
            (Addr >= `DATA_STARTADDR && Addr < `DATA_ENDADDR) || 
            (Addr >= `TIMER0_STARTADDR && Addr < `TIMER0_ENDADDR) || 
            (Addr >= `TIMER1_STARTADDR && Addr < `TIMER1_ENDADDR) ||
            (Addr == `LED_ADDR) || 
            (Addr == `DIGITALTUBE_ADDR) || 
            (Addr == `BUTTONSWITCH_ADDR) || 
            (Addr >= `BUZZER_STARTADDR && Addr < `BUZZER_ENDADDR)
            )) ? (`EXC_ADEL) : // Not-Valid Address Space
        ((instr == `SW) && (Addr[1:0] != 0)) ? (`EXC_ADES) : // store not-aligned word
        ((instr == `SH) && (Addr[0] != 0)) ? (`EXC_ADES) : // store not-aligned halfword
        ((instr == `SH || instr == `SB) && !(Addr >= `DATA_STARTADDR && Addr < `DATA_ENDADDR)) ? (`EXC_ADES) : 
        ((func == `FUNC_MEM_WRITE) && !(
            (Addr >= `DATA_STARTADDR && Addr < `DATA_ENDADDR) || 
            (Addr >= `TIMER0_STARTADDR && Addr < `TIMER0_ENDADDR) || 
            (Addr >= `TIMER1_STARTADDR && Addr < `TIMER1_ENDADDR) || 
            (Addr == `LED_ADDR) || 
            (Addr == `DIGITALTUBE_ADDR) || 
            (Addr == `BUTTONSWITCH_ADDR) || 
            (Addr >= `BUZZER_STARTADDR && Addr < `BUZZER_ENDADDR)
            )) ? (`EXC_ADES) :
        ((func == `FUNC_MEM_WRITE) && (Addr == 32'h0000_7F08 || Addr == 32'h0000_7F18)) ? (`EXC_ADES) :
        0
    );
endmodule

module MEM_TOP (
    /* Global Inputs */
    // Time Sequence
    input wire                      clk, 
    input wire                      rst_n, 
    // Pipeline Registers
    input wire                      stall, 
    input wire                      clr, 
    /* Data Inputs from Previous Pipeline */
    input wire [`WIDTH_INSTR-1:0]   instr_MEM           , 
    input wire [31:0]               PC_MEM              , 
    input wire [6:2]                Exc_MEM             ,
    input wire                      BD_MEM              ,
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
    /* Input Control Signals */
    input wire                      dis_DM, 
    input wire                      BD_Macro,   // sync with macro pc
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
    output wire [31:2]              CP0_EPC,
    output wire                     CP0_BD
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
    wire [6:2] excDM;
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
    // Exception
    wire [6:2] Exc;

    /* ------ Part 1.5: Select Data Source(Forward) ------ */
    wire [31:0] dataRt_use;
    assign dataRt_use = (
        (regaddr_WB == addrRt_MEM && regaddr_WB != 0) ? (regdata_WB) : 
        (dataRt_MEM)
    );
    
    assign Tnew = (Tnew_MEM >= 1) ?  (Tnew_MEM - 1) : 0;

    /* ------ Part 2: Instantiate Modules ------ */

    PREDM predm (
        .instr(instr_MEM), .enable(~dis_DM), 
        .Addr(aluOut_MEM), .WData(dataRt_use), .PC(PC_MEM), 
        .DM_PC(DM_PC), .DM_Addr(DM_Addr[31:2]), .DM_WE(DM_WE), .DM_WData(DM_WData), 
        .offset(offset), .exc(excDM)
    );
    assign DM_Addr[1:0] = 0;

    assign memWord = DM_RData;

    assign Exc = Exc_MEM ? Exc_MEM : excDM;

    // CP0
    CP0 cp0 (
        .clk(clk), .rst_n(rst_n), .PC(CP0_PC),
        .WData(dataRt_use), .CP0id(addrRd_MEM), 
        .instr(instr_MEM), .BDFlag(BD_Macro), 
        .HWInt(CP0_HWInt), .Exc(Exc), .isBD(CP0_BD), 
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
        ((func == `FUNC_CP0) && (instr == `MFC0)) ? (CP0Data) : 
        ((func == `FUNC_MEM_READ)) ? (memWord) :
        (regWriteData_MEM) // not mem-load instruction, use previous
    );

    /* ------ Part 3: Pipeline Registers ------ */
    always @(posedge clk or negedge rst_n) begin
        if ((~rst_n)) begin
            instr_WB                <=  0;
            PC_WB                   <=  0;
            memWord_WB              <=  0;
            offset_WB               <=  0;
            regWriteAddr_WB         <=  0;
            regWriteData_WB         <=  0;
            Tnew_WB                 <=  0;
        end
        else if (clr) begin
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
