.section .text
.include "crt0.s"
.include "common.s"
.include "day01-data.s"


.arm
aoc_day01_part1:
	push {r1-r4}
	ldr r3, =day01_data_start
	ldr r4, =day01_data_end
	mov r0, #0
	ldr r1, [r3], #4
aoc_day01_part1_loop:
	ldr r2, [r3], #4
	cmp r2, r1
	addgt r0, #1
	mov r1, r2
	cmp r3, r4
	bne aoc_day01_part1_loop
	pop {r1-r4}
	bx lr
.pool


.arm
aoc_day01_part2:
	push {r1-r4}
	ldr r3, =day01_data_start
	ldr r4, =day01_data_end
	sub r4, #12
	mov r0, #0
aoc_day01_part2_loop:
	ldr r2, [r3, #12]
	ldr r1, [r3], #4
	cmp r2, r1
	addgt r0, #1
	mov r1, r2
	cmp r3, r4
	bne aoc_day01_part2_loop
	pop {r1-r4}
	bx lr
.pool


.arm
main:
	bl setup_for_display

	bl aoc_day01_part1
	mov r1, #0
	bl display_number

	bl aoc_day01_part2
	mov r1, #1
	bl display_number

spin_halt:
	b spin_halt
.pool
