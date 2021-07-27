`default_nettype none
`include "include/instructions.v"
`include "include/exception.v"
`include "include/memory.v"

/*
 *  Overview: Bridge module, connect CPU with memory and devices
 *      CPU side: I Port (Read only), D Port (Read and Write) and Interrupt Port
 */
module Bridge (
    /* CPU I Port */
    input wire `WORD IAddr,
    output wire `WORD IData,
    output wire IReady,
    /* CPU D Port */
    input wire `WORD DPC,
    input wire `WORD DAddr,
    input wire DREn,
    input wire DWEn,
    input wire [3:0] DByteEn,
    input wire `WORD DWData,
    output wire `WORD DRData,
    output wire DReady,
    /* CPU Interrupt */
    output wire `TYPE_INT HWINT,
    ///////////////////////////
    // IM
    output wire `WORD IM_ADDR,
    output wire IM_CE,
    output wire IM_WE,
    output wire IM_RE,
    output wire [3:0] IM_BE,
    output wire `WORD IM_DIN,
    input wire `WORD IM_DOUT,
    input wire IM_READY,
    // DM
    output wire `WORD DM_PC,
    output wire `WORD DM_ADDR,
    output wire DM_CE,
    output wire DM_WE,
    output wire DM_RE,
    output wire [3:0] DM_BE,
    output wire `WORD DM_DIN,
    input wire `WORD DM_DOUT,
    input wire DM_READY,
    // Timer0
    output wire [31:2] TIMER0_ADDR,
    output wire `WORD TIMER0_DIN,
    output wire TIMER0_WE,
    input wire `WORD TIMER0_DOUT,
    input wire TIMER0_INT,
    // Timer1
    output wire [31:2] TIMER1_ADDR,
    output wire `WORD TIMER1_DIN,
    output wire TIMER1_WE,
    input wire `WORD TIMER1_DOUT,
    input wire TIMER1_INT,
    // Outside
    input wire EXTERN_INT
);

    /* I Port <===> IM */
    assign IM_ADDR = IAddr - `IM_ADDR_START;
    assign IM_CE = 1;
    assign IM_WE = 0;
    assign IM_RE = 1;
    assign IM_BE = 4'b1111;
    assign IM_DIN = 0;
    assign IData = IM_DOUT;
    assign IReady = IM_READY;


    /* D Port */
    wire DMsel, TIMER0sel, TIMER1sel;
    assign DMsel = (DAddr >= `DM_ADDR_START && DAddr <= `DM_ADDR_END);
    assign TIMER0sel = (DAddr >= `TIMER0_ADDR_START && DAddr <= `TIMER0_ADDR_END);
    assign TIMER1sel = (DAddr >= `TIMER1_ADDR_START && DAddr <= `TIMER1_ADDR_END);

    // DM
    assign DM_PC = DPC;
    assign DM_ADDR = DAddr;
    assign DM_DIN = DWData;
    assign DM_BE = DByteEn;
    assign DM_CE = DMsel & (DWEn | DREn);
    assign DM_WE = (DWEn) & (DM_CE);
    assign DM_RE = (DREn) & (DM_CE);

    // Timer0
    assign TIMER0_ADDR = DAddr[31:2];
    assign TIMER0_DIN = DWData;
    assign TIMER0_WE = TIMER0sel & DWEn;

    // Timer1
    assign TIMER1_ADDR = DAddr[31:2];
    assign TIMER1_DIN = DWData;
    assign TIMER1_WE = TIMER1sel & DWEn;

    // D-MUX
    assign {DRData, DReady} =   (DMsel & DREn) ? ({DM_DOUT, DM_READY}) :
                                (TIMER0sel & DREn) ? ({TIMER0_DOUT, 1'b1}) :
                                (TIMER1sel & DREn) ? ({TIMER1_DOUT, 1'b1}) :
                                0;

    /* Interrupt */
    assign HWINT = {3'b0, EXTERN_INT, TIMER1_INT, TIMER0_INT};

endmodule