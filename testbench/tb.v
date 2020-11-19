`timescale 1ps/1ps

module tb_mips;
    reg clk = 0;
    reg reset = 0;

    mips uut (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        reset = 1;
        #10 reset = 0;
        #500000 $finish;
    end

    always #5 clk = ~clk;

endmodule