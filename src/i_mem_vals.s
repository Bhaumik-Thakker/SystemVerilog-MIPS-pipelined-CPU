.text 
# Corner-Case Stress Test for HW11 Cache
# Uses MIPS register names
# $at  = loop counter / temp
# $v0  = main accumulator
# $v1  = secondary accumulator
# $a0  = temp
# $a1  = accumulator for replacement section

###################################################
# Block A: Warm-up – straight-line code (misses)
###################################################

        addi $at, $zero, 0       # 0x00: clear at
        addi $v0, $zero, 0       # 0x04: clear v0
        addi $v1, $zero, 0       # 0x08: clear v1
        addi $a0, $zero, 0       # 0x0C: clear a0

###################################################
# Block B: Loop1 – taken loop (many hits)
###################################################
# Loop1 body at PCs 0x10,0x14,0x18,0x1C
# First time: misses; later iterations: hits.

        addi $at, $zero, 8       # 0x10: at = 8  (loop1 count)

LOOP1:  addi $v0, $v0, 3         # 0x14: v0 += 3
        addi $v0, $v0, 2         # 0x18: v0 += 2
        addi $at, $at, -1        # 0x1C: at--
        bne  $at, $zero, LOOP1   # 0x20: branch back to 0x14 while at!=0

# After LOOP1: v0 = 8 * (3+2) = 40, at = 0

###################################################
# Block C: Non-taken and taken branches
###################################################
# Non-taken BEQ, then taken BEQ to SKIP2

        addi $v1, $zero, 5       # 0x24: v1 = 5
        beq  $v1, $zero, SKIP1   # 0x28: not taken
        addi $v0, $v0, 10        # 0x2C: executes once, v0 = 50

SKIP1:  beq  $v0, $zero, SKIP2   # 0x30: not taken (v0 != 0)
        addi $v0, $v0, 1         # 0x34: v0 = 51
SKIP2:

###################################################
# Block D: Miss + immediate branch interaction
###################################################
# Force a miss at MISS1, then a branch right after.
# We want: only MISS1 triggers miss handling.

MISS1:  addi $v0, $v0, 1         # 0x38: v0 = 52, should miss on first fetch
        bne  $v1, $zero, AFTER_MISS1  # 0x3C: taken (v1=5), branch after miss

AFTER_MISS1:
        addi $v0, $v0, 2         # 0x40: v0 = 54

###################################################
# Block E: Fill cache and cause replacements
###################################################
# Fill: a1 = 100, then several adds to cause multiple writes
# These PC addresses should both fill and then replace.

        addi $a1, $zero, 100     # 0x44: a1 = 100   (new PC => miss)
        addi $a1, $a1, 10        # 0x48: a1 += 10
        addi $a1, $a1, 10        # 0x4C: a1 += 10
        addi $a1, $a1, 10        # 0x50: a1 += 10
        addi $a1, $a1, 10        # 0x54: a1 += 10
        addi $a1, $a1, 10        # 0x58: a1 += 10
        addi $a1, $a1, 10        # 0x5C: a1 += 10
        addi $a1, $a1, 10        # 0x60: a1 += 10

# After Block E: a1 = 100 + 7*10 = 170

###################################################
# Block F: Loop2 – second loop to re-hit cache
###################################################
# Another loop on small body; stresses hit behavior after replacements.

        addi $at, $zero, 4       # 0x64: at = 4

LOOP2:  addi $v0, $v0, 1         # 0x68: v0++
        addi $at, $at, -1        # 0x6C: at--
        bne  $at, $zero, LOOP2   # 0x70: loop 4 times

# After LOOP2: v0 = 54 + 4 = 58

###################################################
# Block G: Miss followed by HALT (halt-in-stall corner)
###################################################
# Force a new miss at MISS2, then HALT immediately after.
# Expect: cache_stall causes NOPs, then HALT executes once.

MISS2:  addi $v0, $v0, 1         # 0x74: v0 = 59, new PC → miss
        halt                     # 0x78



