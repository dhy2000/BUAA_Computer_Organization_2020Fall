/* ------ General Register File ------ */

/* 
 * This module is logically separated into Read and Write parts.
 * Read: combinatial logic 
 *  params : RAddr1, RAddr2
 *  returns: RData1, RData2
 * Write: Sequential logic
 *  params : clk, rst, WAddr, WData, pc, Instr(RegWrite)
 *  returns: none
 */

`default_nettype none

`include "instructions.v"

module GRF (
    // input
    // time seq
    input wire clk, 
    input wire rst, 
    // data input
    input wire [4:0] RAddr1, 
    input wire [4:0] RAddr2,
    input wire [4:0] WAddr, 
    input wire [31:0] WData,
    // pipeline signal
    input wire [31:0] pc,
    // control signal
    input wire [`InstrID_WIDTH-1:0] Instr, // for WB level, not ID level !!!!
    // output
    output wire [31:0] RData1, 
    output wire [31:0] RData2
);
    reg [31:0] grf [0: 31];
    // Read
    assign RData1 = grf[RAddr1]; 
    assign RData2 = grf[RAddr2];

    // Write
    task resetAllReg;
        integer i;
        begin
            for (i = 0; i <= 31; i = i + 1) begin
                grf[i] <= 0;
            end
        end
    endtask
    
    task writeToReg;
        input [4:0] addr;
        input [31:0] data;
        input [31:0] pc;
        begin
            if (addr != 0) begin
                $display("@%h: $%d <= %h", pc, addr, data);
                grf[addr] <= data;
            end
            else begin
                grf[addr] <= 0;
            end
        end
    endtask

    initial begin
        resetAllReg;
    end

    // Instantiate an InstrCategorizer
    // wire [`FORMAT_WIDTH-1:0] format;
    wire [`FUNCTYPE_WIDTH-1:0] functype;
    InstrCategorizer categorizer (
        .instr_id(Instr), 
        .format(), .functype(functype)
    );
    
    wire WEnable;
    assign WEnable = (
        (functype == `FUNC_ARITH) || (functype == `FUNC_LOGICAL) || (functype == `FUNC_SHIFT) || 
        (functype == `FUNC_MEMLOAD) ||
        (Instr == `JAL) || (Instr == `JALR)
    );
    
    always @ (posedge clk /* or posedge rst */ ) begin
        if (rst) begin
            resetAllReg;
        end
        else begin
            if (WEnable) begin
                writeToReg (WAddr, WData, pc);
            end
        end
    end
    
endmodule
