# 临时分支

## TODO

1. 将 PCToLink 信号从 NPC 模块加回来 
2. 在流水线中加入 RegWriteData 信号，在流水过每一级时更新该信号 (PCToLink@ID, AluOut@EX, MemReadData@MEM)
3. WB 级不需要额外的选择了，WB 级的顶层模块可以直接去掉，将 MEM/WB 寄存器的输出信号直接连到 GRF 中即可。(commit)
4. 将 NPC 模块移动到 ID 级别 (commit)