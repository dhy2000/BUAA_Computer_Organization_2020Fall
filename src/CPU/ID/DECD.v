`default_nettype none
`include "../instructions.v"
`include "../IC.v"

module DECD (
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
    output wire [25:0] jmpaddr,
    // Exception Flag
    output wire excRI // exception - RI(unRecognized Instruction)
);
    /* Part 1: Split the machine code */
    wire [5:0] opcode, funct; // [31:26] and [5:0]
    
    assign opcode = code[31:26];
    assign rs = code[25:21];
    assign rt = code[20:16];
    assign rd = code[15:11];
    assign shamt = code[10:6];
    assign funct = code[5:0];
    assign imm = code[15:0];
    assign jmpaddr = code[25:0];

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
            // multdiv
            6'b011000: Rformat = `MULT      ;
            6'b011001: Rformat = `MULTU     ;
            6'b011010: Rformat = `DIV       ;
            6'b011011: Rformat = `DIVU      ;
            6'b010000: Rformat = `MFHI      ;
            6'b010010: Rformat = `MFLO      ;
            6'b010001: Rformat = `MTHI      ;
            6'b010011: Rformat = `MTLO      ;
            // duliu
            6'b001010: Rformat = `MOVZ      ;
            6'b001011: Rformat = `MOVN      ;
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
                case (rt) 
                5'b00001: SpecialI = `BGEZ;
                5'b00000: SpecialI = `BLTZ;
                5'b10000: SpecialI = `BLTZAL;
                5'b10001: SpecialI = `BGEZAL;
                default:  SpecialI = `NOP;
                endcase
            end
            else begin
                // TODO: For On-Course Expansion
                SpecialI = `NOP;
            end
        end
    endfunction

    function [`WIDTH_INSTR-1:0] SpecialV2; // clo, clz
        input [5:0] opcode;
        input [5:0] funct;
        begin
            if (opcode == 6'b011100) begin
                case (funct)
                6'b100001: SpecialV2 = `CLO;
                6'b100000: SpecialV2 = `CLZ;
                6'b000000: SpecialV2 = `MADD;
                6'b000001: SpecialV2 = `MADDU;
                6'b000100: SpecialV2 = `MSUB;
                6'b000101: SpecialV2 = `MSUBU;
                default:   SpecialV2 = `NOP;
                endcase
            end
            else 
                SpecialV2 = `NOP;
        end
    endfunction

    function [`WIDTH_INSTR-1:0] SpecialCOP0;
        input [5:0] opcode;
        input [4:0] rs;
        input [5:0] funct;
        begin
            if (opcode == 6'b010000) begin
                case (rs)
                5'b00000: SpecialCOP0 = `MFC0;
                5'b00100: SpecialCOP0 = `MTC0;
                default: begin
                    if (funct == 6'b011000)
                        SpecialCOP0 = `ERET;
                    else
                        SpecialCOP0 = `NOP;
                end
                endcase
            end
            else 
                SpecialCOP0 = `NOP;
        end
    endfunction

    // Determine the Instruction
    wire [`WIDTH_INSTR-1:0] r, ij;
    assign r = Rformat(funct);
    assign ij = IJformat(opcode);
    wire [`WIDTH_INSTR-1:0] sp_r, sp_i, sp_v2;
    assign sp_r = SpecialR(rs, rt, rd, shamt, funct);
    assign sp_i = SpecialI(opcode, rs, rt);
    assign sp_v2 = SpecialV2(opcode, funct);
    // link these sub-signals
    assign instr = (code == 32'h0000_0000) ? (`NOP) : 
    (sp_v2 != `NOP) ? (sp_v2) : // clo and clz
    (opcode == 6'b000000) ? (
        // R format
        (sp_r != `NOP) ? (sp_r) : (r)
    ) : (
        // IJ format
        (sp_i != `NOP) ? (sp_i) : (ij)
    );

    assign excRI = (code != 32'h0000_0000 && instr == `NOP);

endmodule