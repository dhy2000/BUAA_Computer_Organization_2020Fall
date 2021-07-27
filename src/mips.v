`default_nettype none
`include "include/instructions.v"
`include "include/exception.v"
`include "include/memory.v"

/*
 *  Overview: Top module of MIPS microsystem, for P7
 */
module mips (
    input wire clk,
    input wire reset,
    input wire interrupt,
    output wire `WORD addr
);

    /* ------ Wires Declaration ------ */
    // cpu
    wire `WORD IAddr;
    wire `WORD IData;
    wire IReady;
    
    wire `WORD DPC;
    wire `WORD DAddr;
    wire DREn, DWEn;
    wire [3:0] DByteEn;
    wire `WORD DWData, DRData;
    wire DReady;

    wire `TYPE_INT HWINT;

    // IM
    wire `WORD IM_ADDR;
    wire IM_CE, IM_WE, IM_RE;
    wire [3:0] IM_BE;
    wire `WORD IM_DIN, IM_DOUT;
    wire IM_READY;

    // DM
    wire `WORD DM_PC;
    wire `WORD DM_ADDR;
    wire DM_CE, DM_WE, DM_RE;
    wire [3:0] DM_BE;
    wire `WORD DM_DIN, DM_DOUT;
    wire DM_READY;

    // Timer 0 & 1
    wire [31:2] TIMER0_ADDR, TIMER1_ADDR;
    wire `WORD TIMER0_DIN, TIMER1_DIN;
    wire TIMER0_WE, TIMER1_WE;
    wire `WORD TIMER0_DOUT, TIMER1_DOUT;
    wire TIMER0_INT, TIMER1_INT;

    /* ------ Instantiate Modules ------ */

    CPU cpu (
        .clk(clk),
        .reset(reset),
        .IAddr(IAddr), .IData(IData), .IReady(IReady),
        .DPC(DPC), 
        .DAddr(DAddr), .DREn(DREn), .DWEn(DWEn),  .DByteEn(DByteEn), .DWData(DWData), 
        .DRData(DRData), .DReady(DReady),
        .HWINT(HWINT),
        .PC(addr)
    );

    Bridge br (
        .IAddr(IAddr), .IData(IData),.IReady(IReady),
        .DPC(DPC), .DAddr(DAddr), .DREn(DREn), .DWEn(DWEn), .DByteEn(DByteEn), .DWData(DWData), .DRData(DRData), .DReady(DReady),
        .HWINT(HWINT), 
        .IM_ADDR(IM_ADDR), .IM_CE(IM_CE), .IM_WE(IM_WE), .IM_RE(IM_RE), .IM_BE(IM_BE), .IM_DIN(IM_DIN), .IM_DOUT(IM_DOUT), .IM_READY(IM_READY),
        .DM_PC(DM_PC),
        .DM_ADDR(DM_ADDR), .DM_CE(DM_CE), .DM_WE(DM_WE), .DM_RE(DM_RE), .DM_BE(DM_BE), .DM_DIN(DM_DIN), .DM_DOUT(DM_DOUT), .DM_READY(DM_READY),
        .TIMER0_ADDR(TIMER0_ADDR), .TIMER0_DIN(TIMER0_DIN), .TIMER0_WE(TIMER0_WE), .TIMER0_DOUT(TIMER0_DOUT), .TIMER0_INT(TIMER0_INT),
        .TIMER1_ADDR(TIMER1_ADDR), .TIMER1_DIN(TIMER1_DIN), .TIMER1_WE(TIMER1_WE), .TIMER1_DOUT(TIMER1_DOUT), .TIMER1_INT(TIMER1_INT),
        .EXTERN_INT(interrupt)
    );

    

    Timer timer0 (
        .clk(clk), .reset(reset),
        .Addr(TIMER0_ADDR), .WE(TIMER0_WE), .Din(TIMER0_DIN), .Dout(TIMER0_DOUT),
        .IRQ(TIMER0_INT)
    );

    Timer timer1 (
        .clk(clk), .reset(reset),
        .Addr(TIMER1_ADDR), .WE(TIMER1_WE), .Din(TIMER1_DIN), .Dout(TIMER1_DOUT),
        .IRQ(TIMER1_INT)
    );


endmodule
