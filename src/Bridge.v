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
    // RW Port 2 (For DM)
    input wire [31:0] PC, 
    input wire [31:0] Addr, 
    input wire [31:0] WData, 
    input wire [3:0] WE, 
    output wire [31:0] RData,
    // Interruption
    output wire [7:2] HWInt, 
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
    input wire [7:2] SBr_HWInt
);
    // DM
    assign DM_PC = PC;
    assign DM_Addr = Addr;
    assign DM_WData = WData;
    
    assign DM_WE = (Addr >= `DATA_STARTADDR && Addr < `DATA_ENDADDR) ? (WE) : 4'b0;

    // South Bridge
    assign SBr_PC = PC;
    assign SBr_Addr = Addr;
    assign SBr_WData = WData;
    assign SBr_WE = (
        (Addr >= `TIMER0_STARTADDR && Addr < `TIMER0_ENDADDR) ||
        (Addr >= `TIMER1_STARTADDR && Addr < `TIMER1_ENDADDR)
    ) ? (&WE) : 0;

    assign RData =  (Addr >= `DATA_STARTADDR && Addr < `DATA_ENDADDR) ? (DM_RData) : 
                    (Addr >= `TIMER0_STARTADDR && Addr < `TIMER0_ENDADDR) ? (SBr_RData) : 
                    (Addr >= `TIMER1_STARTADDR && Addr < `TIMER1_ENDADDR) ? (SBr_RData) : 
                    0 ;
    assign HWInt = SBr_HWInt;

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
    output wire [7:2] HWInt, 
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
    assign Timer0_WE = (Addr >= `TIMER0_STARTADDR && Addr < `TIMER0_ENDADDR) ? (WE) : 0;

    assign Timer1_Addr = Addr[31:2];
    assign Timer1_WData = WData;
    assign Timer1_WE = (Addr >= `TIMER1_STARTADDR && Addr < `TIMER1_ENDADDR) ? (WE) : 0;

    assign RData = (Addr >= `TIMER0_STARTADDR && Addr < `TIMER0_ENDADDR) ? (Timer0_RData) : 
                    (Addr >= `TIMER1_STARTADDR && Addr < `TIMER1_ENDADDR) ? (Timer1_RData) : 
                    0;

    assign HWInt = {3'b0, Ext_Int, Timer1_Int, Timer0_Int};
endmodule
