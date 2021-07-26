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

module StageM (
    input wire                      clk,
    input wire                      reset,
    /* From previous stage */
    input wire `TYPE_INSTR          instr_M         ,
    input wire `TYPE_IFUNC          ifunc_M         ,
    input wire `WORD                PC_M            ,
    input wire                      BD_M            ,
    input wire `TYPE_EXC            EXC_M           ,
    input wire                      useRt_M         ,
    input wire `TYPE_REG            addrRt_M        ,
    input wire `WORD                dataRt_M        ,
    input wire `TYPE_REG            addrRd_M        ,
    input wire `WORD                aluOut_M        ,
    input wire                      regWEn_M        ,
    input wire `TYPE_REG            regWAddr_M      ,
    input wire `WORD                regWData_M      ,
    input wire                      regWValid_M     ,
    input wire `TYPE_T              Tnew_M          ,
    /* To next stage */
    // Instruction
    output reg `TYPE_INSTR          instr_W         = 0,
    output reg `TYPE_IFUNC          ifunc_W         = 0,
    output reg `WORD                PC_W            = 0,
    // Reg write
    output reg                      regWEn_W        = 0,
    output reg `TYPE_REG            regWAddr_W      = 0,
    output reg `WORD                regWData_W      = 0,
    output reg                      regWValid_W     = 0,
    output reg `TYPE_T              Tnew_W          = 0,
    // Data
    output reg [1:0]                offset_W        = 0,
    output reg `WORD                memWord_W       = 0,
    /* Interface with DM */
    output wire `WORD               DPC,
    output wire `WORD               DAddr,
    output wire                     DREn,
    output wire                     DWEn,
    output wire [3:0]               DByteEn,
    output wire `WORD               DWData,
    input wire `WORD                DRData,
    input wire                      DReady,
    /* Interface with CP0 */
    output wire `TYPE_REG           CP0reg,
    output wire `WORD               CP0WData,
    input wire `WORD                CP0RData,
    output wire `TYPE_EXC           CP0EXC,
    /* Interface with Pipeline Control */
    input wire                      stall,
    input wire                      clear,
    input wire                      enD,
    output wire                     busyD
);

    /* ------ Wires Declaration ------ */
    // instruction
    wire `TYPE_INSTR instr;
    wire `TYPE_IFUNC ifunc;
    // bypass
    wire `WORD dataRt_use;
    // pre dm
    wire [1:0] offset;
    wire `TYPE_EXC excMEM;
    // reg write
    wire regWEn;
    wire `TYPE_REG regWAddr;
    wire `WORD regWData;
    wire regWValid;
    wire `TYPE_T Tnew;


    /* ------ Instantiate Modules ------ */
    PREDM predm (
        .instr(instr), .ifunc(ifunc),
        .Addr(aluOut_M), .WData(dataRt_use), .PC(PC_M), .en(enD),
        .DPC(DPC), .DAddr(DAddr), .DWEn(DWEn), .DREn(DREn), .DByteEn(DByteEn), .DWData(DWData),
        .offset(offset), .exc(excMEM)
    );

    /* ------ Combinatinal Logic ------ */
    // instruction
    assign instr = instr_M;
    assign ifunc = ifunc_M;
    assign Tnew = (Tnew_M >= 1) ? (Tnew_M - 1) : 0;
    // bypass select
    assign dataRt_use = (
        (regWEn_W & (regWAddr_W == addrRt_M) & (regWAddr_W != 0)) ? (regWData_W) :
        (dataRt_M)
    );
    // D Interface
    assign busyD = (DREn | DWEn) & (~DReady);
    // CP0 Interface
    assign CP0reg = addrRd_M;
    assign CP0WData = dataRt_use;
    assign CP0EXC = (EXC_M) ? (EXC_M) : excMEM;
    // reg write
    assign regWEn = regWEn_M;
    assign regWAddr = regWAddr_M;
    assign regWData =   (instr == `MFC0) ? (CP0RData) :
                        ((ifunc == `I_MEM_R) && (instr == `LW)) ? (DRData) :
                        regWData_M;
    assign regWValid = (regWValid_M) || ((instr == `MFC0) || (instr == `LW));
    

    /* ------ Pipeline Registers ------ */
    always @ (posedge clk) begin
        if (reset) begin
            instr_W         <=  0;
            ifunc_W         <=  0;
            PC_W            <=  0;
            regWEn_W        <=  0;
            regWAddr_W      <=  0;
            regWData_W      <=  0;
            regWValid_W     <=  0;
            Tnew_W          <=  0;
            offset_W        <=  0;
            memWord_W       <=  0;
        end
        else begin
            if (clear & (~stall)) begin
                instr_W         <=  0;
                ifunc_W         <=  0;
                PC_W            <=  0;
                regWEn_W        <=  0;
                regWAddr_W      <=  0;
                regWData_W      <=  0;
                regWValid_W     <=  0;
                Tnew_W          <=  0;
                offset_W        <=  0;
                memWord_W       <=  0;
            end
            else if (~stall) begin
                instr_W         <=  instr;
                ifunc_W         <=  ifunc;
                PC_W            <=  PC_M;
                regWEn_W        <=  regWEn;
                regWAddr_W      <=  regWAddr;
                regWData_W      <=  regWData;
                regWValid_W     <=  regWValid;
                Tnew_W          <=  Tnew;
                offset_W        <=  offset;
                memWord_W       <=  DRData;
            end
        end
    end

endmodule
