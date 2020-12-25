`default_nettype none

module Clock 
#(parameter PERIOD = 32'd2)
(
    input wire clk, 
    input wire rst_n, 
    output reg clk_m
);
    reg [31:0] cnt;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_m <= 0;
            cnt <= 0;
        end
        else begin
            if (cnt == PERIOD) begin
                clk_m <= ~clk_m;
                cnt <= 0;
            end
            else begin
                cnt <= cnt + 32'd1;
            end
        end
    end

endmodule