`default_nettype none

module LED (
    input wire clk, 
    input wire rst_n, 
    input wire WE, 
    input wire [3:0] Din, 
    output wire [31:0] Dout, 
    /* ------ */
    output reg [3:0] led
);

    assign Dout = {28'd0, led};

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led <= 4'b1111;
        end
        else begin
            if (WE) begin
                led <= Din;
            end
        end
    end


endmodule

