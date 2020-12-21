# P8 MIPS 微系统+ (板级验证)

由于今年没有 P8 了，所以用自己的板子做个 P8 试试看

## TODO

1. 将 IM 从 CPU 中分离到桥上
2. 将复位信号改成与板载相同的系统复位 `rst_n` (低电平有效)
3. 添加目前已经支持的外设(连到南桥上)
4. 编写一个简单的小工具用来从 `code.txt` 和 `code_handler.txt` 合并成一个 `instr.hex` 文件
5. 将 IM 和 DM 替换成 ROM 和 BlockRAM 
6. 综合 MIPS 微系统，修复编译错误和不可综合。
7. 编写简单的软件来验证微系统(注意自己写的软件尽量不要有异常, 要自觉遵守什么地址能读/写)
8. 设定分频时钟
9. 上板验证！

如果有时间的话，从往届的 github 上找一下高老师写的 UART 驱动文件，直接嫖来用。

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

