`timescale 1ps/1ps

module tb_mips;
    reg clk = 0;
    reg rst_n = 0;

    wire [31:0] addr;

    mips uut (
        .clk(clk),
        .rst_n(rst_n),
        .interrupt(1'b0), 
        .addr(addr)
    );

    initial begin
        #20 rst_n = 1;
        #5000000 $finish;
    end

    always #5 clk = ~clk;

endmodule