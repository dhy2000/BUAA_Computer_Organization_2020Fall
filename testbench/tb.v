`timescale 1ns/1ps

module tb_mips;
    reg clk = 0;
    reg reset = 0;

    wire [31:0] addr;

    mips uut (
        .clk(clk),
        .reset(reset),
        .interrupt(1'b0), 
        .addr(addr)
    );

    initial begin
        reset = 1;
        #20 reset = 0;
        #200000 $finish;
    end

    always #2 clk = ~clk;

endmodule