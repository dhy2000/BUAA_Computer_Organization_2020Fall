# P7 MIPS 微系统 (中断和异常)

P7 修订版，对原有的(较为混乱的) P7 源码进行了一定程度的修改和重构.

## 源码说明

全部源代码文件位于 `src` 目录下，其中 `mips.v` 为整个工程的顶层模块。

顶层模块要求：

```verilog
module mips (
    input clk,          // 时钟
    input reset,        // 同步复位, 高电平有效
    input interrupt,    // 外部中断, 高电平有效
    output [31:0] addr  // 宏观 PC, 具体含义详见课设指导书与 《See Mips Run Linux》
);
```
其他源码文件及目录说明：
- `Bridge.v` ：桥模块，用于连接 CPU 与外设。本实验中的外设包括两个定时器 `Timer`，指令存储器 `IM` 与数据存储器 `DM` 。
- `device` 目录：本实验中外设模块的源代码。<br>
注意：当前的 `IM` 与 `DM` 模块**不可综合**！（不可综合原因：1. 使用了不可综合的语法 `initial` 进行初始化；2. 采用寄存器数组实现 RAM）
- `cpu` 目录：CPU 核心的源代码，其中 CPU 顶层模块为 `cpu.v`。
- `include` 目录：所有 Verilog 头文件。


## 设计说明

CPU 采用五级流水线设计，分为 F (取指), D(译码), E(执行), M(访存), W(写回) 五个流水级。每个流水级封装了一个顶层模块，对应命名形如 `Stage*.v` 的源代码文件。

地址空间同 MARS 中的 `CompactDataAtZero` 模式：
- `.data` 可用地址为 `0x0000` - `0x2ffc`
- `.text` 起始地址为 `0x3000` - `0x4ffc`
- `.ktext` 只涉及异常中断处理, 异常中断统一入口为 `0x4180` 
- 两个定时器的地址空间分别为 `0x7f00` - `0x7f0b` 与 `0x7f10` - `0x7f1b` 

在本设计中指令存储器和数据存储器不再嵌入 CPU 内，而是拆分到了 Bridge 以外，当做外设对待. 并且在取指和访存的接口中增加了 `ready` 信号来支持 "多周期" 取指与访存(在当前的 `DM` 与 `IM` 模块已经模拟了少量的一周期读取延迟)

本 CPU 支持的指令：

```mips
add sub addu subu and or xor nor slt sltu sll srl sra sllv srlv srav
addi addiu andi ori xori lui slti sltiu
lw lh lhu lb lbu sw sh sb
beq bne bgez bltz bgtz blez bgezal bltzal
j jal jalr jr
mult multu div divu madd msub maddu msubu mfhi mflo mthi mtlo
clo clz movn movz
mfc0 mtc0 eret
```

## 测试方法

使用 MIPS 汇编语言模拟器软件 [MARS](http://courses.missouristate.edu/KenVollmar/MARS/) 将汇编程序导出为十六进制机器码，其中 `.text` 对应的机器码文件命名为 `code.txt`，`.ktext` (异常处理)部分的机器码文件命名为 `code_handler.txt` 并将这两个文件放置于工程目录下。使用任一种仿真工具进行仿真即可。

导出机器码命令参考(假设汇编程序文件名为 `sample.asm` ：

```batch
java -jar MARS.jar a nc mc CompactDataAtZero dump .text HexText code.txt sample.asm
java -jar MARS.jar a nc mc CompactDataAtZero dump 0x4180-0x4ffc HexText code_handler.txt sample.asm
```


汇编程序示例：

```mips
.text 0x3000
    ori     $2, $0, 0x1001
    mtc0    $2, $12
    ori     $28, $0, 0x0000
    ori     $29, $0, 0x0000
    lui     $8, 0x7fff
    lui     $9, 0x7fff
    add     $10, $8, $9 # OV Exception here
    or      $10, $8, $9

end:
    beq     $0, $0, end
    nop

.ktext 0x4180
_entry:
    mfc0    $k0, $14
    mfc0    $k1, $13
    ori     $k0, $0, 0x1000
    sw      $sp, -4($k0)
    
    addiu   $k0, $k0, -256
    move    $sp, $k0
    
    j       _save_context
    nop

_main_handler:
    mfc0    $k0, $13
    ori     $k1, $0, 0x007c
    and     $k0, $k1, $k0
    beq     $0, $k0, _restore_context
    nop
    mfc0    $k0, $14
    addu    $k0, $k0, 4
    mtc0    $k0, $14
    j       _restore_context
    nop

_restore:
    eret

_save_context:
    sw      $1, 4($sp)
    sw      $2, 8($sp)
    sw      $3, 12($sp)
    sw      $4, 16($sp)
    sw      $5, 20($sp)
    sw      $6, 24($sp)
    sw      $7, 28($sp)
    sw      $8, 32($sp)
    sw      $9, 36($sp)
    sw      $10, 40($sp)
    sw      $11, 44($sp)
    sw      $12, 48($sp)
    sw      $13, 52($sp)
    sw      $14, 56($sp)
    sw      $15, 60($sp)
    sw      $16, 64($sp)
    sw      $17, 68($sp)
    sw      $18, 72($sp)
    sw      $19, 76($sp)
    sw      $20, 80($sp)
    sw      $21, 84($sp)
    sw      $22, 88($sp)
    sw      $23, 92($sp)
    sw      $24, 96($sp)
    sw      $25, 100($sp)
    sw      $26, 104($sp)
    sw      $27, 108($sp)
    sw      $28, 112($sp)
    sw      $29, 116($sp)
    sw      $30, 120($sp)
    sw      $31, 124($sp)
    mfhi    $k0
    sw      $k0, 128($sp)
    mflo    $k0
    sw      $k0, 132($sp)
    j       _main_handler
    nop

_restore_context:
    lw      $1, 4($sp)
    lw      $2, 8($sp)
    lw      $3, 12($sp)
    lw      $4, 16($sp)
    lw      $5, 20($sp)
    lw      $6, 24($sp)
    lw      $7, 28($sp)
    lw      $8, 32($sp)
    lw      $9, 36($sp)
    lw      $10, 40($sp)
    lw      $11, 44($sp)
    lw      $12, 48($sp)
    lw      $13, 52($sp)
    lw      $14, 56($sp)
    lw      $15, 60($sp)
    lw      $16, 64($sp)
    lw      $17, 68($sp)
    lw      $18, 72($sp)
    lw      $19, 76($sp)
    lw      $20, 80($sp)
    lw      $21, 84($sp)
    lw      $22, 88($sp)
    lw      $23, 92($sp)
    lw      $24, 96($sp)
    lw      $25, 100($sp)
    lw      $26, 104($sp)
    lw      $27, 108($sp)
    lw      $28, 112($sp)
    lw      $29, 116($sp)
    lw      $30, 120($sp)
    lw      $31, 124($sp)
    lw      $k0, 128($sp)
    mthi    $k0
    lw      $k0, 132($sp)
    mtlo    $k0
    j       _restore
    nop
```