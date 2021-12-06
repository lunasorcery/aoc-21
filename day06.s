.section .text
.include "crt0.s"
.include "common.s"
.include "day06-data.s"


arm_fn
aoc_day06_part1_firsttry:
	push {r1-r11,lr}

	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
	mov r4, #0
	mov r5, #0
	mov r6, #0
	mov r7, #0
	mov r8, #0

	@ initial state
	ldr r9,  =day06_data_start
	ldr r10, =day06_data_end
	p1f_loop_per_initial_fish:
		ldrb r11, [r9], #1

		cmp r11, #0
		addeq r0, #1
		cmp r11, #1
		addeq r1, #1
		cmp r11, #2
		addeq r2, #1
		cmp r11, #3
		addeq r3, #1
		cmp r11, #4
		addeq r4, #1
		cmp r11, #5
		addeq r5, #1
		cmp r11, #6
		addeq r6, #1

		cmp r9, r10
	bne p1f_loop_per_initial_fish

	@ simulation
	mov r12, #80
	p1f_loop_per_day:
		mov r10, r0
		mov r0, r1
		mov r1, r2
		mov r2, r3
		mov r3, r4
		mov r4, r5
		mov r5, r6
		mov r6, r7
		mov r7, r8
		mov r8, r10
		add r6, r10

		subs r12, #1
	bne p1f_loop_per_day

	add r0, r1
	add r0, r2
	add r0, r3
	add r0, r4
	add r0, r5
	add r0, r6
	add r0, r7
	add r0, r8

	pop {r1-r11}
	pop {lr}
	bx lr
.pool


arm_fn
aoc_day06_part1_redo:
	push {r1-r8,lr}

	.equ p1r_array_length, 9*4 @ 9 values x 4 bytes per value

	@ free some stack space for u32[9] counters
	sub sp, #p1r_array_length

	@ clear the stack array
	mov r0, #0
	mov r1, #p1r_array_length
	p1r_loop_clear_array:
		subs r1, #4
		str r0, [sp, r1]
	bne p1r_loop_clear_array

	@ load the initial state
	ldr r2, =day06_data_start
	ldr r3, =day06_data_end
	p1r_loop_per_initial_fish:
		ldrb r0, [r2], #1	@ load a fish from the dataset
		lsl r0, #2			@ multiply by 4 to get byte offset into stack array
		ldr r1, [sp, r0]	@ load,
		add r1, #1			@ increment,
		str r1, [sp, r0]	@ and save the number of fish at that lifespan
		cmp r2, r3
	bne p1r_loop_per_initial_fish

	@ set up pointers to special values in the circular buffer
	mov r6, #(6*4)  @ r6 tracks where the counter of fish with lifespan 6 is
	mov r8, #(8*4)  @ r8 tracks where the counter of fish with lifespan 8 is
	@ carefully chosen to almost be sensible variable names ;)

	@ simulation
	mov r2, #80 @ day counter
	p1r_loop_per_day:
		@ do a rotate!
		@ by advancing the pointers into the circular buffer,
		@ instead of rotating data in the buffer itself
		add r6, #4
		cmp r6, #p1r_array_length
		moveq r6, #0
		add r8, #4
		cmp r8, #p1r_array_length
		moveq r8, #0	

		@ increment the number of fish at lifespan 6,
		@ by the number of fish at lifespan 8
		ldr r0, [sp, r6]
		ldr r1, [sp, r8]
		add r0, r1
		str r0, [sp, r6]

		subs r2, #1
	bne p1r_loop_per_day

	@ sum it all up into r0
	mov r0, #0
	mov r1, #p1r_array_length
	p1r_loop_accumulate:
		subs r1, #4
		ldr r2, [sp, r1]
		add r0, r2
	bne p1r_loop_accumulate

	@ pop the stack array
	add sp, #p1r_array_length

	pop {r1-r8}
	pop {lr}
	bx lr
.pool


arm_fn
aoc_day06_part2:
	push {r1-r11,lr}

	pop {r1-r11}
	pop {lr}
	bx lr
.pool


arm_fn
main:
	bl setup_for_display

	bl aoc_day06_part1_firsttry
	mov r1, #0
	bl display_number

	bl aoc_day06_part1_redo
	mov r1, #1
	bl display_number

	bl aoc_day06_part2
	mov r1, #2
	bl display_number

spin_halt:
	b spin_halt
.pool
