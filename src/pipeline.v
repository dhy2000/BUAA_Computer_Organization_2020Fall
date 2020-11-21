/* 
 *  File Name: pipeline.v
 *  Modules: IF_ID, ID_EX, EX_MEM, MEM_WB
 *  Description: Pipeline Registers
 *  
 */

`default_nettype none
`include "instructions.v"

/* ------- IF/ID ------- */
module IF_ID (
    input wire clk, 
    input wire reset,
    input wire stall, 
    input wire clr,
    input wire [31:0] code_IF,
    output wire [31:0] code_ID,
    input wire [31:0] PC_IF,
    output wire [31:0] PC_ID,
    input wire [31:0] PCToLink_IF,
    output wire [31:0] PCToLink_ID
);
    reg [31:0] code = 0;
    reg [31:0] PC = 0;
    reg [31:0] PCToLink = 0;

    assign code_ID = code;
    assign PC_ID = PC;
    assign PCToLink_ID = PCToLink;

    always @ (posedge clk) begin
        if (reset | clr) begin
            code <= 0;
            PC <= 0;
            PCToLink <= 0;
        end 
        else begin
            if (!stall) begin
                code <= code_IF;
                PC <= PC_IF;
                PCToLink <= PCToLink_IF;
            end
        end
    end
endmodule


/* ------- ID/EX ------- */
module ID_EX (
    input wire clk, 
    input wire reset,
    input wire stall, 
    input wire clr,
    input wire [`WIDTH_INSTR-1:0] instr_ID,
    output wire [`WIDTH_INSTR-1:0] instr_EX,
    input wire [31:0] PC_ID,
    output wire [31:0] PC_EX,
    input wire [31:0] dataRs_ID,
    output wire [31:0] dataRs_EX,
    input wire [31:0] dataRt_ID,
    output wire [31:0] dataRt_EX,
    input wire [15:0] imm16_ID,
    output wire [15:0] imm16_EX,
    input wire [4:0] shamt_ID,
    output wire [4:0] shamt_EX,
    input wire [4:0] addrRs_ID,
    output wire [4:0] addrRs_EX,
    input wire [4:0] addrRt_ID,
    output wire [4:0] addrRt_EX,
    input wire [4:0] addrRd_ID,
    output wire [4:0] addrRd_EX,
    input wire [31:0] PCToLink_ID,
    output wire [31:0] PCToLink_EX
);
    reg [`WIDTH_INSTR-1:0] instr = 0;
    reg [31:0] PC = 0;
    reg [31:0] dataRs = 0;
    reg [31:0] dataRt = 0;
    reg [15:0] imm16 = 0;
    reg [4:0] shamt = 0;
    reg [4:0] addrRs = 0;
    reg [4:0] addrRt = 0;
    reg [4:0] addrRd = 0;
    reg [31:0] PCToLink = 0;

    assign instr_EX = instr;
    assign PC_EX = PC;
    assign dataRs_EX = dataRs;
    assign dataRt_EX = dataRt;
    assign imm16_EX = imm16;
    assign shamt_EX = shamt;
    assign addrRs_EX = addrRs;
    assign addrRt_EX = addrRt;
    assign addrRd_EX = addrRd;
    assign PCToLink_EX = PCToLink;

    always @ (posedge clk) begin
        if (reset | clr) begin
            instr <= 0;
            PC <= 0;
            dataRs <= 0;
            dataRt <= 0;
            imm16 <= 0;
            shamt <= 0;
            addrRs <= 0;
            addrRt <= 0;
            addrRd <= 0;
            PCToLink <= 0;
        end 
        else begin
            if (!stall) begin
                instr <= instr_ID;
                PC <= PC_ID;
                dataRs <= dataRs_ID;
                dataRt <= dataRt_ID;
                imm16 <= imm16_ID;
                shamt <= shamt_ID;
                addrRs <= addrRs_ID;
                addrRt <= addrRt_ID;
                addrRd <= addrRd_ID;
                PCToLink <= PCToLink_ID;
            end
        end
    end
endmodule


/* ------- EX/MEM ------- */
module EX_MEM (
    input wire clk, 
    input wire reset,
    input wire stall, 
    input wire clr,
    input wire [`WIDTH_INSTR-1:0] instr_EX,
    output wire [`WIDTH_INSTR-1:0] instr_MEM,
    input wire [31:0] PC_EX,
    output wire [31:0] PC_MEM,
    input wire [31:0] aluOut_EX,
    output wire [31:0] aluOut_MEM,
    input wire [31:0] memWriteData_EX,
    output wire [31:0] memWriteData_MEM,
    input wire [4:0] regWriteAddr_EX,
    output wire [4:0] regWriteAddr_MEM,
    input wire [31:0] PCToLink_EX,
    output wire [31:0] PCToLink_MEM
);
    reg [`WIDTH_INSTR-1:0] instr = 0;
    reg [31:0] PC = 0;
    reg [31:0] aluOut = 0;
    reg [31:0] memWriteData = 0;
    reg [4:0] regWriteAddr = 0;
    reg [31:0] PCToLink = 0;

    assign instr_MEM = instr;
    assign PC_MEM = PC;
    assign aluOut_MEM = aluOut;
    assign memWriteData_MEM = memWriteData;
    assign regWriteAddr_MEM = regWriteAddr;
    assign PCToLink_MEM = PCToLink;

    always @ (posedge clk) begin
        if (reset | clr) begin
            instr <= 0;
            PC <= 0;
            aluOut <= 0;
            memWriteData <= 0;
            regWriteAddr <= 0;
            PCToLink <= 0;
        end 
        else begin
            if (!stall) begin
                instr <= instr_EX;
                PC <= PC_EX;
                aluOut <= aluOut_EX;
                memWriteData <= memWriteData_EX;
                regWriteAddr <= regWriteAddr_EX;
                PCToLink <= PCToLink_EX;
            end
        end
    end
