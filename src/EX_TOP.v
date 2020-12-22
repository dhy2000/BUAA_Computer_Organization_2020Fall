/* 
 *  File Name: EX_TOP.v
 *  Module: EX_TOP
 *  Description: Pack ALU and forward logic and pipeline register into a top module
 */
`default_nettype none
`include "instructions.v"
`include "exception.v"

module ALU (
    /* Input */
    // Control
    input wire [`WIDTH_INSTR-1:0] instr,
    // Data
    input wire [31:0] dataRs, 
    input wire [31:0] dataRt, 
    input wire [15:0] imm16, 
    input wire [4:0] shamt,
    /* Output */
    output wire [31:0] out,
    // Exception
    output wire [6:2] exc
);
    /* Inner control signal */
    parameter WIDTH_Ext = 1,
        Zero_Ext = 0,
        Sign_Ext = 1;
    parameter WIDTH_Alu = 5,
        Alu_Zero    = 0,
        Alu_A       = 1,
        Alu_B       = 2,
        Alu_Add     = 3,
        Alu_Sub     = 4,
        Alu_And     = 5,
        Alu_Or      = 6,
        Alu_Xor     = 7,
        Alu_Nor     = 8,
        Alu_Slt     = 9,
        Alu_Sltu    = 10,
        Alu_Sll     = 11,
        Alu_Srl     = 12,
        Alu_Sra     = 13,
        Alu_Lui     = 14;
        // Alu_Clo     = 15,
        // Alu_Clz     = 16;
    /* Control */
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    wire [WIDTH_Ext-1:0] extOp;
    wire [WIDTH_Alu-1:0] aluOp;
    
    assign extOp = (
        (func == `FUNC_MEM_READ || func == `FUNC_MEM_WRITE) ? (Sign_Ext) :
        ((instr == `ANDI) || (instr == `ORI) || (instr == `XORI) || (instr == `LUI)) ? (Zero_Ext) : 
        (Sign_Ext) // default
    );

    assign aluOp = (
        (func == `FUNC_MEM_READ || func == `FUNC_MEM_WRITE) ? (Alu_Add) : 
        (instr == `ADD || instr == `ADDU || instr == `ADDIU || instr == `ADDI) ? (Alu_Add) : 
        (instr == `SUB || instr == `SUBU) ? (Alu_Sub) : 
        (instr == `AND || instr == `ANDI) ? (Alu_And) : 
        (instr == `OR || instr == `ORI) ? (Alu_Or) : 
        (instr == `XOR || instr == `XORI) ? (Alu_Xor) : 
        (instr == `NOR) ? (Alu_Nor) : 
        (instr == `SLT || instr == `SLTI) ? (Alu_Slt) : 
        (instr == `SLTU || instr == `SLTIU) ? (Alu_Sltu) : 
        (instr == `SLL || instr == `SLLV) ? (Alu_Sll) : 
        (instr == `SRL || instr == `SRLV) ? (Alu_Srl) : 
        (instr == `SRA || instr == `SRAV) ? (Alu_Sra) : 
        (instr == `LUI) ? (Alu_Lui) : 
        // (instr == `CLO) ? (Alu_Clo) : 
        // (instr == `CLZ) ? (Alu_Clz) : 
        (Alu_Zero) // default 
    );

    /* Execute */
    wire [31:0] extImm;
    assign extImm = (extOp == Sign_Ext) ? ({{16{imm16[15]}}, imm16}) : ({16'b0, imm16});

    wire [31:0] srca, srcb;
    assign srca = ((instr == `SLL || instr == `SRL || instr == `SRA)) ? {27'b0, shamt} : dataRs;
    assign srcb = ((func == `FUNC_CALC_I) || (func == `FUNC_MEM_READ) || (func == `FUNC_MEM_WRITE)) ? extImm : 
                    ((func == `FUNC_CALC_R)) ? dataRt : 
                    0; // default

    // function [31:0] countLeading;
    //     input [31:0] in;
    //     input _bit;
    //     integer i;
    //     reg flg;
    //     begin
    //         flg = 0;
    //         countLeading = 0;
    //         for (i = 31; i >= 0; i = i - 1) begin
    //             if (!flg && in[i] == _bit) countLeading = countLeading + 1;
    //             else flg = 1;
    //         end
    //     end
    // endfunction


    function [31:0] alu;
        input [31:0] a;
        input [31:0] b;
        input [WIDTH_Alu-1:0] op;
        begin
            case (op)
            Alu_Zero:   alu = 0;
            Alu_A:      alu = a;
            Alu_B:      alu = b;
            Alu_Add:    alu = a + b;
            Alu_Sub:    alu = a - b;
            Alu_And:    alu = a & b;
            Alu_Or:     alu = a | b;
            Alu_Xor:    alu = a ^ b;
            Alu_Nor:    alu = ~(a | b);
            Alu_Slt:    alu = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            Alu_Sltu:   alu = (a < b) ? 32'b1 : 32'b0;
            Alu_Sll:    alu = (b << a[4:0]);
            Alu_Srl:    alu = (b >> a[4:0]);
            Alu_Sra:    alu = ($signed($signed(b) >>> a[4:0]));
            Alu_Lui:    alu = {b, 16'b0};
            // Alu_Clo:    alu = countLeading(a, 1);
            // Alu_Clz:    alu = countLeading(a, 0);
            default:    alu = 0;
            endcase
        end
    endfunction

    assign out = alu(srca, srcb, aluOp);

    /* Exception */
    wire [32:0] tmpA = {srca[31], srca}, tmpB = {srcb[31], srcb};
    wire [32:0] tmpSum = tmpA + tmpB, tmpDif = tmpA - tmpB;
    wire ovfSum = (tmpSum[32] != tmpSum[31]), ovfDif = (tmpDif[32] != tmpDif[31]);

    assign exc = ((func == `FUNC_MEM_READ) && ovfSum) ? (`EXC_ADEL) : 
                ((func == `FUNC_MEM_WRITE) && ovfSum) ? (`EXC_ADES) : 
                ((instr == `ADD || instr == `ADDI) && ovfSum) ? (`EXC_OV) : 
                ((instr == `SUB) && ovfDif) ? (`EXC_OV) : 0;
endmodule

module MULTDIV (
    /* Input */
    // Time Sequential
    input wire clk, 
    input wire rst_n, 
    // Control
    input wire [`WIDTH_INSTR-1:0] instr,
    input wire enable, 
    // Data
    input wire [31:0] dataRs, 
    input wire [31:0] dataRt, 
    // output
    output wire busy, 
    output wire [31:0] out
);

    assign out = 0;
    assign busy = 0;

endmodule

module EX_TOP (
    /* Global Inputs */
    // Time Sequence
    input wire                      clk, 
    input wire                      rst_n, 
    // Pipeline Registers
    input wire                      stall, 
    input wire                      clr, 
    /* Data Inputs from Previous Pipeline */
    input wire [`WIDTH_INSTR-1:0]   instr_EX            , 
    input wire [31:0]               PC_EX               , 
    input wire [6:2]                Exc_EX              ,
    input wire                      BD_EX               ,
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
    /* Input External Control Signals */
    input wire                      dis_MULTDIV,
    /* Data Outputs to Next Pipeline */
    // Instruction
    output reg [`WIDTH_INSTR-1:0]   instr_MEM           = 0, 
    output reg [31:0]               PC_MEM              = 0, 
    output reg [6:2]                Exc_MEM             = 0,
    output reg                      BD_MEM              = 0,
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
    // wire mdBusy;
    wire [6:2] excAlu;
    // Hazard may use
    wire [4:0] regWriteAddr;
    wire [31:0] regWriteData;
    wire [`WIDTH_T-1:0] Tnew;
    // Exception
    wire [6:2] Exc;

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

    assign MDBusy_EX = 0; // Busy Signal

    assign Exc = Exc_EX ? Exc_EX : excAlu;

    /* ------ Part 2: Instantiate Modules ------ */

    ALU alu (
        .instr(instr_EX),
        .dataRs(dataRs_alu), .dataRt(dataRt_alu),
        .imm16(imm16_EX), .shamt(shamt_EX),
        .out(aluOut), .exc(excAlu)
    );

    MULTDIV md (
        .clk(clk), .rst_n(rst_n), 
        .instr(instr_EX), .enable(~dis_MULTDIV), 
        .dataRs(dataRs_alu), .dataRt(dataRt_alu), 
        .out(mdOut), .busy()
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
        // ((instr == `MFLO) || (instr == `MFHI)) ? (mdOut) : 
        ((func == `FUNC_CALC_R) || (func == `FUNC_CALC_I)) ? (aluOut) :
        (regWriteData_EX) // not alu instruction, use previous
    );
    
    // assign exOut = (instr == `MFLO || instr == `MFHI) ? mdOut : aluOut;
    assign exOut = aluOut;

    /* ------ Part 3: Pipeline Registers ------ */
    always @(posedge clk or negedge rst_n) begin
        if ((~rst_n)) begin
            instr_MEM                   <=  0;
            PC_MEM                      <=  0;
            Exc_MEM                     <=  0;
            BD_MEM                      <=  0;
            aluOut_MEM                  <=  0;
            dataRt_MEM                  <=  0;
            regWriteAddr_MEM            <=  0;
            regWriteData_MEM            <=  0;
            Tnew_MEM                    <=  0;
            addrRt_MEM                  <=  0;
            addrRd_MEM                  <=  0;
        end
        else if (clr) begin
            instr_MEM                   <=  0;
            PC_MEM                      <=  0;
            Exc_MEM                     <=  0;
            BD_MEM                      <=  0;
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
            Exc_MEM                     <=  Exc;
            BD_MEM                      <=  BD_EX;
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
