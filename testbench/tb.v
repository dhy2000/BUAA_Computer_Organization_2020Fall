`timescale 1ps/1ps

module tb_mips;
    reg clk = 0;
    reg rst_n = 0;

    wire [3:0] led;
    wire [3:0] digitalTube_sel;
    wire [7:0] digitalTube_digit;

    reg [3:0] button_input = 4'b1111;

    wire buzz;

    mips uut (
        .clk(clk),
        .rst_n(rst_n),
        .led(led),
        .digitalTube_sel(digitalTube_sel),
        .digitalTube_digit(digitalTube_digit),
        .button_input(button_input),
        .buzz(buzz)
    );

    initial begin
        #20 rst_n = 1;
        #5000000 $finish;
    end

    always #5 clk = ~clk;

endmodule