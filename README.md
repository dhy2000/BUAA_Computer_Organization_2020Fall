# 临时分支

## TODO

1. 将 PCToLink 信号从 NPC 模块加回来 
2. 在流水线中加入 RegWriteData 信号，在流水过每一级时更新该信号 (PCToLink@ID, AluOut@EX, MemReadData@MEM)
3. WB 级不需要额外的选择了，WB 级的顶层模块可以直接去掉，将 MEM/WB 寄存器的输出信号直接连到 GRF 中即可.
4. 每一级对所有的部件进行套壳，流水寄存器的信号数和每一级部件的套壳数一一对应。
5. 流水寄存器直接套进每层的壳内。