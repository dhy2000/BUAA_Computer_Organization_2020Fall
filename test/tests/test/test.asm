.data
timertick: .word 0
codecur: .word 0
correctflag: .word 0 # 0 or 1
songnotenum: .word 0
digit: .space 12 # 0-9, extra 2 to align word
numcode: .space 4 # 4 digits
codecorrect: .space 4 # 4 digits answer
songnotes: .space 132 # songnotenum * 4
songdur: .space 132 # songnotenum * 4

.text
# ------------ initialize ---------------
li $t0 0x0001
mtc0 $t0 $12
li $gp 0x0000
li $sp 0x0ffc
# Initialize DM
sw $0 timertick # variables
sw $0 codecur
sw $0 correctflag
li $t0 33
sw $t0 songnotenum
# arrays
sw $0 codecorrect # char[4] as word
li $t0 0xffffffff # -1 -1 -1 -1
sw $t0 numcode # char[4] array, as a word
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
# songnotes
li $t0 784
sw $t0 songnotes+0
sw $t0 songnotes+4
sw $t0 songnotes+12
sw $t0 songnotes+28
sw $t0 songnotes+32
sw $t0 songnotes+40
sw $t0 songnotes+56
sw $t0 songnotes+60
li $t0 880
sw $t0 songnotes+8
sw $t0 songnotes+36
sw $t0 songnotes+80
li $t0 988
sw $t0 songnotes+20
sw $t0 songnotes+76
li $t0 1046
sw $t0 songnotes+16
sw $t0 songnotes+48
sw $t0 songnotes+72
sw $t0 songnotes+100
sw $t0 songnotes+108
li $t0 1175
sw $t0 songnotes+44
sw $t0 songnotes+104
li $t0 1318
sw $t0 songnotes+68
sw $t0 songnotes+96
li $t0 1397
sw $t0 songnotes+88
sw $t0 songnotes+92
li $t0 1568
sw $t0 songnotes+64
sw $0 songnotes+24
sw $0 songnotes+52
sw $0 songnotes+84
sw $0 songnotes+112
# songdur
li $t0  600000
sw $t0 songdur+0
sw $t0 songdur+8
sw $t0 songdur+12
sw $t0 songdur+16
sw $t0 songdur+28
sw $t0 songdur+36
sw $t0 songdur+40
sw $t0 songdur+44
sw $t0 songdur+56
sw $t0 songdur+64
sw $t0 songdur+68
sw $t0 songdur+72
sw $t0 songdur+76
sw $t0 songdur+88
sw $t0 songdur+96
sw $t0 songdur+100
sw $t0 songdur+104
li $t0  200000
sw $t0 songdur+4
sw $t0 songdur+32
sw $t0 songdur+60
sw $t0 songdur+92
li $t0  600000
sw $t0 songdur+20
sw $t0 songdur+48
sw $t0 songdur+80
sw $t0 songdur+108
li $t0  800000
sw $t0 songdur+24
sw $t0 songdur+52
sw $t0 songdur+84
sw $t0 songdur+112
j start 
nop
# -------- task delay(a0) ---------
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
# ---------- task digitprint() ------------
digitprint:
    sw $s0 0($sp)
    addiu $sp $sp -4
    sw $s1 0($sp)
    addiu $sp $sp -4
    # [c0][c1][c2][c3]
    li $s0 0
    li $s1 0
    _digitprint_loop:
        lb $t0 numcode($s0) # t0 = numcode[s0]
        # if (t0 == -1) skip
        sll $s1 $s1 8
        ori $s1 $s1 0xff
        bltz $t0 _digitprint_loop_next
        nop
        lbu $t0 digit($t0)
        xori $s1 $s1 0xff # let s1[7:0] = 0
        or $s1 $s1 $t0
        # next i
        _digitprint_loop_next:
        addiu $s0 $s0 1
        li $t1 4
        bne $s0 $t1 _digitprint_loop
        nop
    # add dot
    li $t0 0x10
    lw $t1 codecur
    li $t2 3
    subu $t1 $t2 $t1 # t1 = 3 - codecur
    sll $t1 $t1 3 # t1 *= 8
    sllv $t0 $t0 $t1 # t0 <<= (8 * t1)
    nor $t0 $t0 $0
    and $s1 $s1 $t0 # s1 &= t0, add dot at cursor
    # display output
    li $s0 0x7f30
    sw $s1 0($s0)
    addiu $sp $sp 4
    lw $s1 0($sp)
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
        # srl $t1 $t1 1 # XXXXXXXXXX
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
start:
# ---------- Welcome ---------
li $t0 0x0401
mtc0 $t0 $12
# blink all LED once
li $t0 0
li $s0 0x7f20
sw $t0 0($s0)
li $a0 1000000
jal delay
nop
li $t0 0xf
sw $t0 0($s0)
jal delay
nop
# display digital tube
li $t0 0x1c121c12 # 2020
li $s0 0x7f30
sw $t0 0($s0)
li $a0 1000000
jal delay
nop
# 'b': 00110001 0x31 'U': 00110010 0x32 'A': 01010000 0x50
li $t0 0x31325050 # BUAA
li $s0 0x7f30
sw $t0 0($s0) 
li $a0 500000
jal delay
nop
li $t0 0x17121712
li $s0 0x7f30
sw $t0 0($s0)
li $a0 500000
jal delay
nop
# -------- main program start point ---------
li $t0 0x1401
mtc0 $t0 $12
# initialize digital tube
jal digitprint
nop
# set correct code
li $t0 0x01030201
sw $t0 codecorrect
# loop until the correct code is entered
untilloop:
    lw $t0 correctflag
    beq $t0 $0 untilloop
    nop

