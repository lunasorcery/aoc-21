.section .text
.include "crt0.s"
.include "common.s"
.include "day07-data.s"


arm_fn
@ inputs:
@ r2: begin ptr
@ r4: end ptr
@ returns:
@ r0: (max(range)+min(range))/2 (rounded up)
find_threshold_for_range:
	push {r1-r3}

	ldr r0, =0xffff @ min
	mov r1, #0x0000 @ max

	find_threshold_for_range_loop:
		ldrh r3, [r2], #2
		cmp r3, r0
		movlt r0, r3 @ r0 = min(r0,r3)
		cmp r3, r1 @ how did I miss this???
		movgt r1, r3 @ r1 = max(r1,r3)
		cmp r2, r4
	bne find_threshold_for_range_loop

	add r0, r1
	add r0, #1
	lsr r0, #1

	pop {r1-r3}
	bx lr
.pool



arm_fn
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
@ median of the array
compute_u16_median:
	push {r1-r9,lr}

	mov r2, r0		@ r2: left partition start
	add r4, r2, r1	@ r4: right partition end

	lsr r1, #2
	lsl r1, #1
	add r6, r2, r1	@ r6: midpoint pointer

	compute_u16_median_loop_per_pass:
		bl find_threshold_for_range	@ r0: threshold value
		mov r3, r2	@ r3: left sliding pointer
		mov r5, r4	@ r5: right sliding pointer
		mov r1, #0	@ r1: swap counter

		compute_u16_median_loop_until_collision:
			compute_u16_median_loop_left:
				cmp r3, r5
				beq compute_u16_median_collision @ break out if we've collided

				ldrh r8, [r3]		@ r8: left value
				cmp r8, r0			@ compare with threshold
				addlt r3, #2		@ advance if it's lower than the threshold
			blt compute_u16_median_loop_left @ loop back until we find a misplaced value
			
			compute_u16_median_loop_right:
				cmp r3, r5
				beq compute_u16_median_collision @ break out if we've collided

				ldrh r9, [r5, #-2]	@ r8: right value
				cmp r9, r0			@ compare with threshold
				subge r5, #2		@ advance if it's greater-or-equal than the threshold
			bge compute_u16_median_loop_right @ loop back until we find a misplaced value

			@ swap the values
			strh r8, [r5, #-2]
			strh r9, [r3]
			add r1, #1
		b compute_u16_median_loop_until_collision

		compute_u16_median_collision:
		
		cmp r1, #0
		beq compute_u16_median_finish @ if we did no swaps, then the partition is sorted, and the midpoint is the median

		cmp r3, r6		@ compare the collision location with the midpoint
		movlt r2, r3	@ if the collision is to the left of the midpoint, move the left edge up
		movgt r4, r5	@ if the collision is to the right of the midpoint, move the right edge down
	b compute_u16_median_loop_per_pass

compute_u16_median_finish:
	ldrh r0, [r6] 	@ load result from midpoint

	pop {r1-r9}
	pop {lr}
	bx lr
.pool



arm_fn
@ r0: array start pointer
@ r1: array length (bytes)
@ returns:
@ mean of the array
compute_u16_mean:
	push {r1-r4}

	mov r2, #0  		@ total
	mov r3, r1, lsr #1 	@ num items

	compute_u16_mean_loop:
		subs r1, #2
		ldrh r4, [r0, r1]
		add r2, r4
	bne compute_u16_mean_loop

	mov r0, r2
	mov r1, r3
	arm_swi 0x06 @ div (puts r0/r1 in r0, also writes to r1 and r3)

	pop {r1-r4}
	bx lr
.pool


arm_fn
aoc_day07_part1:
	push {r1-r11,lr}

	@ copy dataset into iwram
	mov r4, #0x03000000
	ldr r5, =day07_data_start
	ldr r6, =day07_data_end
	p1_loop_populate_ram:
		ldrh r3, [r5], #2
		strh r3, [r4], #2
		cmp r5, r6
	bne p1_loop_populate_ram

	@ find median
	mov r0, #0x03000000
	mov r1, #day07_data_length_bytes
	bl compute_u16_median

	@ find fuel costs
	mov r1, #0 @ fuel counter
	ldr r5, =day07_data_start
	ldr r6, =day07_data_end
	p1_loop_sum_fuel_costs:
		ldrh r3, [r5], #2
		subs r3, r0 @ subtract destination
		neglt r3, r3 @ invert if negative
		add r1, r3 @ add to total
		cmp r5, r6
	bne p1_loop_sum_fuel_costs

	mov r0, r1

	pop {r1-r11}
	pop {lr}
	bx lr
.pool


arm_fn
aoc_day07_part2:
	push {r1-r11,lr}

	@ copy dataset into iwram
	mov r4, #0x03000000
	ldr r5, =day07_data_start
	ldr r6, =day07_data_end
	p2_loop_populate_ram:
		ldrh r3, [r5], #2
		strh r3, [r4], #2
		cmp r5, r6
	bne p2_loop_populate_ram

	@ find mean
	mov r0, #0x03000000
	mov r1, #day07_data_length_bytes
	bl compute_u16_mean

	.macro p2_compute_fuel rDest
		mov \rDest, #0 @ fuel counter
		ldr r5, =day07_data_start
		ldr r6, =day07_data_end
		p2_loop_sum_fuel_costs_\@:
			ldrh r3, [r5], #2
			subs r3, r0 @ subtract destination pos
			neglt r3, r3 @ invert if negative
			mla r4, r3, r3, r3 @ r4 = n*n+n
			add \rDest, r4, lsr #1 @ add `(n*n+n)/2` to total
			cmp r5, r6
		bne p2_loop_sum_fuel_costs_\@
	.endm

	@ find fuel costs
	p2_compute_fuel r1 @ for mean rounded down
	add r0, #1
	p2_compute_fuel r2 @ for mean rounded up

	cmp r1, r2
	movlt r0, r1
	movge r0, r2

	pop {r1-r11}
	pop {lr}
	bx lr
.pool


arm_fn
main:
	bl setup_for_display

	bl aoc_day07_part1
	mov r1, #0
	bl print_u32_dec

	bl aoc_day07_part2
	mov r1, #1
	bl print_u32_dec

spin_halt:
	b spin_halt
.pool
