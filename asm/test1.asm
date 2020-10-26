#################
lui $t1 0x1234
ori $t1 0x5678
sw $t1 0
lw $t2 0
addi $t2 $t2 1
sw $t2 4
# branch
# test beq
ori $t3 3
ori $t4 4
beq $t3 $t4 b2
b1: sw $t3 8
j end1
b2: sw $t4 8
end1:
ori $s1 5
ori $s2 5
beq $s1 $s2 bb2
bb1: sw $s1 12
bb2: sw $s1 16
