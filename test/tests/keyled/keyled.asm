# Key Control LED
.data
timertick: .word
.text
li $gp 0
li $sp 0x0ffc
li $t0 0x1401 # timer0 and switch interrupt enable
mtc0 $t0 $12 # write SR
j start
nop
led_op: # a1 == 0: on, a1 == 1: off, a1 == 2: toggle
sw $a0 0($sp)
addiu $sp $sp -4
sw $a1 0($sp)
addiu $sp $sp -4
# a0 = 0, 1, 2, 3
andi $a0 $a0 0x3
li $t0 1
sllv $t0 $t0 $a0
li $t2 0x7f20 # LED
lw $t1 0($t2)
# check $a1
beq $a1 $0 _ledon
addiu $a1 $a1 -1
beq $a1 $0 _ledoff
addiu $a1 $a1 -1
beq $a1 $0 _ledtoggle
nop
j _end_led_op
nop
_ledon:
or $t1 $t0 $t1
j _end_led_op
nop
_ledoff:
not $t0 $t0
and $t1 $t0 $t1
j _end_led_op
nop
_ledtoggle:
xor $t1 $t0 $t1
_end_led_op: 
sw $t1 0($t2)
addiu $sp $sp 4
lw $a1 0($sp)
addiu $sp $sp 4
lw $a0 0($sp)
jr $ra
nop
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
la $s0 timertick
_delay_loop:
lw $t0 0($s0)
beq $t0 $0 _delay_loop
nop
sw $0 0($s0)
jr $ra
nop
start:
li $a0 0
li $a1 0
jal led_op
nop
li $a0 2
li $a1 2
jal led_op
nop
li $a0 3
li $a1 0
jal led_op
nop
li $a0 0
li $a1 1
jal led_op
nop
li $a0 1000000
jal delay
nop
li $a0 2
li $a1 2
jal led_op
nop
li $a0 1000000
jal delay
nop
li $a0 3
li $a1 2
jal led_op
nop
end: beq $0 $0 end
nop

.ktext 0x4180
_entry:
mfc0 $k0 $13 # cause
addiu $sp $sp -28 # t6, t7, t8, t9, ra, sp
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
j _restore_context
nop
_switch_handler: 
li $t9 0x7f40
lw $t8 0($t9)
# load LED
li $t9 0x7f20
lw $t7 0($t9)
# toggle LED
xor $t7 $t7 $t8
sw $t7 0($t9)
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
j _main_handler
nop

_restore_context:
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
addiu $sp $sp 28
eret
