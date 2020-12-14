/* 
 * File Name: Bridge.v
 * Module Name: NorthBridge, SouthBridge
 * Description: Map the address space into separated devices.
 */
`default_nettype none
`include "memconfig.v"

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
    // Outer Side
    // IM
    output wire [31:0] IM_Addr, 
    output wire [31:0] IM_WData, 
    output wire [3:0] IM_WE, 
    input wire [31:0] IM_RData, 
    // DM
    output wire [31:0] DM_PC, 
    output wire [31:0] DM_Addr, 
    output wire [31:0] DM_WData, 
    output wire [3:0] DM_WE, 
    input wire [31:0] DM_RData
);
    // DM Only
    assign DM_PC = PC2;
    assign DM_Addr = Addr2;
    assign DM_WData = WData2;
    assign DM_WE = WE2;
    assign RData2 = DM_RData;

endmodule

/*
 * Module Name: SouthBridge
 * Description: Connect CPU and Devices
 */

module SouthBridge (
    // CPU Side
    input wire [31:0] Addr, 
    input wire [31:0] WData, 
    input wire [3:0] WE,  
    output wire [31:0] RData, 
    output wire [7:2] IRQ, 
    // Device Side
    // Timer 0
    output wire [1:0] Timer0_Addr, 
    output wire [31:0] Timer0_WData, 
    output wire [3:0] Timer0_WE, 
    input wire [31:0] Timer0_RData, 
    input wire Timer0_IRQ, 
    // Timer 1
    output wire [1:0] Timer1_Addr, 
    output wire [31:0] Timer1_WData, 
    output wire [3:0] Timer1_WE, 
    input wire [31:0] Timer1_RData, 
    input wire Timer1_IRQ, 
    // External Interrupt
    input wire Ext_IRQ
);
    





    assign IRQ = {3'b0, Ext_IRQ, Timer1_IRQ, Timer0_IRQ};
endmodule
