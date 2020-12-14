/* 
 *  File Name: ID_LEVEL.v
 *  Module: DECD(Decoder), COMP(Comparator), ID_LEVEL
 *  Description: Pack (DECD, COMP, Interfaces for GRF, Pipeline Register) 
 */

`default_nettype none
`include "../instructions.v"
`include "../IC.v"

/* ------ Instruction Decode and Register Read ------ */
module ID_LEVEL (
    /* Global Inputs */
    // Time Sequence
    input wire                      clk, 
    input wire                      reset, 
    // Pipeline Registers
    input wire                      stall, 
    input wire                      clr, 
    /* Data Inputs from Previous Pipeline */
    input wire [31:0]               code_ID, // Machine Code from IM@IF
    input wire [31:0]               PC_ID,   // PC from PC@IF
    /* Data Inputs from Forward (Data to Write back to GRF) */
    input wire [4:0]                regaddr_EX, 
    input wire [31:0]               regdata_EX, 
    input wire [4:0]                regaddr_MEM,
    input wire [31:0]               regdata_MEM, 
    // input wire [31:0] reg_WB, // Omitted because of Inner-Forward@GRF
    /* Input from Hazard Unit */
    input wire [`WIDTH_T-1:0]       Tnew_ID,
    /* Data Outputs to Next Pipeline */
    // Instruction
    output reg [`WIDTH_INSTR-1:0]   instr_EX            = 0, 
    output reg [31:0]               PC_EX               = 0, 
    // Decoder
    output reg [31:0]               dataRs_EX           = 0, // Need Forward
    output reg [31:0]               dataRt_EX           = 0, // Need Forward
    output reg [15:0]               imm16_EX            = 0, 
    output reg [4:0]                shamt_EX            = 0, 
    // RegUsed
    output reg [4:0]                addrRs_EX           = 0,
    output reg [4:0]                addrRt_EX           = 0,
    // RegWrite
    output reg [4:0]                regWriteAddr_EX     = 0, 
    output reg [31:0]               regWriteData_EX     = 0, 
    // Tnew
    output reg [`WIDTH_T-1:0]       Tnew_EX             = 0,
    /* Data Outputs for NPC */
    output wire [`WIDTH_INSTR-1:0]  instr_NPC, 
    output wire                     cmp_NPC,
    output wire [15:0]              imm16_NPC, 
    output wire [25:0]              jmpAddr_NPC, 
    output wire [31:0]              jmpReg_NPC,
    /* Outputs for Hazard Unit */
    output wire [`WIDTH_INSTR-1:0]  instr_ID, 
    output wire [4:0]               addrRs_ID, 
    output wire [4:0]               addrRt_ID, 
    /* Interfaces for GRF-READ */
    output wire [4:0]               RA1_GRF, 
    output wire [4:0]               RA2_GRF,
    input wire [31:0]               RD1_GRF, 
    input wire [31:0]               RD2_GRF
);
    
    /*
        Modules included: 
            Decoder, Comparator, 
        (Pseudo) Modules:
            Imm Extender for [lui], 
            Sel(regWriteAddr), Sel(regWriteData), 
            Forward Selector
        External Module: GRF
    */

    /* ------ Part 1: Wires Declaration ------ */
    wire [`WIDTH_INSTR-1:0] instr;
    wire [4:0] addrRs, addrRt, addrRd;
    wire [15:0] imm16; wire [4:0] shamt;
    wire [25:0] jmpAddr;
    wire cmp;
    wire [31:0] luiExtImm;
    // Hazard may use
    wire [4:0] regWriteAddr;
    wire [31:0] regWriteData;
    // Tnew
    wire [`WIDTH_T-1:0] Tnew;

    /* ------ Part 1.5: Select Data Source(Forward) ------ */
    // GRF already supports inner forward.
    wire [31:0]dataRs_use, dataRt_use;
    assign dataRs_use = (
        (regaddr_EX == addrRs && regaddr_EX != 0) ? (regdata_EX) : 
        (regaddr_MEM == addrRs && regaddr_MEM != 0) ? (regdata_MEM) : 
        (RD1_GRF)
    ); 
    assign dataRt_use = (
        (regaddr_EX == addrRt && regaddr_EX != 0) ? (regdata_EX) : 
        (regaddr_MEM == addrRt && regaddr_MEM != 0) ? (regdata_MEM) : 
        (RD2_GRF)
    ); 

    assign Tnew = (Tnew_ID >= 1) ? (Tnew_ID - 1) : 0;
    /* ------ Part 2: Instantiate Modules ------ */
    DECD decd (
        .code(code_ID), .instr(instr),
        .rs(addrRs), .rt(addrRt), .rd(addrRd),
        .imm(imm16), .shamt(shamt), .jmpaddr(jmpAddr), 
        .excRI()
    );
    COMP comp (
        .instr(instr),
        .dataRs(dataRs_use), .dataRt(dataRt_use),
        .cmp(cmp)
    );
    assign luiExtImm = {imm16, 16'b0};

    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign regWriteAddr =   (instr == `BGEZAL || instr == `BLTZAL) ? (cmp ? 31 : 0) : // conditionally link according to MARS, but directly link according to MIPS-V2.
                            (instr == `MOVZ || instr == `MOVN) ? (cmp ? addrRd : 0) : 
                            (instr == `JAL)                  ? 31 :       // JAL
                            ((func == `FUNC_CALC_R) || (instr == `JALR) || (instr == `MFHI) || (instr == `MFLO)) ? addrRd :  // rd
                            ((func == `FUNC_CALC_I) || (func == `FUNC_MEM_READ))  ? addrRt :  // rt
                            0;
                            
    assign regWriteData =   (instr == `MOVZ || instr == `MOVN) ? (cmp ? dataRs_use : 0) : 
                            ((instr == `JAL) || (instr == `JALR) || (instr == `BGEZAL) || (instr == `BLTZAL))     ?   PC_ID + 8   :   // Jump Link
                            ((instr == `LUI))                       ?   luiExtImm   :   // LUI(I-instr which don't need data from grf to alu)
                            0; // Default
    /* ------ Part 3: Pipeline Registers ------ */
    always @ (posedge clk) begin
        if (reset | clr) begin
            instr_EX            <= 0;
            PC_EX               <= 0;
            dataRs_EX           <= 0;
            dataRt_EX           <= 0;
            imm16_EX            <= 0;
            shamt_EX            <= 0;
            addrRs_EX           <= 0;
            addrRt_EX           <= 0;
            regWriteAddr_EX     <= 0;
            regWriteData_EX     <= 0;
            Tnew_EX             <= 0;
        end
        else if (!stall) begin
            instr_EX            <=  instr;
            PC_EX               <=  PC_ID;
            dataRs_EX           <=  dataRs_use;
            dataRt_EX           <=  dataRt_use;
            imm16_EX            <=  imm16;
            shamt_EX            <=  shamt;
            addrRs_EX           <=  addrRs;
            addrRt_EX           <=  addrRt;
            regWriteAddr_EX     <=  regWriteAddr;
            regWriteData_EX     <=  regWriteData;
            Tnew_EX             <=  Tnew;
        end
    end
    /* ------ Part 3.5: Assign Wire Outputs ------ */
    assign instr_NPC = instr;
    assign cmp_NPC = cmp;
    assign imm16_NPC = imm16;
    assign jmpAddr_NPC = jmpAddr;
    assign jmpReg_NPC = dataRs_use;
    assign RA1_GRF = addrRs;
    assign RA2_GRF = addrRt;
    assign instr_ID = instr;
    assign addrRs_ID = addrRs;
    assign addrRt_ID = addrRt;
    
endmodule