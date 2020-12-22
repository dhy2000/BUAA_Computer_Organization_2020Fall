`default_nettype none

module ButtonSwitch (
    input wire clk_cpu, 
    input wire rst_n, 
    output wire [31:0] Dout, 
    output reg IRQ, // only 1 cycle high
    /* ------ */
    input wire [3:0] key_input, 
    output reg [3:0] key_state
);
    assign Dout = {28'd0, key_state};

    parameter FILTER_DURATION = 32'd25_000; // 1ms
    // IDLE <===> FILTER
    localparam _IDLE = 1'b0, _FILTER = 1'b1;
    reg [3:0] key_next;
    wire curr_state = (key_next == key_state) ? _IDLE : _FILTER;
    reg [31:0] counter;

    always @ (posedge clk_cpu or negedge rst_n) begin
        if (!rst_n) begin
            key_state <= key_input;
            key_next <= key_input;
            IRQ <= 0;
            counter <= 0;
        end
        else begin
            if (curr_state == _IDLE) begin
                IRQ <= 0;
                if (key_input != key_state) begin
                    key_next <= key_input; // --> FILTER
                end
            end
            else begin
                if (counter < FILTER_DURATION) begin
                    counter <= counter + 1'd1;
                end
                else begin
                    if (key_input == key_next) begin // okay
                        IRQ <= 1;
                        key_state <= key_next; // --> IDLE
                    end
                    else begin
                        key_next <= key_state;
                    end
                    counter <= 0;
                end
            end
        end
    end

endmodule