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

// Device
`include "Device/Timer.v"

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
    wire [6:2] BrExc;
    wire [7:2] HWInt;

    wire [31:0] SBr_PC, SBr_Addr, SBr_WData, SBr_WE;
    // DataMem
    wire [31:0] DM_RData;
    // SouthBridge
    wire [31:0] SBr_RData;
    wire [7:2] SBr_HWInt;
    wire [31:2] Timer0_Addr;
    wire [31:0] Timer0_WData;
    wire Timer0_WE;
    wire [31:2] Timer1_Addr;
    wire [31:0] Timer1_WData;
    wire Timer1_WE;

    // Timer
    wire [31:0] Timer0_RData;
    wire Timer0_Int;
    wire [31:0] Timer1_RData;
    wire Timer1_Int;

    
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
        // CPU Exception and Interruption
        .Exc(BrExc), .HWInt(HWInt), 
        // IM
        .IM_Addr(), .IM_WData(), .IM_WE(), .IM_RData(32'b0), 
        // DM
        .DM_PC(DM_PC), .DM_Addr(DM_Addr), .DM_WData(DM_WData), .DM_WE(DM_WE), .DM_RData(DM_RData),
        // South Bridge
        .SBr_PC(SBr_PC), .SBr_Addr(SBr_Addr), .SBr_WData(SBr_WData), .SBr_WE(SBr_WE), .SBr_RData(SBr_RData)
    );

    DataMem dm (
        .clk(clk), .reset(reset), 
        .PC(DM_PC), .Addr(DM_Addr[31:2]), .WData(DM_WData), .WE(DM_WE), .RData(DM_RData)
    );

    SouthBridge sbridge (
        // CPU Port
        .Addr(SBr_Addr), .WData(SBr_WData), .WE(SBr_WE), .RData(SBr_RData), .HWInt(SBr_HWInt), 
        // Timer 0
        .Timer0_Addr(Timer0_Addr), .Timer0_WData(Timer0_WData), .Timer0_WE(Timer0_WE), .Timer0_RData(Timer0_RData), .Timer0_Int(Timer0_Int),
        // Timer 1
        .Timer1_Addr(Timer1_Addr), .Timer1_WData(Timer1_WData), .Timer1_WE(Timer1_WE), .Timer1_RData(Timer1_RData), .Timer1_Int(Timer1_Int),
        // External
        .Ext_Int(interrupt)
    );

    Timer timer0 (
        .clk(clk), .reset(reset), 
        .Addr(Timer0_Addr), .WE(Timer0_WE), .Din(Timer0_WData), 
        .Dout(Timer0_RData), .IRQ(Timer0_Int)
    );

    Timer timer1 (
        .clk(clk), .reset(reset), 
        .Addr(Timer1_Addr), .WE(Timer1_WE), .Din(Timer1_WData), 
        .Dout(Timer1_RData), .IRQ(Timer1_Int)
    );



endmodule