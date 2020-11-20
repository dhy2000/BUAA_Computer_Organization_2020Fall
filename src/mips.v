/* 
 * File Name: mips.v
 * Module Name: mips
 * Description: Top Module of CPU
 */
`default_nettype none
`include "instructions.v"
/* ---------- Parts ---------- */
`include "PC.v"
`include "NPC.v"
`include "IM.v"
`include "Decoder.v"
`include "GRF.v"
`include "COMP.v"
`include "ALU.v"
`include "RegWriteSel.v"
`include "DM.v"
`include "WB.v"
`include "pipeline.v"

/* ---------- Main Body ---------- */
module mips (
    input wire clk,
    input wire reset
);
    /*
        5-Level Pipeline: 
        1. IF  2. ID(D)  3. EX(E)  4. MEM(M)  5. WB(W)
    */
    /* 1. Declare Wires */
    // PC
    wire [31:0] PC;
    // NPC
    wire [31:0] NPC;
    wire [31:0] PCToLink;
    // IM
    wire [31:0] Code; 
    // --- 
    // Decoder
    wire [31:0] Instr;
    wire [4:0] AddrRs;
    wire [4:0] AddrRt;
    wire [4:0] AddrRd;
    wire [4:0] Shamt;
    wire [15:0] Imm16;
    wire [25:0] JmpAddr;
    // GRF
    wire [31:0] DataRs;
    wire [31:0] DataRt;
    // COMP
    wire Cmp;
    // ---
    // ALU
    wire [31:0] AluOut;
    // RegWriteSel
    wire [4:0] RegWriteAddr;
    // ---
    // DM
    wire [31:0] MemReadData;
    // --- 
    // WB
    wire regWriteEn;
    wire [31:0] RegWriteData;
    // --- Pipeline Register
    // IF/ID
    wire [31:0] Code_ID;
    wire [31:0] PCToLink_ID;
    // ID/EX
    wire [31:0] DataRs_EX;
    wire [31:0] DataRt_EX;
    wire [15:0] Imm16_EX;
    wire [4:0] Shamt_EX;
    wire [4:0] AddrRs_EX;
    wire [4:0] AddrRt_EX;
    wire [4:0] AddrRd_EX;
    wire [31:0] PCToLink_EX;
    // EX/MEM
    wire [31:0] AluOut_MEM;
    wire [31:0] MemWriteData_MEM;
    wire [4:0] RegWriteAddr_MEM;
    wire [31:0] PCToLink_MEM;
    // MEM/WB
    wire [31:0] AluOut_WB;
    wire [31:0] MemReadData_WB;
    wire [31:0] PCToLink_WB;
    wire [4:0] RegWriteAddr_WB;

    /* 2. Instantiate Modules */
    



    
endmodule