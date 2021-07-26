/* 
 *  Overview: Pipeline stage E (Execute)
 */

`default_nettype none
`include "../include/instructions.v"
`include "../include/exception.v"
`include "../include/memory.v"

/*
 *  Overview: ALU
 *  Input: Two source data.
 *  Output: ALU result and Exception (ADEL, ADES, OV)
 */

module ALU (
    // Instruction
    input wire `TYPE_INSTR instr,
    input wire `TYPE_IFUNC ifunc, 
    // Data In
    input wire `WORD srca, 
    input wire `WORD srcb, 
    // Output
    output wire `WORD out,
    output wire `TYPE_EXC exc
);
    localparam WIDTH_Alu = 5,
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
        Alu_Clo     = 14,
        Alu_Clz     = 15;
    
    /* Control */
    wire [WIDTH_Alu - 1 : 0] aluOp;
    assign aluOp = (
        (ifunc == `I_MEM_R || ifunc == `I_MEM_W) ? (Alu_Add) :
        (instr == `ADD || instr == `ADDU || instr == `ADDIU || instr == `ADDI) ? (Alu_Add) :
        (instr == `SUB || instr == `SUBU) ? (Alu_Sub) :
        (instr == `AND || instr == `ANDI) ? (Alu_And) :
        (instr == `OR || instr == `ORI) ? (Alu_Or) :
        (instr == `XOR || instr == `XORI) ? (Alu_Xor) :
        (instr == `NOR) ? (Alu_Nor) :
        (instr == `LUI) ? (Alu_B) :
        (instr == `SLT || instr == `SLTI) ? (Alu_Slt) :
        (instr == `SLTU || instr == `SLTIU) ? (Alu_Sltu) :
        (instr == `SLL || instr == `SLLV) ? (Alu_Sll) :
        (instr == `SRL || instr == `SRLV) ? (Alu_Srl) :
        (instr == `SRA || instr == `SRAV) ? (Alu_Sra) :
        (instr == `CLO) ? (Alu_Clo) :
        (instr == `CLZ) ? (Alu_Clz) :
        (Alu_Zero) // default
    );

    function [31:0] countLeading;
        input [31:0] in;
        input bit;
        integer i;
        reg flg;
        begin
            flg = 0;
            countLeading = 0;
            for (i = 31; i >= 0; i = i - 1) begin
                if (!flg && in[i] == bit) countLeading = countLeading + 1;
                else flg = 1;
            end
        end
    endfunction

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
            Alu_Clo:    alu = (countLeading(a, 1));
            Alu_Clz:    alu = (countLeading(a, 0));
            default:    alu = 0;
            endcase
        end
    endfunction

    assign out = alu(srca, srcb, aluOp);

    // Overflow Detect
    wire [32:0] signA = {srca[31], srca}, signB = {srcb[31], srcb};
    wire [32:0] signSum = signA + signB, signDif = signA - signB;
    wire ovfSum = (signSum[32] != signSum[31]), ovfDif = (signDif[32] != signDif[31]);

    // Exception generate
    assign exc =    ((ifunc == `I_MEM_R) && ovfSum) ? (`EXC_ADEL) : 
                    ((ifunc == `I_MEM_W) && ovfSum) ? (`EXC_ADES) : 
                    ((instr == `ADD || instr == `ADDI) && ovfSum) ? (`EXC_OV) : 
                    ((instr == `SUB) && ovfDif) ? (`EXC_OV) : 0;

endmodule

/*
 *  Overview: Multiply and Division Unit
 *  Input: 
 *      - Two source operands
 *      - Instruction
 *      - Enable signal
 *  Output:
 *      - Register HI and LO
 *      - Busy signal
 */
module MDU (
    input wire clk, 
    input wire reset,
    // Instruction
    input wire `TYPE_INSTR instr,
    input wire `TYPE_IFUNC ifunc,
    // Control
    input wire en,
    // Data in
    input wire `WORD srca, 
    input wire `WORD srcb,
    // Output
    output reg `WORD hi = 0,
    output reg `WORD lo = 0,
    // Status
    output wire busy
);

    /*
     *  Supported instructions:
     *      mult, multu, div, divu
     *      mtlo, mthi
     *      madd, maddu, msub, msubu
     */

    // This unit is ONLY for simulation. If synthesis needed, please use IPCORE or build it in gate-level.

    localparam MULT_DELAY = 5;
    localparam DIV_DELAY = 10;

    /* Part 1. Calculation for multiply and division */
    // registers to store instr and operands
    reg `WORD A, B;
    reg `TYPE_INSTR instr_reg;

    // control signals
    wire isMult =  ((instr == `MULT) || (instr == `MULTU) ||
                    (instr == `MADD) || (instr == `MADDU) ||
                    (instr == `MSUB) || (instr == `MSUBU));
    wire isDiv = ((instr == `DIV) || (instr == `DIVU)) && (srcb != 0); // divisor mustn't be zero

    wire isStart = (en) & (isMult | isDiv);
    
    // signed or not
    wire sign = ((instr == `MULTU) || (instr == `DIVU) || (instr == `MADDU) || (instr == `MSUBU)) ? 1'b0 : 1'b1;
    
    // mult
    wire [63:0] product;

    wire [63:0] uExtA = {32'b0, srca};
    wire [63:0] uExtB = {32'b0, srcb};
    wire [63:0] sExtA = {{32{srca[31]}}, srca};
    wire [63:0] sExtB = {{32{srcb[31]}}, srcb};

    /////////////// REPLACE IF SYNTHESIS ///////////////
    assign product = (sign) ? (sExtA * sExtB) : (uExtA * uExtB);    // operator '*' used
    ////////////////////////////////////////////////////

    // div
    wire [31:0] quotient, remainder;

    wire [32:0] uDivA = {1'b0, srca};
    wire [32:0] uDivB = {1'b0, srcb};

    /////////////// REPLACE IF SYNTHESIS ///////////////
    wire [31:0] uquo = uDivA / uDivB;   // operator '/' used
    wire [31:0] urem = uDivA % uDivB;   // operator '%' used

    wire [31:0] squo = $signed($signed(srca) / $signed(srcb));
    wire [31:0] srem = $signed($signed(srca) % $signed(srcb));
    ////////////////////////////////////////////////////

    assign {quotient, remainder} = (sign) ? ({squo, srem}) : ({uquo, urem});

    /* Part 2. Simulate the delay */
    reg [6:0] delayCount;

    assign busy = (delayCount > 0) || (isStart);

    /* Part 3. State Transfer */
    always @ (posedge clk) begin
        if (reset) begin
            {hi, lo}        <= 0;
            delayCount      <= 0;
            {A, B}          <= 0;
            instr_reg       <= 0;
        end
        else begin
            if (delayCount == 1) begin
                // Will done
                delayCount <= 0;
                if (instr_reg == `MULT || instr_reg == `MULTU) begin
                    {hi, lo} <= product;
                end
                else if (instr_reg == `DIV || instr_reg == `DIVU) begin
                    hi <= remainder;
                    lo <= quotient;
                end
                else if (instr_reg == `MADD || instr_reg == `MADDU) begin
                    {hi, lo} <= {hi, lo} + product;
                end
                else if (instr_reg == `MSUB || instr_reg == `MSUBU) begin
                    {hi, lo} <= {hi, lo} - product;
                end
            end
            else if (delayCount > 0) begin
                delayCount <= delayCount - 1;
            end
            else if (isStart) begin
                instr_reg <= instr;
                A <= srca;
                B <= srcb;
                if (instr == `DIV || instr == `DIVU) begin
                    delayCount <= DIV_DELAY;
                end
                else begin  // multiply
                    delayCount <= MULT_DELAY;
                end
            end
            else if (instr == `MTHI) begin
                hi <= srca; // rs
            end
            else if (instr == `MTLO) begin
                lo <= srca; // rs
            end
        end
    end
endmodule

module StageE (
    input wire                      clk,
    input wire                      reset,
    /* From previous stage */
    input wire `TYPE_INSTR          instr_E         ,
    input wire `TYPE_IFUNC          ifunc_E         ,
    input wire `WORD                PC_E            ,
    input wire                      BD_E            ,
    input wire `TYPE_EXC            exc_E           ,
    input wire `TYPE_REG            addrRs_E        ,
    input wire `TYPE_REG            addrRt_E        ,
    input wire `TYPE_REG            addrRd_E        ,
    input wire                      useRs_E         ,
    input wire                      useRt_E         ,
    input wire `WORD                dataRs_E        ,
    input wire `WORD                dataRt_E        ,
    input wire `WORD                extImm_E        ,
    input wire `WORD                extShamt_E      ,
    input wire                      regWEn_E        ,
    input wire `TYPE_REG            regWAddr_E      ,
    input wire `WORD                regWData_E      ,
    input wire                      regWValid_E     ,
    input wire `TYPE_T              Tnew_E          ,
    /* To next stage */
    // Instruction
    output reg `TYPE_INSTR          instr_M         = 0,
    output reg `TYPE_IFUNC          ifunc_M         = 0,
    output reg `WORD                PC_M            = 0,
    output reg                      BD_M            = 0,
    output reg `TYPE_EXC            exc_M           = 0,
    // Reg use
    output reg                      useRt_M         = 0,
    output reg `TYPE_REG            addrRt_M        = 0,
    output reg `WORD                dataRt_M        = 0,
    output reg `TYPE_REG            addrRd_M        = 0,
    // Data
    output reg `WORD                aluOut_M        = 0,
    // Reg Write
    output reg                      regWEn_M        = 0,
    output reg `TYPE_REG            regWAddr_M      = 0,
    output reg `WORD                regWData_M      = 0,
    output reg                      regWValid_M     = 0,
    output reg `TYPE_T              Tnew_M          = 0,
    /* Bypass (from W) */
    input wire                      regWEn_W,
    input wire `TYPE_REG            regWAddr_W,
    input wire `WORD                regWData_W,
    input wire                      regWValid_W,
    /* Interface with Pipeline Controller */
    input wire                      stall,
    input wire                      clear,
    input wire                      enMD,
    output wire                     busyMD
);

    /* ------ Wires Declaration ------ */
    // instruction
    wire `TYPE_INSTR instr;
    wire `TYPE_IFUNC ifunc;
    // exception
    wire `TYPE_EXC exc;
    // bypass
    wire `WORD dataRs_use, dataRt_use;
    // alu source
    wire `WORD srca, srcb;
    // module output
    wire `WORD aluOut;
    wire `TYPE_EXC excAlu;
    wire `WORD hi, lo;
    // reg write
    wire regWEn;
    wire `TYPE_REG regWAddr;
    wire `WORD regWData;
    wire regWValid;
    wire `TYPE_T Tnew;
    
    /* ------ Instantiate Modules ------ */
    ALU alu (
        .instr(instr), .ifunc(ifunc),
        .srca(srca), .srcb(srcb),
        .out(aluOut), .exc(excAlu)
    );

    MDU mdu (
        .clk(clk), .reset(reset),
        .instr(instr), .ifunc(ifunc), .en(enMD),
        .srca(srca), .srcb(srcb),
        .hi(hi), .lo(lo),
        .busy(busyMD)
    );

    /* ------ Combinatinal Logic ------ */
    // instruction
    assign instr = instr_E;
    assign ifunc = ifunc_E;
    assign Tnew = (Tnew_E >= 1) ? (Tnew_E - 1) : 0;
    assign exc = (exc_E) ? (exc_E) : (excAlu);
    // bypass select
    assign dataRs_use = (regWEn_M & (regWAddr_M != 0) & (regWAddr_M == addrRs_E)) ? (regWData_M) :
                        (regWEn_W & (regWAddr_W != 0) & (regWAddr_W == addrRs_E)) ? (regWData_W) :
                        (dataRs_E);
    
    assign dataRt_use = (regWEn_M & (regWAddr_M != 0) & (regWAddr_M == addrRt_E)) ? (regWData_M) :
                        (regWEn_W & (regWAddr_W != 0) & (regWAddr_W == addrRt_E)) ? (regWData_W) :
                        (dataRt_E); 

    // alu source select
    assign srca = ((instr == `SLL) || (instr == `SRL) || (instr == `SRA)) ? (extShamt_E) : (dataRs_use);
    assign srcb = ((ifunc == `I_ALU_I) || (ifunc == `I_MEM_R) || (ifunc == `I_MEM_W)) ? (extImm_E) : (dataRt_use);

    // reg write
    assign regWEn = regWEn_E;
    assign regWAddr = regWAddr_E;
    assign regWData =   (instr == `MFHI) ? (hi) :
                        (instr == `MFLO) ? (lo) :
                        ((ifunc == `I_ALU_R) || (ifunc == `I_ALU_I)) ? (aluOut) :
                        regWData_E;
    assign regWValid = (regWValid_E) || ((instr == `MFHI) || (instr == `MFLO) || (ifunc == `I_ALU_R) || (ifunc == `I_ALU_I));

    /* ------ Pipeline Registers ------ */
    always @ (posedge clk) begin
        if (reset) begin
            instr_M         <=  0;
            ifunc_M         <=  0;
            PC_M            <=  0;
            BD_M            <=  0;
            exc_M           <=  0;
            useRt_M         <=  0;
            addrRt_M        <=  0;
            dataRt_M        <=  0;
            addrRd_M        <=  0;
            aluOut_M        <=  0;
            regWEn_M        <=  0;
            regWAddr_M      <=  0;
            regWData_M      <=  0;
            regWValid_M     <=  0;
            Tnew_M          <=  0;
        end
        else begin
            if (clear & (~stall)) begin
                instr_M         <=  0;
                ifunc_M         <=  0;
                PC_M            <=  0;
                BD_M            <=  0;
                exc_M           <=  0;
                useRt_M         <=  0;
                addrRt_M        <=  0;
                dataRt_M        <=  0;
                addrRd_M        <=  0;
                aluOut_M        <=  0;
                regWEn_M        <=  0;
                regWAddr_M      <=  0;
                regWData_M      <=  0;
                regWValid_M     <=  0;
                Tnew_M          <=  0;
            end
            else if (~stall) begin
                instr_M         <=  instr;
                ifunc_M         <=  ifunc;
                PC_M            <=  PC_E;
                BD_M            <=  BD_E;
                exc_M           <=  exc;
                useRt_M         <=  useRt_E;
                addrRt_M        <=  addrRt_E;
                dataRt_M        <=  dataRt_use;
                addrRd_M        <=  addrRd_E;
                aluOut_M        <=  aluOut;
                regWEn_M        <=  regWEn;
                regWAddr_M      <=  regWAddr;
                regWData_M      <=  regWData;
                regWValid_M     <=  regWValid;
                Tnew_M          <=  Tnew;
            end
        end
    end

endmodule
