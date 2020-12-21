
`default_nettype none
`include "instructions.v"
`include "exception.v"

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
            // 6'b001010: Rformat = `MOVZ      ;
            // 6'b001011: Rformat = `MOVN      ;
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
                // 5'b10000: SpecialI = `BLTZAL;
                // 5'b10001: SpecialI = `BGEZAL;
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
                // 6'b100001: SpecialV2 = `CLO;
                // 6'b100000: SpecialV2 = `CLZ;
                // 6'b000000: SpecialV2 = `MADD;
                // 6'b000001: SpecialV2 = `MADDU;
                // 6'b000100: SpecialV2 = `MSUB;
                // 6'b000101: SpecialV2 = `MSUBU;
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
    wire [`WIDTH_INSTR-1:0] sp_r, sp_i, sp_v2, sp_cop0;
    assign sp_r = SpecialR(rs, rt, rd, shamt, funct);
    assign sp_i = SpecialI(opcode, rs, rt);
    assign sp_v2 = SpecialV2(opcode, funct);
    assign sp_cop0 = SpecialCOP0(opcode, rs, funct);
    // link these sub-signals
    assign instr = (code == 32'h0000_0000) ? (`NOP) : 
    (sp_v2 != `NOP) ? (sp_v2) : // clo and clz
    (sp_cop0 != `NOP) ? (sp_cop0) : // cp0
    (opcode == 6'b000000) ? (
        // R format
        (sp_r != `NOP) ? (sp_r) : (r)
    ) : (
        // IJ format
        (sp_i != `NOP) ? (sp_i) : (ij)
    );

    assign excRI = (code != 32'h0000_0000 && instr == `NOP);

endmodule

module COMP (
    /* Input */
    input wire [`WIDTH_INSTR-1:0] instr,
    input wire [31:0] dataRs,
    input wire [31:0] dataRt,
    output wire cmp
);

    function compare;
        input [31:0] rs;
        input [31:0] rt;
        input [`WIDTH_INSTR-1:0] instr;
        begin
            case (instr) 
            `BEQ:   compare = (rs == rt);
            `BNE:   compare = (rs != rt);
            `BGEZ:  compare = (rs[31] == 0);
            `BGTZ:  compare = (rs[31] == 0) && (rs != 0);
            `BLEZ:  compare = (rs[31] == 1) || (rs == 0);
            `BLTZ:  compare = (rs[31] == 1);
            `BGEZAL: compare = (rs[31] == 0);
            `BLTZAL: compare = (rs[31] == 1);
            `MOVZ:  compare = (rt == 0);
            `MOVN:  compare = (rt != 0);
            default: compare = 0;
            endcase
        end
    endfunction

    assign cmp = compare(dataRs, dataRt, instr);
    
endmodule

/* ------ Instruction Decode and Register Read ------ */
module ID_TOP (
    /* Global Inputs */
    // Time Sequence
    input wire                      clk, 
    input wire                      rst_n, 
    // Pipeline Registers
    input wire                      stall, 
    input wire                      clr, 
    /* Data Inputs from Previous Pipeline */
    input wire [31:0]               code_ID, // Machine Code from IM@IF
    input wire [31:0]               PC_ID,   // PC from PC@IF
    input wire [6:2]                Exc_ID,  // Exc from PC@IF
    input wire                      BD_ID,   // Branching Delay Flag from IF
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
    output reg [6:2]                Exc_EX              = 0,
    output reg                      BD_EX               = 0,
    // Decoder
    output reg [31:0]               dataRs_EX           = 0, // Need Forward
    output reg [31:0]               dataRt_EX           = 0, // Need Forward
    output reg [15:0]               imm16_EX            = 0, 
    output reg [4:0]                shamt_EX            = 0, 
    // RegUsed
    output reg [4:0]                addrRs_EX           = 0,
    output reg [4:0]                addrRt_EX           = 0,
    output reg [4:0]                addrRd_EX           = 0,
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
        .excRI(excRI)
    );
    COMP comp (
        .instr(instr),
        .dataRs(dataRs_use), .dataRt(dataRt_use),
        .cmp(cmp)
    );
    assign luiExtImm = {imm16, 16'b0};

    assign Exc = (Exc_ID) ? Exc_ID : (excRI ? (`EXC_RI) : 0);

    /* ------ Part 2.5 Part of Controls ------ */
    // instantiate ic module
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign regWriteAddr =   (instr == `BGEZAL || instr == `BLTZAL) ? (cmp ? 31 : 0) : // conditionally link according to MARS, but directly link according to MIPS-V2.
                            (instr == `MOVZ || instr == `MOVN) ? (cmp ? addrRd : 0) : 
                            (instr == `JAL)                  ? 31 :       // JAL
                            ((func == `FUNC_CALC_R) || (instr == `JALR) || (instr == `MFHI) || (instr == `MFLO)) ? addrRd :  // rd
                            ((func == `FUNC_CALC_I) || (func == `FUNC_MEM_READ) || (instr == `MFC0))  ? addrRt :  // rt
                            0;
                            
    assign regWriteData =   (instr == `MOVZ || instr == `MOVN) ? (cmp ? dataRs_use : 0) : 
                            ((instr == `JAL) || (instr == `JALR) || (instr == `BGEZAL) || (instr == `BLTZAL))     ?   PC_ID + 8   :   // Jump Link
                            ((instr == `LUI))                       ?   luiExtImm   :   // LUI(I-instr which don't need data from grf to alu)
                            0; // Default
    /* ------ Part 3: Pipeline Registers ------ */
    always @ (posedge clk or negedge rst_n) begin
        if ((!rst_n) | clr) begin
            instr_EX            <= 0;
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
