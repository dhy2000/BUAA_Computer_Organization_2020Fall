/* 
 *  Overview: Pipeline Stage D (Decode)
 */

`default_nettype none
`include "include/instructions.v"
`include "include/exception.v"
`include "include/memory.v"

/*
 *  Overview: Instruction decoder
 *  Input: machine code of an instruction
 *  Output: 
 *      - Operand fields
 *      - Instruction Symbol
 *      - RI Exception
 *      - Instruction Function Group
 */
module Decoder (
    input wire `WORD            code,
    // Operands
    output wire `TYPE_REG       rs,
    output wire `TYPE_REG       rt,
    output wire `TYPE_REG       rd,
    output wire `TYPE_SHAMT     shamt,
    output wire `TYPE_IMM       imm,
    output wire `TYPE_JADDR     jmpaddr,
    // Symbol and Function
    output wire `TYPE_INSTR     instr,
    output wire `TYPE_IFUNC     ifunc,
    // Exception Flag - RI(Reserved Instruction)
    output wire excRI
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
    function `TYPE_INSTR Rformat;
        input [5:0] funct;
        begin
            case (funct)
            // alu_r
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
            // mult div
            6'b011000: Rformat = `MULT      ;
            6'b011001: Rformat = `MULTU     ;
            6'b011010: Rformat = `DIV       ;
            6'b011011: Rformat = `DIVU      ;
            6'b010000: Rformat = `MFHI      ;
            6'b010010: Rformat = `MFLO      ;
            6'b010001: Rformat = `MTHI      ;
            6'b010011: Rformat = `MTLO      ;
            // conditional move
            6'b001010: Rformat = `MOVZ      ;
            6'b001011: Rformat = `MOVN      ;
            default: Rformat = `NOP         ;
            endcase
        end
    endfunction

    // I or J type, check opcode
    function `TYPE_INSTR IJformat;
        input [5:0] opcode;
        begin
            case (opcode)
            // alu_i
            6'b001000: IJformat = `ADDI   ;
            6'b001001: IJformat = `ADDIU  ;
            6'b001100: IJformat = `ANDI   ;
            6'b001101: IJformat = `ORI    ;
            6'b001110: IJformat = `XORI   ;
            6'b001111: IJformat = `LUI    ;
            6'b001010: IJformat = `SLTI   ;
            6'b001011: IJformat = `SLTIU  ;
            // mem_r
            6'b100011: IJformat = `LW     ;
            6'b100001: IJformat = `LH     ;
            6'b100101: IJformat = `LHU    ;
            6'b100000: IJformat = `LB     ;
            6'b100100: IJformat = `LBU    ;
            // mem_w
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

    // Special R-Instruction
    function `TYPE_INSTR SpecialR;
        input [5:0] opcode;
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

    // Special I-Instruction
    // bgez and bltz
    function `TYPE_INSTR SpecialI;
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

    function `TYPE_INSTR SpecialV2; // clo, clz
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

    function `TYPE_INSTR SpecialCOP0;
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

    // function results
    wire `TYPE_INSTR r, ij;
    assign r = Rformat(funct);
    assign ij = IJformat(opcode);
    wire `TYPE_INSTR sp_r, sp_i, sp_v2, sp_cop0;
    assign sp_r = SpecialR(opcode, rs, rt, rd, shamt, funct);
    assign sp_i = SpecialI(opcode, rs, rt);
    assign sp_v2 = SpecialV2(opcode, funct);
    assign sp_cop0 = SpecialCOP0(opcode, rs, funct);

    // generate instr symbol code
    assign instr =  (code == 32'h0000_0000) ? (`NOP)    : 
                    (sp_v2 != `NOP)         ? (sp_v2)   :
                    (sp_cop0 != `NOP)       ? (sp_cop0) :
                    (opcode == 6'b000000)   ? (r)       :
                    (sp_r != `NOP)          ? (sp_r)    :
                    (sp_i != `NOP)          ? (sp_i)    :
                    (ij);

    /* Part 3: Check RI Exception */
    assign excRI = (code != 32'h0000_0000 && instr == `NOP);
    
    /* Part 4: Categorize instructions by function group */
    wire alu_r, alu_i, mem_r, mem_w, br, jmp, md, cp0;
    assign alu_r = (
        (instr == `NOP ) || 
        (instr == `ADD ) || (instr == `SUB ) || (instr == `ADDU) || (instr == `SUBU) || 
        (instr == `AND ) || (instr == `OR  ) || (instr == `XOR ) || (instr == `NOR ) || 
        (instr == `SLT ) || (instr == `SLTU) || (instr == `SLL ) || (instr == `SRL ) || 
        (instr == `SRA ) || (instr == `SLLV) || (instr == `SRLV) || (instr == `SRAV) ||
        (instr == `CLO) || (instr == `CLZ)
    );
    assign alu_i = (
        (instr == `ADDI ) || (instr == `ADDIU) || (instr == `ANDI ) || (instr == `ORI  ) || 
        (instr == `XORI ) || (instr == `LUI  ) || (instr == `SLTI ) || (instr == `SLTIU) 
    );
    assign mem_r = (
        (instr == `LW ) || (instr == `LH ) || (instr == `LHU) || (instr == `LB ) || (instr == `LBU)
    );
    assign mem_w = (
        (instr == `SW) || (instr == `SH) || (instr == `SB) 
    );
    assign br = (
        (instr == `BEQ ) || (instr == `BNE ) || (instr == `BGEZ) || (instr == `BGTZ) || (instr == `BLEZ) || (instr == `BLTZ) ||
        (instr == `BGEZAL) || (instr == `BLTZAL)
    );
    assign jmp = (
        (instr == `J   ) || (instr == `JAL ) || (instr == `JALR) || (instr == `JR  ) 
    );
    assign md = (
        (instr == `MULT) || (instr == `MULTU) || (instr == `DIV) || (instr == `DIVU) ||
        (instr == `MFHI) || (instr == `MFLO ) || (instr == `MTHI)|| (instr == `MTLO) ||
        (instr == `MADD) || (instr == `MADDU) || (instr == `MSUB) || (instr == `MSUBU)
    );
    assign cp0 = (
        (instr == `MFC0 || instr == `MTC0 || instr == `ERET)
    );

    assign ifunc =  (alu_r) ? (`I_ALU_R) : 
                    (alu_i) ? (`I_ALU_I) : 
                    (mem_r) ? (`I_MEM_R) : 
                    (mem_w) ? (`I_MEM_W) : 
                    (br) ? (`I_BRANCH) : 
                    (jmp) ? (`I_JUMP) : 
                    (md) ? (`I_MD) : 
                    (cp0) ? (`I_CP0) : 
                    (`I_OTHER) ;

endmodule

/*
 *  Overview: Comparator for branch
 */
module Compare (
    input wire `TYPE_INSTR instr,
    input wire `WORD dataRs,
    input wire `WORD dataRt,
    output wire cmp
);

    function compare;
        input [31:0] rs;
        input [31:0] rt;
        input `TYPE_INSTR instr;
        begin
            case (instr) 
            `BEQ    : compare = (rs == rt);
            `BNE    : compare = (rs != rt);
            `BGEZ   : compare = (rs[31] == 0);
            `BGTZ   : compare = (rs[31] == 0) && (rs != 0);
            `BLEZ   : compare = (rs[31] == 1) || (rs == 0);
            `BLTZ   : compare = (rs[31] == 1);
            `BGEZAL : compare = (rs[31] == 0);
            `BLTZAL : compare = (rs[31] == 1);
            `MOVZ   : compare = (rt == 0);
            `MOVN   : compare = (rt != 0);
            default : compare = 0;
            endcase
        end
    endfunction

    assign cmp = compare(dataRs, dataRt, instr);
    
endmodule


module StageD (
    input wire                      clk, 
    input wire                      reset,
    /* From previous stage */
    input wire `WORD                code_D,
    input wire `WORD                PC_D,
    input wire                      BD_D,
    input wire `TYPE_EXC            exc_D,
    /* To next stage */
    // Instruction
    output reg `TYPE_INSTR          instr_E         = 0,
    output reg `TYPE_IFUNC          ifunc_E         = 0,
    output reg `WORD                PC_E            = 0,
    output reg                      BD_E            = 0,
    output reg `TYPE_EXC            exc_E           = 0,
    // Reg Use
    output reg `TYPE_REG            addrRs_E        = 0,
    output reg `TYPE_REG            addrRt_E        = 0,
    output reg                      useRs_E         = 0,
    output reg                      useRt_E         = 0,
    output reg `WORD                dataRs_E        = 0,
    output reg `WORD                dataRt_E        = 0,
    // Immediate Data
    output reg `WORD                extImm_E        = 0,
    output reg `WORD                extShamt_E      = 0,
    // Reg Write
    output reg                      regWEn_E        = 0,
    output reg `TYPE_REG            regWAddr_E      = 0,
    output reg `WORD                regWData_E      = 0,
    output reg                      regWValid_E     = 0,
    output reg `TYPE_T              Tnew_E          = 0,
    /* Data Bypass (from M) */
    input wire                      regWEn_M,
    input wire `TYPE_REG            regWAddr_M,
    input wire `WORD                regWData_M,
    input wire                      regWValid_M,
    /* Status of current stage */
    output wire `TYPE_INSTR         instr_D,
    output wire `TYPE_IFUNC         ifunc_D,
    output wire                     useRs_D,
    output wire                     useRt_D,
    output wire `TYPE_REG           addrRs_D,
    output wire `TYPE_REG           addrRt_D,
    output wire `TYPE_REG           addrRd_D,
    output wire                     cmp_D,
    output wire `TYPE_IMM           imm_D,
    output wire `TYPE_SHAMT         shamt_D,
    output wire `TYPE_JADDR         jmpAddr_D,
    output wire `WORD               jmpReg_D,
    /* Interface with Pipeline Controller */
    input wire                      stall,
    input wire                      clear,
    /* GRF Data Read */
    input wire `WORD                dataRs_D,
    input wire `WORD                dataRt_D
);

    /* ------ Wires Declaration ------ */
    wire excRI;
    wire `TYPE_EXC excNext;
    wire `WORD dataRs_use, dataRt_use;

    /* ------ Instantiate Modules ------ */

    Decoder instr_decoder (
        .code(code_D),
        .rs(addrRs_D),
        .rt(addrRt_D),
        .rd(addrRd_D),
        .shamt(shamt_D),
        .imm(imm_D),
        .jmpaddr(jmpAddr_D),
        .instr(instr_D),
        .ifunc(ifunc_D),
        .excRI(excRI)
    );

    Compare branch_compare (
        .instr(instr_D),
        .dataRs(dataRs_D),
        .dataRt(dataRt_D),
        .cmp(cmp_D)
    );

    /* ------ Controls ------ */

    // Data Bypassing Select
    assign dataRs_use = (
        (regWEn_E & (regWAddr_E == addrRs_D) & (regWAddr_E != 0)) ? (regWData_E) :
        (regWEn_M & (regWAddr_M == addrRs_D) & (regWAddr_M != 0)) ? (regWData_M) :
        (dataRs_D)
    );
    assign dataRt_use = (
        (regWEn_E & (regWAddr_E == addrRt_D) & (regWAddr_E != 0)) ? (regWData_E) :
        (regWEn_M & (regWAddr_M == addrRt_D) & (regWAddr_M != 0)) ? (regWData_M) :
        (dataRt_D)
    );



    /* ------ Other Logics ------ */




    /* ------ Pipeline Registers ------ */




















    /* ------ Part 1: Wires Declaration ------ */
    // decode
    wire `TYPE_INSTR instr;
    wire `TYPE_FORMAT format; 
    wire `TYPE_IFUNC ifunc;
    // fields
    wire [4:0] addrRs, addrRt, addrRd;
    wire [15:0] imm16; 
    wire [4:0] shamt;
    wire [25:0] jmpAddr;
    // other
    wire excRI;
    wire cmp;
    wire [31:0] luiExtImm;
    // Hazard may use
    wire [4:0] regWriteAddr;
    wire [31:0] regWriteData;
    // Tnew
    wire [`WIDTH_T-1:0] Tnew;
    // Exception
    wire [6:2] Exc;

    /* ------ Part 1.5: Select Forward Source ------ */
    // GRF already supports inner forward.
    wire [31:0] dataRs_use, dataRt_use;
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
        .excRI(excRI)
    );
    COMP comp (
        .instr(instr),
        .dataRs(dataRs_use), .dataRt(dataRt_use),
        .cmp(cmp)
    );

    IC ic (.instr(instr), .format(format), .ifunc(ifunc));

    assign luiExtImm = {imm16, 16'b0};

    assign Exc = (Exc_ID) ? Exc_ID : (excRI ? (`EXC_RI) : 0);

    /* ------ Part 2.5 Part of Controls ------ */

    assign regWriteAddr =   (instr == `BGEZAL || instr == `BLTZAL) ? (cmp ? 31 : 0) : // conditionally link according to MARS, but directly link according to MIPS-V2.
                            (instr == `MOVZ || instr == `MOVN) ? (cmp ? addrRd : 0) : 
                            (instr == `JAL)                  ? 31 :       // JAL
                            ((ifunc == `I_ALU_R) || (instr == `JALR) || (instr == `MFHI) || (instr == `MFLO)) ? addrRd :  // rd
                            ((ifunc == `I_ALU_I) || (ifunc == `I_MEM_R) || (instr == `MFC0))  ? addrRt :  // rt
                            0;
                            
    assign regWriteData =   (instr == `MOVZ || instr == `MOVN) ? (cmp ? dataRs_use : 0) : 
                            ((instr == `JAL) || (instr == `JALR) || (instr == `BGEZAL) || (instr == `BLTZAL))     ?   PC_ID + 8   :   // Jump Link
                            ((instr == `LUI))                       ?   luiExtImm   :   // LUI(I-instr which don't need data from grf to alu)
                            0; // Default
    /* ------ Part 3: Pipeline Registers ------ */
    always @ (posedge clk) begin
        if (reset | clr) begin
            instr_EX            <= 0;
            ifunc_EX             <= 0;
            PC_EX               <= 0;
            Exc_EX              <= 0;
            BD_EX               <= 0;
            dataRs_EX           <= 0;
            dataRt_EX           <= 0;
            imm16_EX            <= 0;
            shamt_EX            <= 0;
            addrRs_EX           <= 0;
            addrRt_EX           <= 0;
            addrRd_EX           <= 0;
            regWriteAddr_EX     <= 0;
            regWriteData_EX     <= 0;
            Tnew_EX             <= 0;
        end
        else if (!stall) begin
            instr_EX            <=  instr;
            ifunc_EX             <=  ifunc;
            PC_EX               <=  PC_ID;
            Exc_EX              <=  Exc;
            BD_EX               <=  BD_ID;
            dataRs_EX           <=  dataRs_use;
            dataRt_EX           <=  dataRt_use;
            imm16_EX            <=  imm16;
            shamt_EX            <=  shamt;
            addrRs_EX           <=  addrRs;
            addrRt_EX           <=  addrRt;
            addrRd_EX           <=  addrRd;
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
