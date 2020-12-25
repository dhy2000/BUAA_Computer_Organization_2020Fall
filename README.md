# P8 on FPGA

由于计组课设取消了 P8，所以用自己的 FPGA 板子做了一下 CPU 的简单上板验证。

采用的 FPGA 型号为 Altera Cyclone IV ，开发环境为 Altera 的 Quartus，仿真软件采用 Modelsim.

计组课设所做 CPU 在上板验证前需要将 IM (指令存储器) 和 DM (数据存储器) 替换成相应的 ipcore (DM 用 BlockRAM, IM 用 BlockROM) ，不能直接用原来的寄存器数组的写法。

由于本人所写的 CPU 硬件延迟较长，担心直接采用板载时钟可能出错，并且由于 BlockRAM 读写数据的时序与 reg 写的 DM 有差别（BlockRAM 数据读出端口有寄存器），所以对板载的时钟进行了分频，分出一个较慢的时钟给 CPU ，并且使得给存储器的时钟频率是给 CPU 的时钟频率的两倍（这样在 CPU 视角下读数据的时序没有变化，依旧可以看作"组合逻辑"）。感谢计组助教 [VOIDMalkuth](https://github.com/VOIDMalkuth) 讲解 ipcore 的使用与时钟分频技巧。

另外由于自己的板子逻辑门资源较少，在 P7 基础上添加上外设后综合出的逻辑门数量超过限制，不得不删掉 P6 的乘除法器，并且 P7 的两个 Timer 只保留了一个。最终综合结果逻辑门数量为 6272 / 6292 。

该 project 距离真正的计组课设 P8 实验仍然有很大的差距，例如受限于逻辑门数量的限制而没有实现串口通信（串口通信是 P8 实验非常重要的内容之一），并且采用的开发工具是 Altera Quartus 而非计组的 Xilinx ISE ，因此对以后届的参考价值不大。