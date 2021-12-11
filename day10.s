.section .text
.include "crt0.s"
.include "common.s"
.include "day10-data.s"



.macro u64_add a_lo, a_hi, b_lo, b_hi
	adds \a_lo, \b_lo	@ add low bits and set carry flag if appropriate
	adc  \a_hi, \b_hi	@ add high bits with carry
.endm



arm_fn
aoc_day10_part1:
	push {r1-r12,lr}

	@ total counter
	mov r0, #0

	ldr r5, =day10_data_start
	ldr r6, =day10_data_end	
	p1_loop_per_row:
		mov r4, #0x03000000 @ stack pointer

		p1_loop_per_char:
			ldrb r1, [r5], #1	@ read and advance the input
			cmp r1, #0
			beq p1_next_row		@ bail out if we hit the end of a string

			@ push to the stack for an opening brace
			cmp r1, #'('
				streqb r1, [r4], #1
				beq p1_loop_per_char

			cmp r1, #'['
				streqb r1, [r4], #1
				beq p1_loop_per_char

			cmp r1, #'{'
				streqb r1, [r4], #1
				beq p1_loop_per_char

			cmp r1, #'<'
				streqb r1, [r4], #1
				beq p1_loop_per_char

			@ pop from the stack
			ldrb r2, [r4, #-1]!	@ (read from r4-1, and the '!' makes it write that offsetted address back into r4)

			@ cheap way to check for matching braces,
			@ just compare the top 4 bits
			@ because of the ascii layout:
			@ 28: (    29: )
			@ 5B: [    5D: ]
			@ 7B: {    7D: }
			@ 3C: <    3E: >
			lsr r1, #4
			lsr r2, #4
			cmp r1, r2
			beq p1_loop_per_char @ if it's matching, we're all good

			@ if it doesn't match
			@ update the score accordingly
			cmp r1, #('(' >> 4)
				addeq r0, #3
				beq p1_skip_to_end_of_row

			cmp r1, #('[' >> 4)
				addeq r0, #57
				beq p1_skip_to_end_of_row

			cmp r1, #('{' >> 4)
				ldr r3, =1197
				addeq r0, r3
				beq p1_skip_to_end_of_row

			cmp r1, #('<' >> 4)
				ldr r3, =25137
				addeq r0, r3
				beq p1_skip_to_end_of_row

		b p1_loop_per_char

		@ seek to the next null terminator
		p1_skip_to_end_of_row:
			ldrb r1, [r5], #1
			cmp r1, #0
		bne p1_skip_to_end_of_row

		p1_next_row:
		cmp r5, r6
	bne p1_loop_per_row

	pop {r1-r12}
	pop {lr}
	bx lr
.pool




.macro u64_max a_lo, a_hi, b_lo, b_hi
	cmp \a_hi, \b_hi		@ compare hi bits
	bhi u64_max_ret_\@		@ if a_hi > b_hi, bail
	beq u64_max_hi_eq_\@	@ if a_hi == b_hi, handle specially
	mov \a_hi, \b_hi		@ otherwise if a_hi < b_hi.. swap both
	mov \a_lo, \b_lo		@ swap both
u64_max_hi_eq_\@:
	cmp \a_lo, \b_lo		@ compare lo bits
	movlo \a_lo, \b_lo		@ if a_lo < b_lo, swap lo bits
u64_max_ret_\@:
.endm


.macro u64_min a_lo, a_hi, b_lo, b_hi
	cmp \a_hi, \b_hi		@ compare hi bits
	blo u64_min_ret_\@		@ if a_hi < b_hi, bail
	beq u64_min_hi_eq_\@	@ if a_hi == b_hi, handle specially
	mov \a_hi, \b_hi		@ otherwise if a_hi > b_hi.. swap both
	mov \a_lo, \b_lo		@ swap both
u64_min_hi_eq_\@:
	cmp \a_lo, \b_lo		@ compare lo bits
	movhi \a_lo, \b_lo		@ if a_lo > b_lo, swap lo bits
u64_min_ret_\@:
.endm




arm_fn
@ inputs:
@ r2: begin ptr
@ r4: end ptr
@ returns:
@ r0: pivot value (lo bits)
@ r1: pivot value (hi bits)
find_threshold_for_range:
	push {r2-r9}

	@ seems to be critical that the pivot actually exists in the range,
	@ rather than being a value between two entries
	@ https://www.i-programmer.info/babbages-bag/505-quick-median.html

	@ "random" value
	ldr r3, =0x03006000
	ldr r5, [r3]
	add r5, #1
	str r5, [r3]

	@ get range length
	sub r6, r4, r2
	lsr r6, #3

	reduce_random:
		cmp r5, r6
		lsrgt r5, #1
		bgt reduce_random

	@ get pivot pointer
	add r5, r2, r5, lsl #3

	ldr r0, [r5], #4
	ldr r1, [r5], #4

	pop {r2-r9}
	bx lr
.pool




arm_fn
@ copied and adapted from day 7
@ pick a threshold and partition the array into two sets, <T and >=T, using swaps
@ once done, determine which partition the midpoint of the full array is in
@ pick a new threshold from that partition
@ apply recursively, always recursing into whichever of the two sets contains the overall midpoint
@ repeat until only the median remains
@
@ inputs:
@ r0: array start pointer
@ r1: array length (bytes)
@ returns:
@ r0: median of the array (lo bits)
@ r1: median of the array (hi bits)
.global compute_u64_median
compute_u64_median:
	push {r2-r12,lr}

	mov r2, r0		@ r2: left partition start
	add r4, r2, r1	@ r4: right partition end

	lsr r1, #4		@ (length / sizeof_item) / 2
	lsl r1, #3		@ (midpoint_index * sizeof_item)
	add r6, r2, r1	@ r6: midpoint pointer

	.global compute_u64_median_loop_per_pass
	compute_u64_median_loop_per_pass:
		bl find_threshold_for_range	@ {r0,r1}: threshold value
		.global after_threshold
		after_threshold:
		mov r3, r2	@ r3: left sliding pointer
		mov r5, r4	@ r5: right sliding pointer
		mov r12, #0	@ r12: swap counter

		compute_u64_median_loop_until_collision:
			compute_u64_median_loop_left:
				cmp r3, r5
				beq compute_u64_median_collision @ break out if we've collided

				ldr r8, [r3]		@ r8: left value (lo)
				ldr r9, [r3, #4]	@ r9: left value (hi)

				cmp r9,r1	@ compare hi bits
				bgt compute_u64_median_found_left	@ if it's misplaced, jump ahead
				addlt r3, #8						@ if it's correctly placed, advance...
				blt compute_u64_median_loop_left	@ and jump back
				cmp r8, r0	@ if hi bits are equal, compare lo bits
				bhs compute_u64_median_found_left
				addlo r3, #8
				blo compute_u64_median_loop_left
			compute_u64_median_found_left:


			compute_u64_median_loop_right:
				cmp r3, r5
				beq compute_u64_median_collision @ break out if we've collided

				ldr r10, [r5, #-8]	@ r10: right value (lo)
				ldr r11, [r5, #-4]	@ r11: right value (hi)
			
				cmp r11,r1	@ compare hi bits
				blt compute_u64_median_found_right	@ if it's misplaced, jump ahead
				subgt r5, #8						@ if it's correctly placed, advance...
				bgt compute_u64_median_loop_right	@ and jump back
				cmp r10, r0	@ if hi bits are equal, compare lo bits
				blo compute_u64_median_found_right
				subhs r5, #8
				bhs compute_u64_median_loop_right
			compute_u64_median_found_right:

			.global break_here
			break_here:

			@ swap the values
			str r8, [r5, #-8]
			str r9, [r5, #-4]
			str r10, [r3]
			str r11, [r3, #4]

			@ update swap counter
			add r12, #1
		b compute_u64_median_loop_until_collision

		compute_u64_median_collision:
		
		cmp r12, #0
		beq compute_u64_median_finish @ if we did no swaps, then the partition is sorted, and the midpoint is the median

		cmp r3, r6		@ compare the collision location with the midpoint
		movlt r2, r3	@ if the collision is to the left of the midpoint, move the left edge up
		movgt r4, r5	@ if the collision is to the right of the midpoint, move the right edge down
	b compute_u64_median_loop_per_pass

.global compute_u64_median_finish
compute_u64_median_finish:
	ldr r0, [r6] 		@ load result from midpoint (lo bits)
	ldr r1, [r6, #4] 	@ load result from midpoint (hi bits)

	pop {r2-r12}
	pop {lr}
	bx lr
.pool





arm_fn
aoc_day10_part2:
	push {r2-r12,lr}

	@ score table
	ldr r9,  =0x03004000 @ score table start
	ldr r10, =0x03004000 @ score table end / writeptr

	ldr r5, =day10_data_start
	ldr r6, =day10_data_end	
	p2_loop_per_row:
		mov r4, #0x03000000 @ stack pointer

		p2_loop_per_char:
			ldrb r1, [r5], #1	@ read and advance the input
			cmp r1, #0
			beq p2_incomplete_row	@ bail out if we hit the end of a string

			@ push to the stack for an opening brace
			cmp r1, #'('
				streqb r1, [r4], #1
				beq p2_loop_per_char

			cmp r1, #'['
				streqb r1, [r4], #1
				beq p2_loop_per_char

			cmp r1, #'{'
				streqb r1, [r4], #1
				beq p2_loop_per_char

			cmp r1, #'<'
				streqb r1, [r4], #1
				beq p2_loop_per_char

			@ pop from the stack
			ldrb r2, [r4, #-1]!	@ (read from r4-1, and the '!' makes it write that offsetted address back into r4)

			@ cheap way to check for matching braces,
			@ just compare the top 4 bits
			@ because of the ascii layout:
			@ 28: (    29: )
			@ 5B: [    5D: ]
			@ 7B: {    7D: }
			@ 3C: <    3E: >
			lsr r1, #4
			lsr r2, #4
			cmp r1, r2
			beq p2_loop_per_char @ if it's matching, we're all good

			@ if it doesn't match
			@ update the score accordingly
			cmp r1, #('(' >> 4)
				addeq r0, #3
				beq p2_corrupted_row

			cmp r1, #('[' >> 4)
				addeq r0, #57
				beq p2_corrupted_row

			cmp r1, #('{' >> 4)
				ldr r3, =1197
				addeq r0, r3
				beq p2_corrupted_row

			cmp r1, #('<' >> 4)
				ldr r3, =25137
				addeq r0, r3
				beq p2_corrupted_row

		b p2_loop_per_char

		@ handle the incomplete-row case
		p2_incomplete_row:
			mov r7, #0 @ row score (lo bits)
			mov r8, #0 @ row score (hi bits)
			p2_loop_pop_stack:

				@ multiply score by 5 (via repeated addition)
				mov r11, r7
				mov r12, r8
				u64_add r7,r8, r11,r12
				u64_add r7,r8, r11,r12
				u64_add r7,r8, r11,r12
				u64_add r7,r8, r11,r12

				@ pop from the stack
				ldrb r2, [r4, #-1]!
				
				@ update score
				cmp r2, #'('
					addeqs r7, #1
					adceq r8, #0
				cmp r2, #'['
					addeqs r7, #2
					adceq r8, #0
				cmp r2, #'{'
					addeqs r7, #3
					adceq r8, #0
				cmp r2, #'<'
					addeqs r7, #4
					adceq r8, #0

				cmp r4, #0x03000000
			bne p2_loop_pop_stack
			
			@ add to score table
			str r7, [r10], #4
			str r8, [r10], #4
		b p2_next_row

		@ handle the corrupted-row case
		@ seek to the next null terminator
		p2_corrupted_row:
		p2_skip_to_end_of_row:
			ldrb r1, [r5], #1
			cmp r1, #0
		bne p2_skip_to_end_of_row

		p2_next_row:
		cmp r5, r6
	bne p2_loop_per_row

	@ find middle score
	mov r0, r9			@ r0 = range start
	subs r1, r10, r9	@ r1 = range length (bytes)
	bl compute_u64_median

	pop {r2-r12}
	pop {lr}
	bx lr
.pool



arm_fn
main:
	bl setup_for_display

	bl aoc_day10_part1
	mov r1, #0
	bl print_u32_dec

	bl aoc_day10_part2
	mov r2, #1
	bl print_u64_dec

spin_halt:
	b spin_halt
.pool
