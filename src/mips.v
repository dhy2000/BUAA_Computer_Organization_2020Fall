/* 
 * File Name: mips.v
 * Module Name: mips
 * Description: Top Module of CPU
 */
`default_nettype none

`include "CPU/cpu.v"


/* ---------- Main Body ---------- */
module mips (
    input wire clk,
    input wire reset
);
    CPU cpu (
        .clk(clk), 
        .reset(reset)
    );
endmodule