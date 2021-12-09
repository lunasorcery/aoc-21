.section .text
.include "crt0.s"
.include "common.s"
.include "day08-data.s"


arm_fn
@ do this the lazy way, just by counting lengths and not deriving anything
aoc_day08_part1:
	push {r1-r4,lr}

	@ total counter
	mov r0, #0

	ldr r3, =day08_data_start
	ldr r4, =day08_data_end
	p1_loop_per_row:
		add r3, #61 @ seek ahead past the pipe, to the displayed numbers

		p1_loop_per_displayed_digit:
			mov r2, #0 @ digit length counter
			p1_loop_per_char:
				ldrb r1, [r3], #1	@ read a char
				cmp r1, #'a'		@ if it's 'a' or above,
				addge r2, #1		@ increment the length counter
			bge p1_loop_per_char @ loop until we hit the end of the digit (space and null are both less than 'a' in ascii)

			cmp r2, #4  @ if it's 2,3,4 chars, then it's a 1,7,4 respectively (and it can't possibly be 1 or 0 chars)
			addle r0, #1
			cmp r2, #7	@ if it's 7 chars, then it's an 8
			addeq r0, #1

			cmp r1, #0
		bne p1_loop_per_displayed_digit @ loop back until we hit a null terminator

		cmp r3, r4
	bne p1_loop_per_row	@ loop until we hit the end of the data

	@ result total already in r0, so can just return now

	pop {r1-r4}
	pop {lr}
	bx lr
.pool



arm_fn
@ inputs:
@ r8: char* input
read_digit_mask:
	push {r2-r3}

	mov r1, #0 @ digit bits
	mov r2, #1 @ just for masking in new bits
	read_digit_mask_loop_per_char:
		ldrb r3, [r8], #1		@ read a char
		subs r3, #'a'			@ @ if it's >='a',
		orrge r1, r2, lsl r3	@ mask in the corresponding bit
	bge read_digit_mask_loop_per_char @ loop until we hit the end of the digit (space is less than 'a' in ascii)

	pop {r2-r3}
	bx lr
.pool



arm_fn
@ inputs:
@ r6: sorted array of digit masks
@ r8: char* input
read_digit_actual:
	push {r2-r3,lr}

	bl read_digit_mask @ puts result in r1
	mov r2, #9
	read_digit_actual_find_match:
		ldrb r3, [r6, r2]	@ load from sorted array
		cmp r3, r1			@ if it matches,
		beq read_digit_actual_found_match	@ bail out
		subs r2, #1			@ otherwise, keep looping
	bge read_digit_actual_find_match

read_digit_actual_found_match:
	mov r1, r2	@ put result in r1

	pop {r2-r3}
	pop {lr}
	bx lr
.pool



