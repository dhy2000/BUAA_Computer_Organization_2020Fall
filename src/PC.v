/* ----------- Program Counter ----------- */

`default_nettype none
`include "instructions.v"
`include "memconfig.v"


module PC (
    // time sequential
    input wire clk,
    input wire rst,
    input wire WE,
    input wire [31:0] nPC,
    output wire [31:0] PC
);

parameter PC_START = `TEXT_STARTADDR;

    reg [31:0] pc = PC_START;
    assign PC = pc;

    initial begin
        pc <= PC_START;
    end
    
    always @(posedge clk /*or posedge rst*/ ) begin
        if (rst) begin
            pc <= PC_START;
        end
        else begin
            if (WE) begin
                pc <= nPC;
            end
            else begin
                pc <= pc;
            end
        end
    end

endmodule
