/*
 *  Overview: Pipeline stage M (Memory)
 */

`default_nettype none
`include "../include/instructions.v"
`include "../include/exception.v"
`include "../include/memory.v"

/*
 *  Overview: module before DM, generates byte-en and offset for mem.
 */
module PREDM (
    input wire `TYPE_INSTR instr, 
    input wire `TYPE_IFUNC ifunc,
    input wire `WORD Addr, 
    input wire `WORD WData, 
    input wire `WORD PC, 
    // memory-write enable
    input wire en,
    // to DM
    output wire `WORD DPC,
    output wire `WORD DAddr,
    output wire DWEn,
    output wire DREn,
    output wire [3:0] DByteEn,
    output wire `WORD DWData,
    // word offset
    output wire [1:0] offset, 
    // exception
    output wire `TYPE_EXC exc
);
    // align address and get offset
    assign DAddr = {Addr[31:2], 2'b0};
    assign offset = Addr[1:0];
    
    // D mem
    assign DREn = (ifunc == `I_MEM_R);
    assign DWEn = (ifunc == `I_MEM_W);

    assign DByteEn = (en & (ifunc == `I_MEM_W)) ? (
        (instr == `SW) ? (4'b1111) : 
        (instr == `SH) ? (4'b0011 << ({1'b0, offset[1]} << 1)) : 
        (instr == `SB) ? (4'b0001 << (offset)) : 
        (4'b0000)
    ) : 4'b0;
    
    assign DPC = PC;
    assign DWData = (instr == `SH) ? (WData << ({4'b0, offset[1]} << 4)) : 
                    (instr == `SB) ? (WData << ({3'b0, offset} << 3)) : 
                    (WData);

    // Exceptions
    assign exc = (
        ((instr == `LW) && (Addr[1:0] != 0)) ? (`EXC_ADEL) : // load not-aligned word
        ((instr == `LH || instr == `LHU) && (Addr[0] != 0)) ? (`EXC_ADEL) : // load not-aligned halfword
        ((instr == `LH || instr == `LHU || instr == `LB || instr == `LBU) && !(Addr >= `DM_ADDR_START && Addr < `DM_ADDR_END)) ? (`EXC_ADEL) : // load non-whole word on timer register
        ((ifunc == `I_MEM_R) && !(
            (Addr >= `DM_ADDR_START && Addr < `DM_ADDR_END) || 
            (Addr >= `TIMER0_ADDR_START && Addr < `TIMER0_ADDR_END) || 
            (Addr >= `TIMER1_ADDR_START && Addr < `TIMER1_ADDR_END))) ? (`EXC_ADEL) : // Not-Valid Address Space
        ((instr == `SW) && (Addr[1:0] != 0)) ? (`EXC_ADES) : // store not-aligned word
        ((instr == `SH) && (Addr[0] != 0)) ? (`EXC_ADES) : // store not-aligned halfword
        ((instr == `SH || instr == `SB) && !(Addr >= `DM_ADDR_START && Addr < `DM_ADDR_END)) ? (`EXC_ADES) : 
        ((ifunc == `I_MEM_W) && !(
            (Addr >= `DM_ADDR_START && Addr < `DM_ADDR_END) || 
            (Addr >= `TIMER0_ADDR_START && Addr < `TIMER0_ADDR_END) || 
            (Addr >= `TIMER1_ADDR_START && Addr < `TIMER1_ADDR_END))) ? (`EXC_ADES) :
        ((ifunc == `I_MEM_W) && (Addr == `TIMER0_COUNT || Addr == `TIMER1_COUNT)) ? (`EXC_ADES) :
        0
    );

endmodule

