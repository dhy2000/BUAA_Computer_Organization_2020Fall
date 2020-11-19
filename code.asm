lui    $t1, 4660
ori    $t1, $t1, 22136
sw     $t1, 0($0)
lw     $t2, 0($0)
addi   $t2, $t2, 1
sw     $t2, 4($0)
ori    $t3, $t3, 3
ori    $t4, $t4, 4
beq    $t3, $t4, L1
sw     $t3, 8($0)
j      L2
L1:sw     $t4, 8($0)
L2:ori    $s1, $s1, 5
ori    $s2, $s2, 5
bne    $s1, $s2, L3
sw     $s1, 12($0)
L3:sw     $s1, 16($0)
addi   $s5, $0, 0
addi   $s6, $0, 10
L6:beq    $s5, $s6, L4
add    $a0, $s5, $0
jal    L5
add    $s5, $v0, $0
j      L6
L5:addi   $v0, $a0, 1
sb     $a0, 32($a0)
jr     $ra
L4:sw     $s5, 20($0)
