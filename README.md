# P8 MIPS 微系统+ (板级验证)

由于今年没有 P8 了，所以用自己的板子做个 P8 试试看

注：该分支仅用作添加外设后的功能仿真，真正用于 FPGA 验证的**可综合**版本位于 `P8_fpga` 分支。

## 地址空间映射

| 名称                       | 地址范围          |
| -------------------------- | ----------------- |
| 数据存储器                 | `0x0000 - 0x2fff` |
| 指令存储器                 | `0x3000 - 0x4fff` |
| PC 初始值                  | `0x3000`          |
| Exception Handler 初始地址 | `0x4180`          |
| 定时器                     | `0x7F00 - 0x7F0B` |
| LED                        | `0x7F20`          |
| 数码管                     | `0x7F30`          |
| 按钮开关                   | `0x7F40`          |
| 蜂鸣器                     | `0x7F50 - 0x7F5B` |

