/* --------- P4 A MIPS-32 Single-Cycle CPU --------- */

`default_nettype none

`include "instructions.v"
// `include "memconfig.v"
// Include Parts
`include "PC.v"
`include "IM.v"
`include "NPC.v"
`include "Decoder.v"
`include "GRF.v"
`include "COMP.v"
`include "ALU.v"
`include "DM.v"
`include "WB.v"

module mips (
    input wire clk, 
    input wire reset
);

    // Wires (Outputs)
    // This part declares output signals, 

    // Level1: Instruction Fetch
    wire [31:0] nextPC, PC;
    wire [31:0] InstrHex;
    wire [31:0] PCInOrder;

    // Level2: Instruction Decode And Read Register
    wire [4:0] Addr_Rs, Addr_Rt, Addr_Rd;
    wire [4:0] shamt;
    wire [15:0] Imm16;
    wire [25:0] JmpAddr;
    wire [`InstrID_WIDTH-1:0] InstrId;
    wire [31:0] Data_Rs, Data_Rt, Data_Rd;
    wire BranchCmp;
    // Level3: Execute
    wire [31:0] ALUOut;
    wire [4:0] RegWriteAddr;
    wire [31:0] MemWriteData;
    // Level4: Memory
    wire [31:0] MemReadData;
    // Level5: WriteBack
    wire [31:0] RegWriteData;

    // Modules
    // IF
    PC ProgramCounter (
        .clk(clk), .rst(reset), 
        .WE(1'b1), 
        .nPC(nextPC), .PC(PC)
    );

    IM InstructionMemory (
        .PC(PC), .Instr_Hex(InstrHex)
    );

    NPC NextProgramCounter (
        .PC(PC), .Instr(InstrId), .BranchCmp(BranchCmp),
        .Imm16(Imm16), .JmpAddr(JmpAddr), .JmpReg(Data_Rs),
        .NextPC(nextPC), .PCInOrder(PCInOrder)
    );
    // ID
    Decoder decoder (
        .HexCode(InstrHex), 
        .rs(Addr_Rs), .rt(Addr_Rt), .rd(Addr_Rd), 
        .shamt(shamt), .imm(Imm16), .jaddr(JmpAddr), 
        .instr_id(InstrId)
    );
    GRF GeneralRegisterFile (
        .clk(clk), .rst(reset), .pc(PC), 
        .Instr(InstrId), 
        .RAddr1(Addr_Rs), .RAddr2(Addr_Rt), 
        .WAddr(RegWriteAddr), .WData(RegWriteData),
        .RData1(Data_Rs), .RData2(Data_Rt)
    );
    COMP comparator (
        .Instr(InstrId), 
        .DataRs(Data_Rs), .DataRt(Data_Rt), 
        .result(BranchCmp)
    );
    // EX
    ALU alu (
        .Instr(InstrId), 
        .DataRs(Data_Rs), .DataRt(Data_Rt), 
        .Imm16(Imm16), .shamt(shamt), 
        .AddrRt(Addr_Rt), .AddrRd(Addr_Rd), 
        .Out(ALUOut),
        .RegWriteAddr(RegWriteAddr), .MemWriteData(MemWriteData)
    );

    // MEM
    DM DataMemory (
        .clk(clk), .rst(reset), .Instr(InstrId), .pc(PC), 
        .Addr(ALUOut), .WData(MemWriteData), 
        .RData(MemReadData)
    );

    // WB
    WriteBack writeback (
        .Instr(InstrId), 
        .ALUOut(ALUOut), 
        .MemRead(MemReadData), 
        .PCInOrder(PCInOrder), 
        .RegWriteData(RegWriteData)
    );

endmodule
