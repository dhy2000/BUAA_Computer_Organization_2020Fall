# P3课下 试水

P3课下需要支持的指令集： `{addu, subu, ori, lw, sw, beq, lui, nop}`

自己补充的指令：读写类 `lb, lbu, lh, lhu, sh, sb` ，跳转类 `j jal jalr jr` 

分支类： `bgez bltz bne bnez` 

计算类：`add sub and or`。

## 开发日志

- P0课下周：初步构造了CPU，访存八条指令都加上了，算术指令只有加减，跳转全加上了，分支只加了bne和beq。（在课下要求的几条指令的基础上加了全部的访存，加了全部的跳转）

- 2020.10.26 

  - TODOs
  - [x] 重新改一下ALU，把所有的移位指令单独分离出来，分到自己封装的移位器里面。
  - [x] 把运算类R型和I型指令加上。
  - [x] 将移位器加入数据通路当中。

  - Dones

  - [x] 重构了ALU，去除了移位运算，重新安排了顺序。
  - [x] 重构Control单元，增加了对指令的中间分类，重新排布了电路。
  - [x] 重构了辅助建模Control Unit的Excel表格。
  - [x] 将准备加的指令添加到表格中。
  - [x] 测试一下重构之后的CPU有没有Bug！！！！(OK)
  - [x] 将准备加的指令添加到Control单元中。
  - [x] 扩展Control单元的输出信号
  - [x] 扩展CPU中对移位指令的数据通路
  - [x] 编写了处理Logisim RAM输出内容的C程序（将不规整的输出内容整理成一字一行，方便对拍）
  - [x] 测出来了bgez的BUG！！！（已修复）
  - [x] 测出来了jalr的数据通路错误！！！建模时对jalr指令理解有误（已修复）
  - [x] 测出并修复了sltu和sltiu的错误（对指令理解有误）



## 支持的指令

### 运算类(普通R型)

- [x] add/addu
- [x] sub/subu
- [x] slt
- [x] sltu
- [x] and
- [x] or
- [x] xor
- [x] nor
- [ ] 

### 运算类-移位指令

- [x] sll
- [x] srl
- [x] sra
- [x] sllv
- [x] srlv
- [x] srav
- [ ] 



### 运算类(立即数)

- [x] lui
- [x] ori
- [x] addi
- [x] andi
- [x] xori
- [x] slti/sltiu



### 访存类

- [x] lw
- [x] sw
- [x] lb
- [x] sb
- [x] lh
- [x] sh
- [x] lbu
- [x] lhu



### 跳转类

- [x] j
- [x] jal
- [x] jr
- [x] jalr

### 分支类

- [x] beq
- [x] bne
- [x] bgez
- [x] bgtz
- [x] blez
- [x] bltz



