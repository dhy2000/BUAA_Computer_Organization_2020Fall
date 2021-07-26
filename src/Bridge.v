/* 
 * File Name: Bridge.v
 * Module Name: NorthBridge, SouthBridge
 * Description: Map the address space into separated devices.
 */
`default_nettype none
`include "include/memconfig.v"

/*
 * Module Name: NorthBridge
 * Description: Connect CPU and Memory
 */
module NorthBridge (
    // CPU Side
    // RW Port 1 (For IM)
    input wire [31:0] Addr1, 
    input wire [31:0] WData1, 
    input wire [3:0] WE1, 
    output wire [31:0] RData1,
    // RW Port 2 (For DM)
    input wire [31:0] PC2, 
    input wire [31:0] Addr2, 
    input wire [31:0] WData2, 
    input wire [3:0] WE2, 
    output wire [31:0] RData2,
    // Interruption
    output wire [7:2] HWINT, 
    // Outer Side
    // // IM
    // output wire [31:0] IM_Addr, 
    // output wire [31:0] IM_WData, 
    // output wire [3:0] IM_WE, 
    // input wire [31:0] IM_RData, 
    // DM
    output wire [31:0] DM_PC, 
    output wire [31:0] DM_Addr, 
    output wire [31:0] DM_WData, 
    output wire [3:0] DM_WE, 
    input wire [31:0] DM_RData,
    // South Bridge
    output wire [31:0] SBr_PC, 
    output wire [31:0] SBr_Addr, 
    output wire [31:0] SBr_WData, 
    output wire SBr_WE, 
    input wire [31:0] SBr_RData,
    input wire [7:2] SBr_HWINT
);
    // DM
    assign DM_PC = PC2;
    assign DM_Addr = Addr2;
    assign DM_WData = WData2;
    
    assign DM_WE = (Addr2 >= `DM_ADDR_START && Addr2 < `DM_ADDR_END) ? (WE2) : 4'b0;

    // South Bridge
    assign SBr_PC = PC2;
    assign SBr_Addr = Addr2;
    assign SBr_WData = WData2;
    assign SBr_WE = (
        (Addr2 >= `TIMER0_ADDR_START && Addr2 < `TIMER0_ADDR_END) ||
        (Addr2 >= `TIMER1_ADDR_START && Addr2 < `TIMER1_ADDR_END)
    ) ? (&WE2) : 0;

    assign RData2 = (Addr2 >= `DM_ADDR_START && Addr2 < `DM_ADDR_END) ? (DM_RData) : 
                    (Addr2 >= `TIMER0_ADDR_START && Addr2 < `TIMER0_ADDR_END) ? (SBr_RData) : 
                    (Addr2 >= `TIMER1_ADDR_START && Addr2 < `TIMER1_ADDR_END) ? (SBr_RData) : 
                    0 ;
    assign HWINT = SBr_HWINT;

endmodule

/*
 * Module Name: SouthBridge
 * Description: Connect CPU and Devices
 */

module SouthBridge (
    // CPU Side
    input wire [31:0] Addr, 
    input wire [31:0] WData, 
    input wire WE,  
    output wire [31:0] RData, 
    output wire [7:2] HWINT, 
    // Device Side
    // Timer 0
    output wire [31:2] Timer0_Addr, 
    output wire [31:0] Timer0_WData, 
    output wire Timer0_WE, 
    input wire [31:0] Timer0_RData, 
    input wire Timer0_Int, 
    // Timer 1
    output wire [31:2] Timer1_Addr, 
    output wire [31:0] Timer1_WData, 
    output wire Timer1_WE, 
    input wire [31:0] Timer1_RData, 
    input wire Timer1_Int, 
    // External Interrupt
    input wire Ext_Int
);
    assign Timer0_Addr = Addr[31:2];
    assign Timer0_WData = WData;
    assign Timer0_WE = (Addr >= `TIMER0_ADDR_START && Addr < `TIMER0_ADDR_END) ? (WE) : 0;

    assign Timer1_Addr = Addr[31:2];
    assign Timer1_WData = WData;
    assign Timer1_WE = (Addr >= `TIMER1_ADDR_START && Addr < `TIMER1_ADDR_END) ? (WE) : 0;

    assign RData = (Addr >= `TIMER0_ADDR_START && Addr < `TIMER0_ADDR_END) ? (Timer0_RData) : 
                    (Addr >= `TIMER1_ADDR_START && Addr < `TIMER1_ADDR_END) ? (Timer1_RData) : 
                    0;

    assign HWINT = {3'b0, Ext_Int, Timer1_Int, Timer0_Int};
endmodule
