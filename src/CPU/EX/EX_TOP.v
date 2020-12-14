/* 
 *  File Name: EX_TOP.v
 *  Module: EX_TOP
 *  Description: Pack ALU and forward logic and pipeline register into a top module
 */

`default_nettype none
`include "../instructions.v"
`include "../IC.v"

`include "ALU.v"
`include "MULTDIV.v"

module EX_TOP (
    /* Global Inputs */
    // Time Sequence
    input wire                      clk, 
    input wire                      reset, 
    // Pipeline Registers
    input wire                      stall, 
    input wire                      clr, 
    /* Data Inputs from Previous Pipeline */
    input wire [`WIDTH_INSTR-1:0]   instr_EX            , 
    input wire [31:0]               PC_EX               , 
    input wire [31:0]               dataRs_EX           , 
    input wire [31:0]               dataRt_EX           , 
    input wire [15:0]               imm16_EX            , 
    input wire [4:0]                shamt_EX            , 
    input wire [4:0]                addrRs_EX           ,
    input wire [4:0]                addrRt_EX           ,
    input wire [4:0]                addrRd_EX           ,
    input wire [4:0]                regWriteAddr_EX     , 
    input wire [31:0]               regWriteData_EX     , 
    input wire [`WIDTH_T-1:0]       Tnew_EX             ,
    /* Data Inputs from Forward (Data to Write back to GRF) */
    input wire [4:0]                regaddr_MEM, 
    input wire [31:0]               regdata_MEM, 
    input wire [4:0]                regaddr_WB, 
    input wire [31:0]               regdata_WB, 
    /* Data Outputs to Next Pipeline */
    // Instruction
    output reg [`WIDTH_INSTR-1:0]   instr_MEM           = 0, 
    output reg [31:0]               PC_MEM              = 0, 
    // From ALU
    output reg [31:0]               aluOut_MEM          = 0,

    // RegUsed
    output reg [4:0]                addrRt_MEM          = 0,
    output reg [31:0]               dataRt_MEM          = 0,
    output reg [4:0]                addrRd_MEM          = 0,
    // RegWrite
    output reg [4:0]                regWriteAddr_MEM    = 0, 
    output reg [31:0]               regWriteData_MEM    = 0,
    // Tnew
    output reg [`WIDTH_T-1:0]       Tnew_MEM            = 0,
    // Mult/Div Unit
    output wire                     MDBusy_EX
);
    /*
        Modules included: 
            ALU
        (Pseudo) Modules:
            Sel(regWriteAddr), Sel(regWriteData), 
            Forward Selector
    */
    /* ------ Part 1: Wires Declaration ------ */
    wire [31:0] aluOut;
    wire [31:0] mdOut;
    wire [31:0] exOut;
    wire mdBusy;
    // Hazard may use
    wire [4:0] regWriteAddr;
    wire [31:0] regWriteData;
    wire [`WIDTH_T-1:0] Tnew;

    /* ------ Part 1.5: Select Data Source(Forward) ------ */

    wire [31:0] dataRs_alu, dataRt_alu;
    assign dataRs_alu = (
        (regaddr_MEM == addrRs_EX && regaddr_MEM != 0) ? (regdata_MEM) : 
        (regaddr_WB == addrRs_EX && regaddr_WB != 0) ? (regdata_WB) : 
        (dataRs_EX)
    ); 
    assign dataRt_alu = (
        (regaddr_MEM == addrRt_EX && regaddr_MEM != 0) ? (regdata_MEM) : 
        (regaddr_WB == addrRt_EX && regaddr_WB != 0) ? (regdata_WB) : 
        (dataRt_EX)
    ); 

    assign Tnew = (Tnew_EX >= 1) ? (Tnew_EX - 1) : 0; // TODO: mult/div module stalls

    assign MDBusy_EX = mdBusy; // Busy Signal

    /* ------ Part 2: Instantiate Modules ------ */

    ALU alu (
        .instr(instr_EX),
        .dataRs(dataRs_alu), .dataRt(dataRt_alu),
        .imm16(imm16_EX), .shamt(shamt_EX),
        .out(aluOut)
    );

    MULTDIV md (
        .clk(clk), .reset(reset), 
        .instr(instr_EX), 
        .dataRs(dataRs_alu), .dataRt(dataRt_alu), 
        .out(mdOut), .busy(mdBusy)
    );

    // assign memWriteData = dataRt_alu;
    

    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_INSTR-1:0] instr;
    assign instr = instr_EX;
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign regWriteAddr = regWriteAddr_EX;
    assign regWriteData = (
        ((instr == `MFLO) || (instr == `MFHI)) ? (mdOut) : 
        ((func == `FUNC_CALC_R) || (func == `FUNC_CALC_I)) ? (aluOut) :
        (regWriteData_EX) // not alu instruction, use previous
    );
    
    assign exOut = (instr == `MFLO || instr == `MFHI) ? mdOut : aluOut;

    /* ------ Part 3: Pipeline Registers ------ */
    always @(posedge clk) begin
        if (reset | clr) begin
            instr_MEM                   <=  0;
            PC_MEM                      <=  0;
            aluOut_MEM                  <=  0;
            dataRt_MEM                  <=  0;
            regWriteAddr_MEM            <=  0;
            regWriteData_MEM            <=  0;
            Tnew_MEM                    <=  0;
            addrRt_MEM                  <=  0;
            addrRd_MEM                  <=  0;
        end
        else if (!stall) begin
            instr_MEM                   <=  instr_EX;
            PC_MEM                      <=  PC_EX;
            aluOut_MEM                  <=  exOut;
            dataRt_MEM                  <=  dataRt_alu;
            regWriteAddr_MEM            <=  regWriteAddr;
            regWriteData_MEM            <=  regWriteData;
            Tnew_MEM                    <=  Tnew;
            addrRt_MEM                  <=  addrRt_EX;
            addrRd_MEM                  <=  addrRd_EX;
        end
    end

endmodule
