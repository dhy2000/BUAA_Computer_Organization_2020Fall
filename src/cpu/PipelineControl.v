/*
 *  Overview: Pipeline Controller
 */

`default_nettype none
`include "../include/instructions.v"
`include "../include/exception.v"
`include "../include/memory.v"

/*
 *  Overview: Pipeline controller module, controlling the pipeline work or stall, also processing macro status of cpu.
 *  Input:
 *      - Instruction at D
 *      - Register use of each stage
 *      - Register write of each stage
 *      - Tnew at each stage
 *      - Busy signals of each stage
 *      - EXL Op from CP0
 *      -
 *  Output:
 *      - Stall signals
 *      - Clear signals
 *      - Enable signals for some stage
 */

module PipelineControl (
    // instruction at D
    input wire `TYPE_INSTR instr_D,
    input wire `TYPE_IFUNC ifunc_D,
    // reg use
    input wire useRs_D,
    input wire useRt_D,
    input wire `TYPE_REG addrRs_D,
    input wire `TYPE_REG addrRt_D,
    input wire useRs_E,
    input wire useRt_E,
    input wire `TYPE_REG addrRs_E,
    input wire `TYPE_REG addrRt_E,
    input wire useRt_M,
    input wire `TYPE_REG addrRt_M,
    // reg write
    input wire regWEn_D,
    input wire `TYPE_REG regWAddr_D,
    input wire regWValid_D,
    input wire regWEn_E,
    input wire `TYPE_REG regWAddr_E,
    input wire regWValid_E,
    input wire regWEn_M,
    input wire `TYPE_REG regWAddr_M,
    input wire regWValid_M,
    input wire regWEn_W,
    input wire `TYPE_REG regWAddr_W,
    input wire regWValid_W,
    // Tnew
    input wire `TYPE_T TuseRs_D,
    input wire `TYPE_T TuseRt_D,
    input wire `TYPE_T Tnew_D,
    input wire `TYPE_T Tnew_E,
    input wire `TYPE_T Tnew_M,
    input wire `TYPE_T Tnew_W,
    // busy
    input wire busyI,
    input wire busyD,
    input wire busyMD,
    // EXL
    input wire `TYPE_EXLOP EXLOp,
    // output
    output wire enPC,
    output wire enMD,
    output wire enD,
    output wire enGRF,
    output wire stall_D,
    output wire clear_D,
    output wire stall_E,
    output wire clear_E,
    output wire stall_M,
    output wire clear_M,
    output wire stall_W,
    output wire clear_W
);

    /*
     *  Pipeline stall conditions:
     *      1. I-Fetch busy: @F, disable PC, stall F/D, clear D/E
     *      2. Data hazard (Tnew > Tuse): @D, disable PC, stall F/D, clear D/E
     *      3. MDU busy with MDU instr following: @D, disable PC, stall F/D, clear D/E
     *      4. D-RW busy: @M, disable PC, stall F/D, stall D/E, stall E/M, clear M/W
     *      5. EXL change (Interrupt/Exception, eret): enable PC, clear all (HIGHEST PRIORITY)
     */

    // 1. I-Fetch busy
        // busyI
    
    // 2. Data hazard
    wire waitRs, waitRt;
    assign waitRs = (useRs_D & (addrRs_D != 0)) && (
        ((regWEn_E) & (regWAddr_E == addrRs_D) & (Tnew_E > TuseRs_D)) ||
        ((regWEn_M) & (regWAddr_M == addrRs_D) & (Tnew_M > TuseRs_D))
    );
    assign waitRt = (useRt_D & (addrRt_D != 0)) && (
        ((regWEn_E) & (regWAddr_E == addrRt_D) & (Tnew_E > TuseRt_D)) ||
        ((regWEn_M) & (regWAddr_M == addrRt_D) & (Tnew_M > TuseRt_D))
    );
    wire waitReg = (waitRs | waitRt);

    // 3. MDU busy
    wire waitMD = (busyMD & (ifunc_D == `I_MD));

    // 4. D-RW busy
        // busyD

    // 5. EXL change
    wire exl = (EXLOp != 0);

    // Generate control signals
    assign {enPC, enMD, enD, enGRF, stall_D, stall_E, stall_M, stall_W, clear_D, clear_E, clear_M, clear_W} = 
        (exl)                               ? (12'b1001_0000_1111) :
        (busyD)                             ? (12'b0110_1111_0000) :
        (waitMD | waitReg | busyI)          ? (12'b0111_1000_0100) :
        (12'b1111_0000_0000);

endmodule
