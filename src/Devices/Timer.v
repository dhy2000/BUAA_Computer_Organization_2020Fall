`default_nettype none

`define IDLE 2'b00
`define LOAD 2'b01
`define CNT  2'b10
`define INT  2'b11

`define ctrl   mem[0]
`define preset mem[1]
`define count  mem[2]

module Timer(
    input wire clk,
    input wire rst_n, 
	input wire clk_cpu, 
    input wire [31:2] Addr,
    input wire WE,
    input wire [31:0] Din,
    output wire [31:0] Dout,
    output wire IRQ
    );

	// buffer the clock of cpu (slow)
	reg _clk_cpu_l;

	reg [1:0] state;
	reg [31:0] mem [2:0];
	
	reg _IRQ = 0;
	assign IRQ = `ctrl[3] & _IRQ;
	
	assign Dout = mem[Addr[3:2]];
	
	wire [31:0] load = Addr[3:2] == 0 ? {28'h0, Din[3:0]} : Din;
	
	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			_clk_cpu_l <= 0;
		end
		else 
			_clk_cpu_l <= clk_cpu;
	end

	integer i;
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state <= 0; 
			for(i = 0; i < 3; i = i+1) mem[i] <= 0;
			_IRQ <= 0;
		end
		else if(WE && (~_clk_cpu_l) && clk_cpu) begin
			// $display("%d@: *%h <= %h", $time, {Addr, 2'b00}, load);
			mem[Addr[3:2]] <= load;
			if (Addr[3:2] == 0 && load[3] == 0) begin
			  	_IRQ <= 0;
			end
		end
		else begin
			case(state)
				`IDLE : if(`ctrl[0]) begin
					state <= `LOAD;
					_IRQ <= 1'b0;
				end
				`LOAD : begin
					`count <= `preset;
					state <= `CNT;
				end
				`CNT  : 
					if(`ctrl[0]) begin
						if(`count > 1) `count <= `count-1;
						else begin
							`count <= 0;
							state <= `INT;
							_IRQ <= 1'b1;
						end
					end
					else state <= `IDLE;
				default : begin
					if(`ctrl[2:1] == 2'b00) `ctrl[0] <= 1'b0;
					else _IRQ <= 1'b0;
					state <= `IDLE;
				end
			endcase
		end
	end

endmodule
