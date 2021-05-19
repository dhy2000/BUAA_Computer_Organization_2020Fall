.data
timertick: .word 0
digit: .space 12
songnotenum: .word 0
songnotes: .space 24 # do re me nul fa sol
songdur: .space 24 # 1s 2s 1s 1s 2s 1s #(basic unit: us)
.text
# ------------ initialize ---------------
li $t0 0x0001
mtc0 $t0 $12
li $gp 0x0000
li $sp 0x0ffc
# Initialize DM
la $s0 timertick
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
la $s0 songnotenum
li $t0 6
sw $t0 0($s0)
la $s0 songnotes
li $t0 532
sw $t0 0($s0)
li $t0 587
sw $t0 4($s0)
li $t0 659
sw $t0 8($s0)
li $t0 0
sw $t0 12($s0)
li $t0 698
sw $t0 16($s0)
li $t0 783
sw $t0 20($s0)
la $s0 songdur
li $t0 1000000
sw $t0 0($s0)
li $t0 2000000
sw $t0 4($s0)
li $t0 1000000
sw $t0 8($s0)
li $t0 1000000
sw $t0 12($s0)
li $t0 2000000
sw $t0 16($s0)
li $t0 1000000
sw $t0 20($s0)
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
# -------- function delay(a0) ---------
delay:
sw $s0 0($sp) 
addiu $sp $sp -4
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
addiu $sp $sp 4
lw $s0 0($sp)
jr $ra
nop
# ---------- task playsong() ----------
playsong:
sw $ra 0($sp)
addiu $sp $sp -4
sw $s0 0($sp)
addiu $sp $sp -4
li $s0 0
_playsong_loop: 
    # load tune
    sll $t0 $s0 2
    lw $t1 songnotes($t0) # load note
    beq $t1 $0 _playsong_notedelay
    addiu $s0 $s0 1 # delay slot
    # control buzzer
    li $t2 0x7f50 # &buzzer
    sw $t1 4($t2)
    lw $t1 songdur($t0)
    sll $t3 $t1 3
    sll $t1 $t1 1
    addu $t1 $t1 $t3 # t1 = t1 * 10
    sll $t3 $t1 2
    addu $t1 $t1 $t3 # t1 = t1 * 5
    sw $t1 8($t2)
    li $t1 1
    sw $t1 0($t2) # start
    _playsong_notedelay:
    lw $a0 songdur($t0) # load duration
    jal delay
    nop
    # next s0
    # -- addiu $s0 $s0 1
    lw $t0 songnotenum
    bne $s0 $t0 _playsong_loop
    nop
addiu $sp $sp 4
lw $s0 0($sp)
addiu $sp $sp 4
lw $ra 0($sp)
jr $ra
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
start:
# ---------- Welcome ---------
li $t0 0x0401
mtc0 $t0 $12
li $a0 2020
jal dispdigit
nop
li $a0 1000000
jal delay
nop
# 'C': 00010111 0x17 'O': 00010010 0x12
li $t0 0x17121712 # COCO
li $s0 0x7f30
sw $t0 0($s0)
li $a0 2000000
jal delay
nop
# -------- main program start point ---------
li $t0 0x1401
mtc0 $t0 $12
li $t0 0xefefefef
sw $s0 0x7f30
sw $t0 0($s0)
jal playsong # start play song
nop
li $t0 0xffffffff
sw $s0 0x7f30
sw $t0 0($s0)
end: beq $0 $0 end
nop

.ktext 0x4180
_entry:
mfc0 $k0 $13
addiu $sp $sp -124 # 1 - 31 register
j _save_context
nop

_main_handler:
mfc0 $k0 $13 # cause
andi $k1 $k0 0x400 # cause & (HWInt[2])
bne $k1 $0 _timer_handler
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
j _restore_context
nop
_save_context:
sw $1 4($sp)
sw $2 8($sp)
sw $3 12($sp)
sw $4 16($sp)
sw $5 20($sp)
sw $6 24($sp)
sw $7 28($sp)
sw $8 32($sp)
sw $9 36($sp)
sw $10 40($sp)
sw $11 44($sp)
sw $12 48($sp)
sw $13 52($sp)
sw $14 56($sp)
sw $15 60($sp)
sw $16 64($sp)
sw $17 68($sp)
sw $18 72($sp)
sw $19 76($sp)
sw $20 80($sp)
sw $21 84($sp)
sw $22 88($sp)
sw $23 92($sp)
sw $24 96($sp)
sw $25 100($sp)
sw $26 104($sp)
sw $27 108($sp)
sw $28 112($sp)
sw $29 116($sp)
sw $30 120($sp)
sw $31 124($sp)
j _main_handler
nop

_restore_context:
lw $1 4($sp)
lw $2 8($sp)
lw $3 12($sp)
lw $4 16($sp)
lw $5 20($sp)
lw $6 24($sp)
lw $7 28($sp)
lw $8 32($sp)
lw $9 36($sp)
lw $10 40($sp)
lw $11 44($sp)
lw $12 48($sp)
lw $13 52($sp)
lw $14 56($sp)
lw $15 60($sp)
lw $16 64($sp)
lw $17 68($sp)
lw $18 72($sp)
lw $19 76($sp)
lw $20 80($sp)
lw $21 84($sp)
lw $22 88($sp)
lw $23 92($sp)
lw $24 96($sp)
lw $25 100($sp)
lw $26 104($sp)
lw $27 108($sp)
lw $28 112($sp)
lw $29 116($sp)
lw $30 120($sp)
lw $31 124($sp)
j _restore
nop
_restore:
addiu $sp $sp 124
eret