# disable button interrupt
li $t0 0x0401
mtc0 $t0 $12
repeatinf:
li $t0 0xf
li $s0 0x7f20
sw $t0 0($s0) # off led
# Print 2021
li $t0 0x1c121cfa
li $s0 0x7f30
sw $t0 0($s0)
li $a0 1000000
jal delay
nop
# Count 3
li $t0 0xffffffff
sw $t0 numcode
sw $0 codecur
li $s1 3
countloop:
    # display digital tube
    sb $s1 numcode
    jal digitprint
    nop
    # delay
    li $a0 1000000
    jal delay
    nop
    # minus
    addiu $s1 $s1 -1
    bgtz $s1 countloop
    nop

# -!!!!!!!! TODO !!!!!!!!-
# Digital Tube
li $t0 0x71507150 # hAhA
li $s0 0x7f30
sw $t0 0($s0)
# LED
li $t0 0x8
li $s0 0x7f20
sw $t0 0($s0)
jal playsong
nop
j repeatinf
nop
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
    lw $t9 0($t9)
    andi $t8 $t9 0x1
    bne $t8 $0 _switch_1
    nop
    andi $t8 $t9 0x2
    bne $t8 $0 _switch_2
    nop
    andi $t8 $t9 0x4
    bne $t8 $0 _switch_3
    nop
    andi $t8 $t9 0x8
    bne $t8 $0 _switch_4
    nop 
    j _restore_context
    nop
    _switch_1: # add 1 to the current code
        lw $t9 codecur
        lbu $t8 numcode($t9)
        addiu $t8 $t8 1
        # if (t8 >= 10) t8 = 0
        li $t7 10
        blt $t8 $t7 _update_numcode
        nop
        li $t8 0
        _update_numcode:
        sb $t8 numcode($t9)
        jal digitprint
        nop
        j _restore_context
        nop
    _switch_2: # right shift the cursor
        lw $t9 codecur
        li $t8 4
        addiu $t9 $t9 1
        bne $t9 $t8 _update_cursor # if (codecur == 4) codecur = 0
        nop
        li $t9 0
        _update_cursor:
        sw $t9 codecur
        jal digitprint
        nop
        j _restore_context
        nop
    _switch_3: # clear all
        sw $0 codecur
        li $t9 0xffffffff
        sw $t9 numcode
        jal digitprint
        nop
        j _restore_context
        nop
    _switch_4: # submit
        lw $t9 numcode
        lw $t8 codecorrect
        bne $t8 $t9 _restore_context
        nop
        # succeed
        li $t8 1
        sw $t8 correctflag
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
