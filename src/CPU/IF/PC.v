`ifndef CPU_IF_PC_INCLUDED
`define CPU_IF_PC_INCLUDED
/*
 *  Module: PC
 *  Inputs: clk, reset, En, NPC
 *  Outputs: PC
 *  Description: Program Counter
 */
`default_nettype none
`include "../../memconfig.v"

module PC (
    input wire clk, 
    input wire reset,
    // control
    input wire En,  // Write Enable, 0 if the pipeline stalls
    // data
    input wire [31:0] NPC, // next PC
    // output
    output wire [31:0] PC
);
    reg [31:0] pc = `TEXT_STARTADDR;
    assign PC = pc;
    
    initial begin
        pc <= `TEXT_STARTADDR;
    end
    
    always @(posedge clk ) begin
        if (reset) begin
            pc <= `TEXT_STARTADDR;
        end
        else begin
            if (En) begin
                pc <= NPC;
            end
            else begin
                pc <= pc;
            end
        end
    end

endmodule

`endif
