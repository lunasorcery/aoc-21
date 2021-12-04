.section .text
.include "crt0.s"
.include "common.s"
.include "day04-data.s"


arm_fn
is_winning_board:
	push {r1-r2}

	ldr r1, =0b0000000000000000000011111
	.rept 5
		and r2, r0, r1
		cmp r1, r2
		beq is_winning_board_ret_true
		lsl r1, #5
	.endr

	ldr r1, =0b0000100001000010000100001
	.rept 5
		and r2, r0, r1
		cmp r1, r2
		beq is_winning_board_ret_true
		lsl r1, #1
	.endr

	mov r0, #0
	b is_winning_board_ret
is_winning_board_ret_true:
	mov r0, #1
is_winning_board_ret:
	pop {r1-r2}
	bx lr
.pool


arm_fn
aoc_day04_part1:
	push {r1-r11,lr}

	@ r0: current board state bitfield
	@ r1: current board cell
	@ r2: current call
	@ r5: current call pointer
	@ r6: end call pointer
	@ r7: current board pointer
	@ r8: end board pointer
	@ r9: cell id
	@ r10: cell mask
	@ r11: board state pointer (ram)

	ldr r6, =day04_data_calls_end
	ldr r8, =day04_data_boards_end

	ldr r5, =day04_data_calls_start
	p1_loop_per_call:
		ldrb r2, [r5], #1

		ldr r7, =day04_data_boards_start
		ldr r11, =0x03000000
		p1_loop_per_board:
			mov r9, #0
			mov r10, #1
			ldr r0, [r11]
			p1_loop_per_cell:
				ldrb r1, [r7, r9]
				cmp r1, r2
				bne p1_next_cell
					orr r0, r10
					str r0, [r11]
				p1_next_cell:
				lsl r10, #1
				add r9, #1
				cmp r9, #25
			bne p1_loop_per_cell

			bl is_winning_board
			cmp r0, #0
			bne p1_found_winner

			add r11, #4
			add r7, #25
			cmp r7, r8
		bne p1_loop_per_board
		

		cmp r5, r6
	bne p1_loop_per_call

p1_found_winner:
	@ r0: score total
	@ r1: current board cell
	@ r2: winning call
	@ r3: winning board state bitfield
	@ r7: winning board pointer
	@ r9: cell index
	@ r10: cell mask
	@ r11: winning board state pointer (ram)

	mov r0, #0
	ldr r3, [r11]
	mov r9, #0
	mov r10, #1
	p1_loop_per_cell_totals:
		tst r3, r10
		bne p1_next_cell_totals
			ldrb r1, [r7, r9]
			add r0, r1
		p1_next_cell_totals:
		lsl r10, #1
		add r9, #1
		cmp r9, #25
	bne p1_loop_per_cell_totals
	mul r0, r2

	pop {r1-r11}
	pop {lr}
	bx lr
.pool



arm_fn
aoc_day04_part2:
	push {r1-r12}

	pop {r1-r12}
	bx lr
.pool



arm_fn
main:
	bl setup_for_display

	bl aoc_day04_part1
	mov r1, #0
	bl display_number

	bl aoc_day04_part2
	mov r1, #1
	bl display_number

spin_halt:
	b spin_halt
.pool
