and $gp $gp $0
and $sp $sp $0
#########################
# test lw/sw addi subi ori
lui $0 0xbaad
ori $0 0xf00d
lui $1 0xface
ori $1 0xc001
sw $1 4
lw $2 4
addi $2 $2 1
sw $2 8
lw $3 8
addi $3 $3 2
sw $3 12
lw $4 12

addi $4 $4 3
sw $4 16
lw $5 16

addi $5 $5 4
sw $5 20
lw $6 20

addi $6 $6 5
sw $6 24
lw $7 24

addi $7 $7 6
sw $7 28
lw $8 28

addi $8 $8 7
sw $8 32
lw $9 32

addi $9 $9 8
sw $9 36
lw $10 36

addi $10 $10 9
sw $10 40
lw $11 40

addi $11 $11 10
sw $11 44
lw $12 44

addi $12 $12 11
sw $12 48
lw $13 48

addi $13 $13 12
sw $13 52
lw $14 52

addi $14 $14 13
sw $14 56
lw $15 56

addi $15 $15 14
sw $15 60
lw $16 60

addi $16 $16 15
sw $16 64
lw $17 64

addi $17 $17 16
sw $17 68
lw $18 68

addi $18 $18 17
sw $18 72
lw $19 72

addi $19 $19 18
sw $19 76
lw $20 76

addi $20 $20 19
sw $20 80
lw $21 80

addi $21 $21 20
sw $21 84
lw $22 84

addi $22 $22 21
sw $22 88
lw $23 88

addi $23 $23 22
sw $23 92
lw $24 92

addi $24 $24 23
sw $24 96
lw $25 96

addi $25 $25 24
sw $25 100
lw $26 100

addi $26 $26 25
sw $26 104
lw $27 104

addi $27 $27 26
sw $27 108
lw $28 108

addi $28 $28 27
sw $28 112
lw $29 112

addi $29 $29 28
sw $29 116
lw $30 116

addi $30 $30 29
sw $30 120
lw $31 120

addi $31 $31 30
sw $31 124

