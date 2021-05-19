.text
# Display 2020 on Digital Tube
li $gp 0
li $sp 0x0ffc
j start
nop
digitalPrint:
sw $s0 0($sp)
addiu $sp $sp -4
li $s0 0x7f30
sw $a0 0($s0)
addiu $sp $sp 4
lw $s0 0($sp)
jr $ra
nop
start:
li $a0 0x1c121c12 # 2 0 2 0
jal digitalPrint
nop
end: 
beq $0, $0, end
nop

