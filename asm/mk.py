temp = '''addi ${0} ${0} {1}
sw ${0} {3}
lw ${2} {3}
'''
for i in range(5, 31):
    print(temp.format(i, i - 1, i + 1, i * 4))
