`default_nettype none
`include "../include/instructions.v"
`include "../include/memory.v"
`include "../include/exception.v"

/*
 *  Overview: Coprocessor 0
 *  Input:
 *      - Macro PC (and BD flag)
 *      - CP0 Register Request (mfc0/mtc0)
 *      - Exception code
 *      - Hardware Interruption
 *  Output:
 *      - EPC
 *      - Exception Operation (enter ktext / eret)
 *      - Register Value
 */
module CP0 (
    input wire clk,
    input wire reset,
    // macro instruction
    input wire `WORD MPC,
    input wire MBD,
    // cp0 instruction
    input wire `TYPE_INSTR instr,
    // cp0 register operation
    input wire `TYPE_REG regid,
    input wire `WORD WData,
    output wire `WORD RData,
    // Interrupt and Exception
    input wire `TYPE_INT HWINT,
    input wire `TYPE_EXC EXC,
    // EPC
    output reg `TYPE_EPC EPC = 0,
    output wire `TYPE_EXLOP EXLOp
);
    localparam  idSR    = 12, 
                idCause = 13,
                idEPC   = 14,
                idPrID  = 15;
    
    // CP0 Registers
    // 12: SR
    reg [7:2] IM = 6'b111111;
    reg EXL = 0, IE = 1;
    wire [31:0] SR = {16'b0, IM, 8'b0, EXL, IE};
    // 13: Cause
    reg [7:2] IP = 6'b000000;
    reg [6:2] ExcCode = 6'b000000;
    reg BD = 0;
    wire [31:0] Cause = {BD, 15'b0, IP, 3'b0, ExcCode, 2'b0};
    // 14: EPC, already in output port
    // 15: PrID
    reg [31:0] PrID = 32'hbaad_face;
    
    // Interrupt flag
    wire Interrupt;
    assign Interrupt = (IM[7:2] & HWINT[7:2]) && IE && (!EXL);

    // Exception flag
    // assert: exception will NOT happen in kernel text
    wire Exception;
    assign Exception = (EXC != 0);

    // EX LEVEL Op
    wire entry = (Interrupt || Exception);
    wire eret = (instr == `ERET);
    assign EXLOp =  (entry) ? (`EXL_ENTRY) : 
                    (eret) ? (`EXL_ERET) : (`EXL_NONE);

    // support MFC0, MTC0, ERET
    // MFC0 - Read
    assign RData = (instr == `MFC0) ? (
        (regid == idSR) ? (SR) : 
        (regid == idCause) ? (Cause) : 
        (regid == idEPC) ? ({EPC, 2'b0}) : 
        (regid == idPrID) ? (PrID) : 
        0
    ) : 0;

    // assign isBD = (Interrupt || Exception) ? BD : 0;

    always @ (posedge clk) begin
        if (reset) begin
            EXL <= 0;
            IE <= 1;
            IM <= 6'b111111;
            IP <= 0;
            ExcCode <= 0;
            BD <= 0;
            EPC <= 0;
        end
        else begin
            // SR
            if (eret) begin // Kernel State, no interrupt
                EXL <= 0;
            end
            else if (entry) begin
                EXL <= 1;
            end
            else if (instr == `MTC0 && regid == idSR) 
                {IM, EXL, IE} <= {WData[15:10], WData[1], WData[0]};
            // Cause
            IP <= HWINT;
            if (eret) begin
                ExcCode <= 0;
                BD <= 0;
            end
            else if (entry) begin
                ExcCode <= (Interrupt) ? 0 : EXC;
                BD <= MBD;
            end
            // EPC
            if (entry) begin
                EPC <= ((MBD ? (MPC - 4) : MPC) >> 2);
            end
            else if (instr == `MTC0 && regid == idEPC) begin
                EPC <= WData[31:2];
            end

            // PrID
            // cannot write
        end
    end


endmodule