`ifndef CPU_MEM_PREDM_INCLUDED
`define CPU_MEM_PREDM_INCLUDED
/*
 * File Name: PREDM.v
 * Module Name: PREDM
 * Description: The Driver before DM, decode the instruction and generate signals to DM
 */

`default_nettype none
`include "memconfig.v"
`include "CPU/instructions.v"
`include "CPU/IC.v"

module PREDM (
    input wire [`WIDTH_INSTR-1:0] instr, 
    input wire [31:0] Addr, 
    input wire [31:0] WData, 
    input wire [31:0] PC, 
    // Link To DM
    output wire [31:0] DM_PC, 
    output wire [31:2] DM_Addr, 
    output wire [3:0] DM_WE, 
    output wire [31:0] DM_WData, 
    // output inside cpu
    output wire [1:0] offset
);
    // split the address
    assign DM_Addr = Addr[31:2];
    assign offset = Addr[1:0];
    
    wire [`WIDTH_FORMAT-1:0] format; wire [`WIDTH_FUNC-1:0] func;
    IC ic (.instr(instr), .format(format), .func(func));

    assign DM_WE = (func == `FUNC_MEM_WRITE) ? (
        (instr == `SW) ? (4'b1111) : 
        (instr == `SH) ? (4'b0011 << (offset[1] << 1)) : 
        (instr == `SB) ? (4'b0001 << (offset)) : 
        (4'b0000)
    ) : 0;
    
    assign DM_PC = PC;
    assign DM_WData = WData;

endmodule
`endif
