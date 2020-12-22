`default_nettype none

`define CTRL mem[0] // [0]: 1 - enable, 0 - disable
`define FREQ mem[1] // the frequency of the note
`define DUR  mem[2] // the duration of the note

module Buzzer(
    input wire clk, 
    input wire rst_n, 
    input wire clk_cpu, // slow clock
    input wire [31:2] Addr, 
    input wire [31:0] Din, 
    input wire WE, 
    output wire [31:0] Dout, 
    // Output
    output reg buzz
);
    localparam _IDLE = 1'b0,_RUN = 1'b1;
    reg state;
    localparam CLK_FREQ = 32'd50_000_000;
    reg [31:0] mem[2:0];
    assign Dout = mem[Addr[3:2]];
    wire [31:0] din = (Addr[3:2] == 0) ? {31'b0, Din[0]} : Din;
    integer i;
    reg [31:0] freq_count, dur_count;
    
    wire en = `CTRL[0];
    wire [31:0] freq_C = (`FREQ != 0) ? (CLK_FREQ / `FREQ) : 0;

    // buffer the clock of cpu
    reg _clk_cpu_l;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            _clk_cpu_l <= 0;
        end
        else begin
            _clk_cpu_l <= clk_cpu;
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            for (i = 0; i < 3; i = i + 1) begin
                mem[i] <= 0;
            end
            freq_count <= 0;
            dur_count <= 0;
            buzz <= 1'b0;
            state <= _IDLE;
        end
        else begin
            if (WE && (~_clk_cpu_l) && (clk_cpu)) begin
                mem[Addr[3:2]] <= din;
            end 
            else begin
                case (state) 
                _IDLE: if (en && freq_C) begin
                    dur_count <= `DUR;
                    freq_count <= freq_C;
                    state <= _RUN;
                end
                _RUN: if (en) begin
                    if (dur_count > 1) begin
                        if (freq_count > 0) begin
                            freq_count <= freq_count - 1;
                        end
                        else begin 
                            freq_count <= freq_C;
                            buzz <= ~buzz;
                        end
                        dur_count <= dur_count - 1;
                    end
                    else begin
                        dur_count <= 0;
                        freq_count <= 0;
                        `CTRL <= 0;
                        state <= _IDLE;
                    end
                end
                else begin
                    dur_count <= 0;
                    freq_count <= 0;
                    state <= _IDLE;
                end
                endcase
            end
        end
    end

endmodule
