.section .text
.include "crt0.s"
.include "common.s"
.include "day03-data.s"


arm_fn
aoc_day03_part1:
	push {r1-r6}

	@ r0: current row value
	@ r1: counter
	@ r2: current bit mask
	@ r3: 'gamma' accumulator
	@ r4: current row pointer
	@ r5: end row pointer
	@ r6: row threshold (row count / 2)

	ldr r5, =day03_data_end

	ldr r6, =day03_data_start
	sub r6, r5, r6
	lsr r6, #3 @ shift by two to divide by bytes-per-value, and another one to divide by two

	mov r3, #0
	mov r2, #(1 << (day03_data_num_bits - 1))
	p1_loop_per_bit:
		ldr r4, =day03_data_start
		mov r1, #0 @ reset counter

		p1_loop_per_row:
			ldr r0, [r4], #4	@ load the next row, and advance
			tst r0, r2 			@ check the active bit
			addne r1, #1 		@ increment counter if it's set

			cmp r4, r5
		bne p1_loop_per_row
		
		cmp r1, r6		@ if counter is greater than threshold..
		orrgt r3, r2	@ ..accumulate the current bit

		lsrs r2, #1		@ move to next bit, and set flags
	bne p1_loop_per_bit	@ loop until the current bit mask is zero

	@ generate mask for all bits
	mov r0, #(1 << day03_data_num_bits)
	sub r0, #1

	@ compute epsilon as bit-inverse of gamma
	eor r0, r3

	@ compute (gamma * epsilon) as result
	mul r0, r3

	pop {r1-r6}
	bx lr
.pool



arm_fn
.global aoc_day03_part2_filter
@ r0: mode (0: Oxygen, 1: CO2)
aoc_day03_part2_filter:
	push {r1-r8}

	@ r0: current row value
	@ r1: temporary masked value
	@ r2: check mask (which bit are we counting)
	@ r3: filter mask (which bit positions are we filtering on)
	@ r4: filter value (which bit values are we filtering on)
	@ r5: counter of filtered rows
	@ r6: counter of filtered rows with a 1
	@ r7: current row pointer
	@ r8: end row pointer
	@ r9: current mode (0: Oxygen, 1: CO2)
	@ r10: last valid match

	mov r9, r0
	ldr r8, =day03_data_end

	mov r2, #(1 << (day03_data_num_bits - 1))
	mov r3, #0
	mov r4, #0
	p2_loop_per_bit:
		mov r5, #0
		mov r6, #0
		ldr r7, =day03_data_start
		mov r10, #0
		p2_loop_per_row:
			ldr r0, [r7], #4 @ load a row value
			and r1, r0, r3 @ mask the filtering bits
			cmp r1, r4 @ check if they're what we want
			bne p2_skip_to_next_row @ skip ahead if they're not

			add r5, #1 @ increment the counter of included rows

			mov r10, r0 @ update the last valid match

			tst r0, r2 @ check the current check-bit
			addne r6, #1 @ increment the counter of rows with a 1 in
		p2_skip_to_next_row:
			cmp r7, r8
		bne p2_loop_per_row

		@ if there's only one matching value..
		cmp r5, #1
		beq p2_break_out @ break out!

		@ r5 is now the count of filtered rows with a 0 in the check-bit
		sub r5, r6

		@ update the filter
		cmp r9, #0
		bne p2_update_filter_co2
			cmp r6, r5
			orrge r4, r2 @ if more 1s than 0s (or equal), write a 1
			b p2_after_update_filter
		p2_update_filter_co2:
			cmp r6, r5
			orrlt r4, r2 @ if fewer 1s than 0s (or equal), write a 1
		p2_after_update_filter:

		orr r3, r2 @ add current check-bit to filter mask
		lsrs r2, #1 @ move to check the next bit, and set flags
	bne p2_loop_per_bit @ loop until the check bit is zero

p2_break_out:
	mov r0, r10

	pop {r1-r8}
	bx lr
.pool



arm_fn
aoc_day03_part2:
	push {r1,lr}

	@ get oxygen rating
	mov r0, #0
	bl aoc_day03_part2_filter
	mov r1, #4
	bl display_number

	@ back up oxygen rating
	mov r2, r0

	@ get CO2 rating
	mov r0, #1
	bl aoc_day03_part2_filter
	mov r1, #5
	bl display_number

	@ multiply results
	mul r0, r2

	pop {r1}
	pop {lr}
	bx lr
.pool


arm_fn
main:
	bl setup_for_display

	bl aoc_day03_part1
	mov r1, #0
	bl display_number

	bl aoc_day03_part2
	mov r1, #6
	bl display_number

spin_halt:
	b spin_halt
.pool
