# Fibnacci Recursion
.text

# Read n
li $v0 5
syscall # $v0 = n
# fib(n)
move $a0 $v0 # set $a0 = $v0
jal Fib
# print ans
move $a0 $v0
li $v0 1
syscall
Exit:
li $v0 10
syscall

# ------ $v0 = fib(n: $a0) ------ 
Fib:
# Convert If Statement
    li $t1 2 # let $t1 = 2
    bgt $a0 $t1 recursion # if (a0 >= 2) Fib() + Fib()
    # return 1
    li $v0 1
    jr $ra # return ;

recursion:
    # call Fib(n - 1)
    # Stage $a0 and $ra
    sw $a0 0($sp) # store n($a0)
    subi $sp $sp 4
    sw $ra 0($sp) # store $ra
    subi $sp $sp 4
    # Fib(n - 1)
    subi $a0 $a0 1 # (n - 1)
    jal Fib 
    # Returned
    addi $sp $sp 4
    lw $ra 0($sp)
    addi $sp $sp 4
    lw $a0 0($sp)
    # $s1 = fib(n - 1)
    move $s1 $v0
    
    # call Fib(n - 2)
    # Stage $s1 $a0 $ra
    sw $s1 0($sp)
    subi $sp $sp 4
    sw $a0 0($sp)
    subi $sp $sp 4
    sw $ra 0($sp)
    subi $sp $sp 4
    # Fib(n - 2)
    subi $a0 $a0 2
    jal Fib
    # Returned
    addi $sp $sp 4
    lw $ra 0($sp)
    addi $sp $sp 4
    lw $a0 0($sp)
    addi $sp $sp 4
    lw $s1 0($sp)
    # $v0 = Fib(n - 2)
# final return: return $s1 + $v0
add $v0 $v0 $s1
jr $ra