arm_fn
aoc_day08_part2:
	push {r1-r11,lr}
	sub sp, #(10+10)
	@ ^ enough space to store the unsorted input set
	@ and the derived sorted set

	@ final counter
	mov r0, #0

	ldr r8, =day08_data_start
	ldr r9, =day08_data_end
	p2_loop_per_row:
		mov r4, #9 @ loop counter, unsorted-set write index
		p2_loop_per_mapping_digit:
			bl read_digit_mask	@ places result in r1
			strb r1, [sp, r4]	@ store it to the scratch buffer
			subs r4, #1
		bge p2_loop_per_mapping_digit @ loop until we've loaded all 10 input digits

		ldr r5, =popcount_table
		add r6, sp, #10 @ pointer to sorted-set

		mov r4, #9
		p2_loop_find_by_bitcount:
			ldrb r1, [sp, r4] @ load nth item from unsorted set
			ldrb r2, [r5, r1] @ count bits via lookup table

			cmp r2, #2 @ if it's got 2 bits, then it's 1
			streqb r1, [r6, #1] @ write to sorted set

			cmp r2, #3 @ if it's got 3 bits, then it's 7
			streqb r1, [r6, #7] @ write to sorted set

			cmp r2, #4 @ if it's got 4 bits, then it's 4
			streqb r1, [r6, #4] @ write to sorted set

			subs r4, #1
		bge p2_loop_find_by_bitcount @ loop through all 10 input values

		@  --
		@ |  |
		@  --
		@ |  |
		@  --
		@ 8 has all 7 bits set
		@ so it doesn't matter which bit is which
		mov r2, #0x7f
		strb r2, [r6, #8]

		@  --
		@    |
		@  --
		@    |
		@  --
		@ 3 has 5 bits set
		@ only 5-bit value to have *all* the bits from 1 set
		mov r4, #9
		p2_loop_find_3:
			ldrb r1, [sp, r4]	@ load nth item from unsorted set
			ldrb r2, [r5, r1]	@ count bits
			cmp r2, #5			@ check it's got 5 bits
			bne p2_loop_find_3_next
				ldrb r3, [r6, #1]	@ load bit-pattern for 1
				and r2, r1, r3		@ mask it
				cmp r2, r3			@ if all the bits from 1 are set,
				streqb r1, [r6, #3]	@ save bit-pattern for 3
			p2_loop_find_3_next:
			subs r4, #1
		bge p2_loop_find_3

		@  --
		@ |   
		@  --
		@ |  |
		@  --
		@ 6 has 6 bits set
		@ only 6-bit value to have all the bits *not* from 1 set
		mov r4, #9
		p2_loop_find_6:
			ldrb r1, [sp, r4]	@ load nth item from unsorted set
			ldrb r2, [r5, r1]	@ count bits
			cmp r2, #6			@ check it's got 6 bits
			bne p2_loop_find_6_next
				ldrb r3, [r6, #1]	@ load bit-pattern for 1
				mov r2, #0x7f
				eor r3, r2			@ invert it
				and r2, r1, r3		@ mask it
				cmp r2, r3			@ if all the bits from not-1 are set,
				streqb r1, [r6, #6]	@ save bit-pattern for 6
			p2_loop_find_6_next:
			subs r4, #1
		bge p2_loop_find_6

		@  -- 
		@ |  |
		@  -- 
		@    |
		@  -- 
		@ 9 can be obtained as (3 | 4)
		ldrb r2, [r6, #3]
		ldrb r3, [r6, #4]
		orr r2, r3 @ 3 | 4
		strb r2, [r6, #9]

		@  -- 
		@ |  |
		@     
		@ |  |
		@  -- 
		@ 0 is only missing the middle crossbar
		@ middle crossbar can be obtained with (~1 & 3 & 4)
		@ so 0 is ~(~1 & 3 & 4)
		mov r1, #0x7f
		ldrb r2, [r6, #1]
		eor r2, r1 @ ~1
		ldrb r3, [r6, #3]
		and r2, r3 @ & 3
		ldrb r3, [r6, #4]
		and r2, r3 @ & 4
		eor r2, r1 @ ~
		strb r2, [r6, #0]

		@  -- 
		@ |   
		@  -- 
		@    |
		@  -- 
		@ 5 can be obtained with (6 & 9)
		ldrb r2, [r6, #6]
		ldrb r3, [r6, #9]
		and r2, r3 @ 6 & 9
		strb r2, [r6, #5]

		@  -- 
		@    |
		@  -- 
		@ |   
		@  -- 
		@ 2 is 5 with the sides flipped
		@ the sides can be obtained as (1 | ~3)
		@ so 2 can be obtained with (5 ^ (1 | ~3))
		mov r1, #0x7f
		ldrb r2, [r6, #3]
		eor r2, r1 @ ~3
		ldrb r3, [r6, #1]
		orr r2, r3 @ | 1
		ldrb r3, [r6, #5]
		eor r2, r3 @ ^ 5
		strb r2, [r6, #2]

		@ seek past the pipe
		add r8, #2

		@ prepare to read in four digits
		mov r2, #0	@ accumulator
		mov r3, #10	@ decimal multiplier

		@ read in four digits
		bl read_digit_actual
		mov r2, r1
		.rept 3
			bl read_digit_actual
			mla r2, r3, r2, r1	@ r2 = r2*10+r1
		.endr

		@ add to final total
		add r0, r2

		cmp r8, r9
	bne p2_loop_per_row	@ loop until we've processed all rows

	@ result total already in r0, so can just return now

	add sp, #(10+10)
	pop {r1-r11}
	pop {lr}
	bx lr
.pool


arm_fn
main:
	bl setup_for_display

	bl aoc_day08_part1
	mov r1, #0
	bl print_u32_dec

	bl aoc_day08_part2
	mov r1, #1
	bl print_u32_dec

spin_halt:
	b spin_halt
.pool