endmodule


/* ------- MEM/WB ------- */
module MEM_WB (
    input wire clk, 
    input wire reset,
    input wire stall, 
    input wire clr,
    input wire [31:0] PC_MEM,
    output wire [31:0] PC_WB,
    input wire [`WIDTH_INSTR-1:0] instr_MEM,
    output wire [`WIDTH_INSTR-1:0] instr_WB,
    input wire [31:0] aluOut_MEM,
    output wire [31:0] aluOut_WB,
    input wire [31:0] memReadData_MEM,
    output wire [31:0] memReadData_WB,
    input wire [31:0] PCToLink_MEM,
    output wire [31:0] PCToLink_WB,
    input wire [4:0] regWriteAddr_MEM,
    output wire [4:0] regWriteAddr_WB
);
    reg [31:0] PC = 0;
    reg [`WIDTH_INSTR-1:0] instr = 0;
    reg [31:0] aluOut = 0;
    reg [31:0] memReadData = 0;
    reg [31:0] PCToLink = 0;
    reg [4:0] regWriteAddr = 0;

    assign PC_WB = PC;
    assign instr_WB = instr;
    assign aluOut_WB = aluOut;
    assign memReadData_WB = memReadData;
    assign PCToLink_WB = PCToLink;
    assign regWriteAddr_WB = regWriteAddr;

    always @ (posedge clk) begin
        if (reset | clr) begin
            PC <= 0;
            instr <= 0;
            aluOut <= 0;
            memReadData <= 0;
            PCToLink <= 0;
            regWriteAddr <= 0;
        end 
        else begin
            if (!stall) begin
                PC <= PC_MEM;
                instr <= instr_MEM;
                aluOut <= aluOut_MEM;
                memReadData <= memReadData_MEM;
                PCToLink <= PCToLink_MEM;
                regWriteAddr <= regWriteAddr_MEM;
            end
        end
    end
endmodule


