/* 
 * File Name: mips.v
 * Module Name: mips
 * Description: Top Module of the MIPS MicroSystem
 */
`default_nettype none

/* ---------- Main Body ---------- */
module mips (
    input wire clk,
    input wire rst_n, 
    // LED
    output wire [3:0] led, 
    // DigitalTube
    output wire [3:0] digitalTube_sel, 
    output wire [7:0] digitalTube_digit, 
    // ButtonSwitch
    input wire [3:0] button_input, 
    // Buzzer
    output wire buzz
);
    /* 1. Declare Wires */
    // cpu
    wire [31:0] PC;
    wire [31:0] BrPC;
    wire [31:0] BrAddr;
    wire [31:0] BrWData;
    wire [3:0] BrWE;
    wire [31:0] IMPC;
    
    // NorthBridge
    wire [31:0] BrRData;
    wire [31:0] DM_PC, DM_Addr, DM_WData;
    wire [3:0] DM_WE;
    wire [6:2] BrExc;
    wire [7:2] HWInt;

    wire [31:0] SBr_PC, SBr_Addr, SBr_WData;
    wire SBr_WE;
    // DataMem
    wire [31:0] DM_RData;
    // InstrMem
    wire [31:0] IM_Code;
    // SouthBridge
    wire [31:0] SBr_RData;
    wire [7:2] SBr_HWInt;
    

    // Timer
    wire [31:2] Timer0_Addr;
    wire [31:0] Timer0_WData;
    wire Timer0_WE;
    wire [31:0] Timer0_RData;
    wire Timer0_Int;
    wire [31:2] Timer1_Addr;
    wire [31:0] Timer1_WData;
    wire Timer1_WE;
    wire [31:0] Timer1_RData = 0;
    wire Timer1_Int = 0;
    
    // LED
    wire [31:0] LED_WData;
    wire LED_WE;
    wire [31:0] LED_RData;

    // DigitalTube
    wire [31:0] DigitalTube_WData;
    wire DigitalTube_WE;
    wire [31:0] DigitalTube_RData;

    // ButtonSwitch
    wire [31:0] ButtonSwitch_RData;
    wire ButtonSwitch_Int;

    // Buzzer
    wire [31:2] Buzzer_Addr;
    wire [31:0] Buzzer_WData;
    wire Buzzer_WE;
    wire [31:0] Buzzer_RData;

    // splitted clocks
    wire clk_cpu;
    wire clk_mem;
    
    /* 2. Instantiate Modules */
    Clock #(.PERIOD(32'd5_000)) Clk_C1 (.clk(clk), .rst_n(rst_n), .clk_m(clk_cpu));
    Clock #(.PERIOD(32'd2_500)) Clk_C2 (.clk(clk), .rst_n(rst_n), .clk_m(clk_mem));


    CPU cpu (
        .clk(clk_cpu), 
        .rst_n(rst_n), 
        .PC(PC), 
        .BrPC(BrPC), 
        .BrAddr(BrAddr), 
        .BrWData(BrWData), 
        .BrWE(BrWE), 
        .BrRData(BrRData),
        .HWInt(HWInt),
        .IMPC(IMPC),
        .IMCode(IM_Code) 
    );

    NorthBridge nbridge (
        // CPU Port
        .PC(BrPC), .Addr(BrAddr), .WData(BrWData), .WE(BrWE), .RData(BrRData),
        // CPU Interruption
        .HWInt(HWInt), 
        // DM
        .DM_PC(DM_PC), .DM_Addr(DM_Addr), .DM_WData(DM_WData), .DM_WE(DM_WE), .DM_RData(DM_RData),
        // South Bridge
        .SBr_PC(SBr_PC), .SBr_Addr(SBr_Addr), .SBr_WData(SBr_WData), .SBr_WE(SBr_WE), .SBr_RData(SBr_RData), 
        .SBr_HWInt(SBr_HWInt)
    );

    DataMem dm (
        .clk_m(clk_mem), .rst_n(rst_n), 
        .PC(DM_PC), .Addr(DM_Addr[31:2]), .WData(DM_WData), .WE(DM_WE), .RData(DM_RData)
    );

    InstrMem im (
        .clk_m(clk_mem), 
        .PC(IMPC), .code(IM_Code)
    );

    SouthBridge sbridge (
        // CPU Port
        .Addr(SBr_Addr), .WData(SBr_WData), .WE(SBr_WE), .RData(SBr_RData), .HWInt(SBr_HWInt), 
        // Timer 0
        .Timer0_Addr(Timer0_Addr), .Timer0_WData(Timer0_WData), .Timer0_WE(Timer0_WE), .Timer0_RData(Timer0_RData), .Timer0_Int(Timer0_Int),
        // Timer 1
        .Timer1_Addr(Timer1_Addr), .Timer1_WData(Timer1_WData), .Timer1_WE(Timer1_WE), .Timer1_RData(Timer1_RData), .Timer1_Int(Timer1_Int),
        // LED
        .LED_WData(LED_WData), .LED_WE(LED_WE), .LED_RData(LED_RData), 
        // DigitalTube
        .DigitalTube_WData(DigitalTube_WData), .DigitalTube_WE(DigitalTube_WE), .DigitalTube_RData(DigitalTube_RData), 
        // ButtonSwitch
        .ButtonSwitch_RData(ButtonSwitch_RData), .ButtonSwitch_Int(ButtonSwitch_Int), 
        // Buzzer
        .Buzzer_Addr(Buzzer_Addr), .Buzzer_WData(Buzzer_WData), .Buzzer_WE(Buzzer_WE), .Buzzer_RData(Buzzer_RData)
    );

    Timer timer0 (
        .clk(clk), .rst_n(rst_n), .clk_cpu(clk_cpu),
        .Addr(Timer0_Addr), .WE(Timer0_WE), .Din(Timer0_WData), 
        .Dout(Timer0_RData), .IRQ(Timer0_Int)
    );

    /*Timer timer1 (
        .clk(clk), .rst_n(rst_n), .clk_cpu(clk_cpu),
        .Addr(Timer1_Addr), .WE(Timer1_WE), .Din(Timer1_WData), 
        .Dout(Timer1_RData), .IRQ(Timer1_Int)
    );*/

    LED Led (
        .clk_cpu(clk_cpu), .rst_n(rst_n), .WE(LED_WE), .Din(LED_WData), .Dout(LED_RData), 
        .led(led)
    );

    DigitalTube digitaltube (
        .clk(clk), .rst_n(rst_n), .clk_cpu(clk_cpu), .WE(DigitalTube_WE), .Din(DigitalTube_WData), .Dout(DigitalTube_RData), 
        .sel(digitalTube_sel), .digit(digitalTube_digit)
    );

    ButtonSwitch buttonswitch (
        .clk(clk), .clk_cpu(clk_cpu), .rst_n(rst_n), .Dout(ButtonSwitch_RData), .IRQ(ButtonSwitch_Int), 
        .key_input(button_input)
    );

    Buzzer buzzer (
        .clk(clk), .rst_n(rst_n), .clk_cpu(clk_cpu), .Addr(Buzzer_Addr), .Din(Buzzer_WData), .WE(Buzzer_WE), .Dout(Buzzer_RData), 
        .buzz(buzz)
    );

endmodule