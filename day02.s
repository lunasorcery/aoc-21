.section .text
.include "crt0.s"
.include "common.s"
.include "day02-data.s"


arm_fn
aoc_day02_part1:
	push {r1-r5}

	ldr r4, =day02_data_start
	ldr r5, =day02_data_end

	mov r2, #0 @ depth
	mov r3, #0 @ horizontal

	p1_loop_per_line:
		ldrb r0, [r4], #1 @ load first char of line

		p1_loop_to_end_of_line:
			ldrb r1, [r4], #1 @ read a char and advance
			cmp r1, #0 @ loop until we've read a zero
		bne p1_loop_to_end_of_line

		ldrb r1, [r4, #-2] @ load last char of line
		sub r1, #0x30 @ ascii to int

		cmp r0, #'d'
		addeq r2, r1
		cmp r0, #'u'
		subeq r2, r1
		cmp r0, #'f'
		addeq r3, r1

		cmp r4, r5 @ have we reached the end of the data?
	bne p1_loop_per_line

	@ multiply depth by horizontal to get result
	mul r0, r2, r3

	pop {r1-r5}
	bx lr
.pool



arm_fn
aoc_day02_part2:
	push {r1-r6}

	ldr r4, =day02_data_start
	ldr r5, =day02_data_end

	mov r2, #0 @ depth
	mov r3, #0 @ horizontal
	mov r6, #0 @ aim

	p2_loop_per_line:
		ldrb r0, [r4], #1 @ load first char of line

		p2_loop_to_end_of_line:
			ldrb r1, [r4], #1 @ read a char and advance
			cmp r1, #0 @ loop until we've read a zero
		bne p2_loop_to_end_of_line

		ldrb r1, [r4, #-2] @ load last char of line
		sub r1, #0x30 @ ascii to int

		cmp r0, #'d' @ down
		addeq r6, r1
		cmp r0, #'u' @ up
		subeq r6, r1
		cmp r0, #'f' @ forward
		addeq r3, r1
		muleq r1, r6
		addeq r2, r1

		cmp r4, r5 @ have we reached the end of the data?
	bne p2_loop_per_line

	@ multiply depth by horizontal to get result
	mul r0, r2, r3

	pop {r1-r6}
	bx lr
.pool



arm_fn
main:
	bl setup_for_display

	bl aoc_day02_part1
	mov r1, #0
	bl display_number

	bl aoc_day02_part2
	mov r1, #1
	bl display_number

spin_halt:
	b spin_halt
.pool
