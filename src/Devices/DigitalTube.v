`default_nettype none

module DigitalTube(
    input wire clk, 
    input wire rst_n, 
    input wire WE, 
    input wire [31:0] Din, 
    output wire [31:0] Dout, 
    /* ------ ------ */
    input wire clk_scan, 
    output reg [3:0] sel, 
    output wire [7:0] digit
);
    parameter SCAN_PERIOD = 32'd25_000;

    reg [31:0] content;
    assign Dout = content;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            content <= 32'hffff_ffff;
        end
        else if (WE) begin
            content <= Din;
        end
    end

    reg [31:0] t_count;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_count <= 0;
        end
        else begin
            if (t_count == SCAN_PERIOD) begin
                t_count <= 0;
            end
            else begin
                t_count <= t_count + 1;
            end
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel <= 4'b1110;
        end
        else begin
            if (t_count == SCAN_PERIOD) begin
                sel <= {sel[2:0], sel[3]};
            end
        end
    end


endmodule

