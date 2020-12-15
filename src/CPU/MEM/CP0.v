/* 
 *  File Name: CP0.v
 *  Module Name: CP0
 *  Description: Coprocessor 0
 */
`default_nettype none

`include "../instructions.v"
`include "../IC.v"
`include "../../memconfig.v"
`include "../exception.v"

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