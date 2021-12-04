.section .text
.include "crt0.s"
.include "common.s"
.include "day04-data.s"


arm_fn
@ inputs:
@ r0: board state bitfield
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
@ inputs:
@ r0: win counter (return score of Nth winning board)
aoc_day04:
	push {r1-r12,lr}

	@ back up the win counter
	mov r12, r0

	@ clear out the ram area we'll use to store board state
	mov r1, #day04_data_num_boards
	mov r2, #0x03000000
	mov r3, #0
	p1_loop_per_board_clear_ram:
		str r3, [r2], #4
		subs r1, #1
	bne p1_loop_per_board_clear_ram


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
	@ r12: win counter

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

			@ if it's already won (flag in top bit of state)
			@ skip ahead
			mov r1, #0x80000000
			tst r0, r1
			bne p1_next_board

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

			@ check if it's a winning board
			bl is_winning_board
			cmp r0, #0
			beq p1_next_board

				@ if it's a winning board
				@ decrement the counter,
				@ and jump out if we've found the Nth winning board we want
				subs r12, #1
				beq p1_found_winner

				@ if it's a winning board but *not* the Nth we want
				@ mark it as already won so we can skip processing it
				mov r1, #0x80000000
				orr r0, r1
				str r0, [r11]
				
			p1_next_board:
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

	pop {r1-r12}
	pop {lr}
	bx lr
.pool



arm_fn
main:
	bl setup_for_display

	mov r0, #1
	bl aoc_day04
	mov r1, #0
	bl display_number

	mov r0, #day04_data_num_boards
	bl aoc_day04
	mov r1, #1
	bl display_number

spin_halt:
	b spin_halt
.pool
