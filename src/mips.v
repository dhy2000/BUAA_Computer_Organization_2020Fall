/* 
 * File Name: mips.v
 * Module Name: mips
 * Description: Top Module of CPU
 */
`default_nettype none

`include "CPU/cpu.v"
`include "Bridge.v"

// Memory
`include "Memory/DataMem.v"
`include "Memory/InstrMem.v"

/* ---------- Main Body ---------- */
module mips (
    input wire clk,
    input wire reset, 
    input wire interrupt, 
    output wire [31:0] addr
);
    /* 1. Declare Wires */
    // cpu
    wire [31:0] PC;
    wire [31:0] BrPC;
    wire [31:0] BrAddr;
    wire [31:0] BrWData;
    wire [3:0] BrWE;
    
    // NorthBridge
    wire [31:0] BrRData;
    wire [31:0] DM_PC, DM_Addr, DM_WData;
    wire [3:0] DM_WE;
    // DataMem
    wire [31:0] DM_RData;

    
    /* 2. Instantiate Modules */
    assign addr = PC;
    CPU cpu (
        .clk(clk), 
        .reset(reset), 
        .PC(PC), 
        .BrPC(BrPC), 
        .BrAddr(BrAddr), 
        .BrWData(BrWData), 
        .BrWE(BrWE), 
        .BrRData(BrRData)
    );

    NorthBridge nbridge (
        // CPU Port 1
        .Addr1(32'b0), .WData1(32'b0), .WE1(4'b0), .RData1(), 
        // CPU Port 2
        .PC2(BrPC), .Addr2(BrAddr), .WData2(BrWData), .WE2(BrWE), .RData2(BrRData),
        // IM
        .IM_Addr(), .IM_WData(), .IM_WE(), .IM_RData(32'b0), 
        // DM
        .DM_PC(DM_PC), .DM_Addr(DM_Addr), .DM_WData(DM_WData), .DM_WE(DM_WE), .DM_RData(DM_RData)
    );

    DataMem dm (
        .clk(clk), .reset(reset), 
        .PC(DM_PC), .Addr(DM_Addr[31:2]), .WData(DM_WData), .WE(DM_WE), .RData(DM_RData)
    );




endmodule