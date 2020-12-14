module MULTDIV (
    /* Input */
    // Time Sequential
    input wire clk, 
    input wire reset, 
    // Control
    input wire [`WIDTH_INSTR-1:0] instr,
    // Data
    input wire [31:0] dataRs, 
    input wire [31:0] dataRt, 
    // output
    output wire busy, 
    output wire [31:0] out
);
parameter WIDTH_OP  = 2,
            Nop     = 0,
            Op_Mult = 1,
            Op_Div  = 2;
parameter   EXT_ZERO = 0,
            EXT_SIGN = 1;

    reg [31:0] HI = 0, LO = 0;
    reg [3:0] delayCounter = 0;
    reg [WIDTH_OP-1:0] currOp;
    
    assign busy = (delayCounter > 0) || 
                    ((delayCounter == 0) && (
                        (instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU) || 
                        (instr == `MADD) || (instr == `MADDU) || (instr == `MSUB) || (instr == `MSUBU)
                    ));

    wire extOp;
    assign extOp = ((instr == `MULTU) || (instr == `DIVU) || (instr == `MADDU) || (instr == `MSUBU)) ? EXT_ZERO : EXT_SIGN;
    wire [63:0] extRs, extRt;
    assign extRs = (extOp == EXT_ZERO) ? {32'b0, dataRs} : {{32{dataRs[31]}}, dataRs};
    assign extRt = (extOp == EXT_ZERO) ? {32'b0, dataRt} : {{32{dataRt[31]}}, dataRt};
    wire [32:0] divuRs, divuRt;
    assign divuRs = {1'b0, dataRs};
    assign divuRt = {1'b0, dataRt};

    assign out = (busy) ? 0 : (
        (instr == `MFHI) ? (HI) : 
        (instr == `MFLO) ? (LO) : 
        0
    );

    wire [63:0] product;
    assign product = extRs * extRt;

    wire [31:0] quo_s, rem_s;   // signed div
    wire [31:0] quo_u, rem_u;   // unsigned div
    assign quo_s = $signed(dataRs) / $signed(dataRt);
    assign rem_s = $signed(dataRs) % $signed(dataRt);
    assign quo_u = divuRs / divuRt;
    assign rem_u = divuRs % divuRt;

    wire [31:0] quotient, remainder;
    assign quotient = (extOp == EXT_ZERO) ? quo_u : quo_s;
    assign remainder = (extOp == EXT_ZERO) ? rem_u : rem_s;
    
    
    always @(posedge clk) begin
        if (reset) begin
            HI <= 0;
            LO <= 0;
            delayCounter <= 0;
            currOp <= Nop;
        end
        else begin
            if (delayCounter != 0) begin
                if (delayCounter == 1) 
                    currOp <= Nop;
                delayCounter <= delayCounter - 1;
            end
            else begin
                if (instr == `MULT || instr == `MULTU) begin
                    delayCounter <= 5;
                    HI <= product[63:32];
                    LO <= product[31:0];
                    currOp <= Op_Mult;
                end
                else if (instr == `DIV || instr == `DIVU) begin
                    delayCounter <= 10;
                    HI <= remainder;
                    LO <= quotient;
                    currOp <= Op_Div;
                end
                else if (instr == `MADD || instr == `MADDU) begin
                    delayCounter <= 5;
                    {HI, LO} <= {HI, LO} + product;
                    currOp <= Op_Mult;
                end
                else if (instr == `MSUB || instr == `MSUBU) begin
                    delayCounter <= 5;
                    {HI, LO} <= {HI, LO} - product;
                    currOp <= Op_Mult;
                end
                else if (instr == `MTHI) begin
                    HI <= dataRs;
                end
                else if (instr == `MTLO) begin
                    LO <= dataRs;
                end
            end
        end
    end
endmodule
