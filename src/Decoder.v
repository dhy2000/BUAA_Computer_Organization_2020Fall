/*
 *  File Name:  Decoder.v
 *  Module:     Decoder
 *  Inputs: A 32-bit Machine Code of a MIPS instruction
 *  Outputs: Segments of the binary code, and a symbol label of current instruction.
 *  Description: Split the 32-bit instruction into several segments such as rs, rt, rd(R), shamt(R); 16-bit immediate(I), 26-bit address(J), and get the symbol of the instruction by determine the opcode/funct.
 */
`default_nettype none
`include "instructions.v"

module Decoder (
    /* Input */
    input wire [31:0] code,
    /* Output */
    // Instruction Symbol
    output wire [`WIDTH_INSTR-1:0] instr,
    // Operands
    output wire [4:0] rs,
    output wire [4:0] rt,
    output wire [4:0] rd,
    output wire [4:0] shamt,
    output wire [15:0] imm,
    output wire [25:0] jmpaddr
);
    /* Part 1: Split the machine code */
    wire [5:0] opcode, funct; // [31:26] and [5:0]
    
    assign opcode = code[31:26];
    assign rs = code[25:21];
    assign rt = code[20:16];
    assign rd = code[15:11];
    assign shamt = code[10:6];
    assign funct = code[5:0];

    /* Part 2: Determine the symbol of instruction */
    // R type, check [funct]
    function [`WIDTH_INSTR-1:0] Rformat;
        input [5:0] funct;
        begin
            case (funct)
            6'b100000: Rformat = `ADD       ;
            6'b100010: Rformat = `SUB       ;
            6'b100001: Rformat = `ADDU      ;
            6'b100011: Rformat = `SUBU      ;
            6'b100100: Rformat = `AND       ;
            6'b100101: Rformat = `OR        ;
            6'b100110: Rformat = `XOR       ;
            6'b100111: Rformat = `NOR       ;
            6'b101010: Rformat = `SLT       ;
            6'b101011: Rformat = `SLTU      ;
            6'b000000: Rformat = `SLL       ;
            6'b000100: Rformat = `SLLV      ;
            6'b000010: Rformat = `SRL       ;
            6'b000110: Rformat = `SRLV      ;
            6'b000011: Rformat = `SRA       ;
            6'b000111: Rformat = `SRAV      ;
            // jalr and jr
            6'b001001: Rformat = `JALR      ;
            6'b001000: Rformat = `JR        ;
            default: Rformat = `NOP         ;
            endcase
        end
    endfunction
    // I or J type, check opcode
    function [`WIDTH_INSTR-1:0] IJformat;
        input [5:0] opcode;
        begin
            case (opcode)
            // calc_i
            6'b001000: IJformat = `ADDI   ;
            6'b001001: IJformat = `ADDIU  ;
            6'b001100: IJformat = `ANDI   ;
            6'b001101: IJformat = `ORI    ;
            6'b001110: IJformat = `XORI   ;
            6'b001111: IJformat = `LUI    ;
            6'b001010: IJformat = `SLTI   ;
            6'b001011: IJformat = `SLTIU  ;
            // memload
            6'b100011: IJformat = `LW     ;
            6'b100001: IJformat = `LH     ;
            6'b100101: IJformat = `LHU    ;
            6'b100000: IJformat = `LB     ;
            6'b100100: IJformat = `LBU    ;
            // memstore
            6'b101011: IJformat = `SW     ;
            6'b101001: IJformat = `SH     ;
            6'b101000: IJformat = `SB     ;
            // branch
            6'b000100: IJformat = `BEQ    ;
            6'b000101: IJformat = `BNE    ;
            6'b000110: IJformat = `BLEZ   ;
            6'b000111: IJformat = `BGTZ   ;
            // jump
            6'b000010: IJformat = `J      ;
            6'b000011: IJformat = `JAL    ;
            default: IJformat = `NOP  ;
            endcase
        end
    endfunction
    // Special Encode R-Instruction
    function [`WIDTH_INSTR-1:0] SpecialR;
        input [4:0] rs;
        input [4:0] rt;
        input [4:0] rd;
        input [4:0] shamt;
        input [5:0] funct;
        begin
            // TODO: For On-Course Expansion
            SpecialR = `NOP;
        end
    endfunction
    // Special Encode I-Instruction
    // bgez and bltz
    function [`WIDTH_INSTR-1:0] SpecialI;
        input [5:0] opcode;
        input [4:0] rs;
        input [4:0] rt;
        begin
            if (opcode == 6'b000001) begin
                if (rt == 5'b00001) 
                    SpecialI = `BGEZ;
                else if (rt == 5'b00000)
                    SpecialI = `BLTZ;
                else begin
                    // TODO: For On-Course Expansion
                    SpecialI = `NOP;
                end
            end
            else begin
                // TODO: For On-Course Expansion
                SpecialI = `NOP;
            end
        end
    endfunction

    // Determine the Instruction
    wire [`WIDTH_INSTR-1:0] r, ij;
    assign r = Rformat(funct);
    assign ij = IJformat(opcode);
    wire [`WIDTH_INSTR-1:0] sp_r, sp_i;
    assign sp_r = SpecialR(rs, rt, rd, shamt, funct);
    assign sp_i = SpecialI(opcode, rs, rt);
    // link these sub-signals
    assign instr = (opcode == 6'b000000) ? (
        // R format
        (sp_r != `NOP) ? (sp_r) : (r)
    ) : (
        // IJ format
        (sp_i != `NOP) ? (sp_i) : (ij)
    );

endmodule
