.data
timertick: .word 0
timrunning: .word 0
timecount: .word 0
digit: .space 12 # 0 1 2 3 4 5 6 7 8 9 - - -
.text
# ------------ initialize ---------------
# li $t0 0x0401
li $t0 0x0001
mtc0 $t0 $12
li $gp 0x0000
li $sp 0x0ffc
# Initialize DM
la $s0 timertick
sw $0 0($s0)
la $s0 timrunning
sw $0 0($s0)
la $s0 timecount
sw $0 0($s0)
la $s0 digit
li $t0 0x12
sb $t0 0($s0)
li $t0 0xfa
sb $t0 1($s0)
li $t0 0x1c
sb $t0 2($s0)
li $t0 0x98
sb $t0 3($s0)
li $t0 0xf0
sb $t0 4($s0)
li $t0 0x91
sb $t0 5($s0)
li $t0 0x11
sb $t0 6($s0)
li $t0 0xda
sb $t0 7($s0)
li $t0 0x10
sb $t0 8($s0)
li $t0 0x90
sb $t0 9($s0)
j start
nop
# -------- function divmod(a0, a1) ---------
divmod:
# a0 / a1
beq $a1 $0 divmod_ret
nop
move $v1 $a0
li $v0 0
divloop:
blt $v1 $a1 divmod_ret # while (v1 < a1)
nop
subu $v1 $v1 $a1 # v1 -= a1
addiu $v0 $v0 1
j divloop
nop
divmod_ret: jr $ra 
nop
# -------- function dispdigit(a0) ---------
dispdigit:
li $t0 0
li $t1 4
li $t2 0
sw $ra 0($sp)
addiu $sp $sp -4
sw $a0 0($sp)
addiu $sp $sp -4
li $a1 10
dispdigit_loop:
beq $t1 $0 dispdigit_endloop # count 4
nop
jal divmod # v0, v1 = (a0 / 10), (a0 % 10)
nop
lbu $v1 digit($v1) # v1 = digit[v1]
sllv $v1 $v1 $t2
or $t0 $t0 $v1
move $a0 $v0
addiu $t2 $t2 8
addiu $t1 $t1 -1 # t1--
j dispdigit_loop
nop
dispdigit_endloop:
la $t1 0x7f30
sw $t0 0($t1) # write to digital tube
addiu $sp $sp 4
lw $a0 0($sp)
addiu $sp $sp 4
lw $ra 0($sp)
jr $ra
nop
# -------- function delay(a0) ---------
delay:
# Set Timer
li $s0 0x7f00
# 20ns * 50 = 1000ns = 1us
move $t0 $a0
# tmp1 = ((x << 3) + (x << 1))
# ans = (tmp << 2) + tmp
sll $t1 $t0 3
sll $t2 $t0 1
addu $t1 $t1 $t2 # (t0 << 3) + (t0 << 1) 
sll $t2 $t1 2
addu $t0 $t1 $t2 # (t1 << 2) + t1
sw $t0 4($s0)
li $t0 9
sw $t0 0($s0)
sw $0 timertick
_delay_loop:
lw $t0 timertick
beq $t0 $0 _delay_loop
nop
sw $0 0($s0)
jr $ra
nop


start:
# -------------- Welcome --------------------
li $t0 0x0401
mtc0 $t0 $12
li $a0 2020
jal dispdigit
nop
li $a0 2000000
jal delay
nop
# 'b': 00110001 0x31 'U': 00110010 0x32 'A': 01010000 0x50
li $t0 0x31325050 # BUAA
li $s0 0x7f30
sw $t0 0($s0) 
li $a0 2000000
jal delay
nop
# 'C': 00010111 0x17 'O': 00010010 0x12
li $t0 0x17121712
li $s0 0x7f30
sw $t0 0($s0)
li $a0 2000000
jal delay
nop

# -------- main program start point ---------
li $t0 0x1401
mtc0 $t0 $12
# start timer
li $s0 0x7f00
li $t0 50000000 # 1s
sw $t0 4($s0)
li $t0 9
sw $t0 0($s0) # start timer
li $t0 1
sw $t0 timrunning

end: beq $0, $0, end
nop
.ktext 0x4180
_entry:
mfc0 $k0 $13 # cause
addiu $sp $sp -36 # t6, t7, t8, t9, ra, sp, at, a0, a1
j _save_context
nop
_main_handler:
mfc0 $k0 $13 # cause
andi $k1 $k0 0x400 # cause & (HWInt[2])
bne $k1 $0 _timer_handler
nop
andi $k1 $k0 0x1000 # cause & (HWInt[4])
bne $k1 $0 _switch_handler
nop
j _restore_context
nop
_timer_handler:
# Stop Timer
li $t9 0x7f00
sw $0 0($t9)
# Set Global Flag
la $t9 timertick
li $t8 1
sw $t8 0($t9)
# check timrunning
lw $t8 timrunning
beq $t8 $0 _restore_context
nop
# Restart Timer
sw $0 timertick
li $t9 0x7f00
li $t8 9
sw $t8 0($t9)
# display count
lw $a0 timecount
addiu $a0 $a0 1
sw $a0 timecount
jal dispdigit
nop
j _restore_context
nop
_switch_handler: 
li $t9 0x7f40
lw $t9 0($t9)
andi $t8 $t9 0x1
bne $t8 $0 _switch_1
nop
andi $t8 $t9 0x2
bne $t8 $0 _switch_2
nop
j _restore_context
nop
_switch_1:  # !!!!!!!!!!!!!!!!!!!!!!!!!!
lw $t9 timrunning
li $t8 1
subu $t9 $t8 $t9 # timrunning = 1 - timrunning
sw $t9 timrunning
# if (timrunning == 1) restart timer
beq $t9 $0 _restore_context
nop
li $t9 0x7f00
li $t8 9
sw $t8 0($t9) # restart timer
j _restore_context
nop
_switch_2: 
sw $0 timecount
j _restore_context
nop
_save_context:
sw $t6 4($sp)
sw $t7 8($sp)
sw $t8 12($sp)
sw $t9 16($sp)
sw $sp 20($sp)
sw $ra 24($sp)
sw $at 28($sp)
sw $a0 32($sp)
sw $a1 36($sp)
j _main_handler
nop

_restore_context:
lw $a1 36($sp)
lw $a0 32($sp)
lw $at 28($sp)
lw $ra 24($sp)
lw $sp 20($sp)
lw $t9 16($sp)
lw $t8 12($sp)
lw $t7 8($sp)
lw $t6 4($sp)
j _restore
nop
_restore:
addiu $sp $sp 36
eret

