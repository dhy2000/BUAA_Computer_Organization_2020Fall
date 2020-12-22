`default_nettype none

module LED (
    input wire clk_cpu, 
    input wire rst_n, 
    input wire WE, 
    input wire [31:0] Din, 
    output wire [31:0] Dout, 
    /* ------ */
    output reg [3:0] led
);

    assign Dout = {28'd0, led};

    always @ (posedge clk_cpu or negedge rst_n) begin
        if (!rst_n) begin
            led <= 4'b1111;
        end
        else begin
            if (WE) begin
                led <= Din[3:0];
            end
        end
    end


endmodule

