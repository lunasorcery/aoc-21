.section .text
.include "crt0.s"
.include "common.s"
.include "day11-data.s"


arm_fn
load_data_into_ram:
	push {r1-r6,lr}

	@ load data into ram
	mov r6, #0x03000000
	ldr r5, =day11_data_start
	mov r4, #day11_data_height
	copy_to_ram_per_row:
		mov r3, #day11_data_width
		copy_to_ram_per_col:
			ldrb r1, [r5], #1
			sub r1, #'0'
			strb r1, [r6], #1
			subs r3, #1
		bne copy_to_ram_per_col
		add r5, #1 @ skip null terminator
		subs r4, #1
	bne copy_to_ram_per_row

	pop {r1-r6}
	pop {lr}
	bx lr
.pool



arm_fn
print_grid:
	push {r0-r6,lr}


	@ wait for vblank
	mov r0, #0x04000000
wait_for_vblank:
	ldrh r1, [r0, #6] @ load VCOUNT
	cmp r1, #160
	bne wait_for_vblank
	

	mov r6, #0x03000000 @ ram ptr
	mov r5, #0x06000000 @ vram ptr

	mov r4, #0	@y
	print_grid_per_row:
		mov r3, #0	@x
		print_grid_per_col:
			@ read from ram
			ldrb r2, [r6], #1

			@ toggle palette if appropriate
			cmp r2, #0
			addne r2, #0x1000

			@ increment to get tile id
			add r2, #1

			@ get vram offset from x
			lsl r1, r3, #1

			strh r2, [r5, r1]

			add r3, #1
			cmp r3, #day11_data_width
		blt print_grid_per_col

		add r5, #64

		add r4, #1
		cmp r4, #day11_data_height
	blt print_grid_per_row

	pop {r0-r6}
	pop {lr}
	bx lr
.pool




arm_fn
run_one_step:
	push {r1-r6,lr}

	mov r0, #0 @ total flash counter

	@ increment all values
	mov r6, #0x03000000 @ ram ptr
	mov r4, #day11_data_height	@ y
	run_step_increment_per_row:
		mov r3, #day11_data_width	@ x
		run_step_increment_per_col:
			@ increment value
			ldrb r1, [r6]
			add r1, #1
			strb r1, [r6], #1

			subs r3, #1
		bne run_step_increment_per_col
		subs r4, #1
	bne run_step_increment_per_row


	run_step_propagate_flashes:
		mov r2, #0 @ per-pass flash counter

		mov r6, #0x03000000 @ ram ptr
		mov r4, #0	@y
		run_step_propagate_per_row:
			mov r3, #0	@x
			run_step_propagate_per_col:
				ldrsb r1, [r6]
				cmp r1, #10
				blt run_step_next_cell
					@ process a flash at {r3,r4}:

					@ update counter
					add r2, #1

					@ set a flag so we don't double-flash
					orr r1, #0x80
					strb r1, [r6]

					@ process NW N NE
					cmp r4, #0
					beq run_step_skip_all_north
						@ process N
						ldrb r1, [r6, #-day11_data_width]
						add r1, #1
						strb r1, [r6, #-day11_data_width]

						@ process SW
						cmp r3, #0
						beq run_step_skip_norththwest
							ldrb r1, [r6, #(-day11_data_width-1)]
							add r1, #1
							strb r1, [r6, #(-day11_data_width-1)]
						run_step_skip_norththwest:

						@ process SE
						cmp r3, #(day11_data_width-1)
						beq run_step_skip_norththeast
							ldrb r1, [r6, #(-day11_data_width+1)]
							add r1, #1
							strb r1, [r6, #(-day11_data_width+1)]
						run_step_skip_norththeast:
					run_step_skip_all_north:


					@ process SW S SE
					cmp r4, #(day11_data_height-1)
					beq run_step_skip_all_south
						@ process S
						ldrb r1, [r6, #day11_data_width]
						add r1, #1
						strb r1, [r6, #day11_data_width]

						@ process SW
						cmp r3, #0
						beq run_step_skip_southwest
							ldrb r1, [r6, #(day11_data_width-1)]
							add r1, #1
							strb r1, [r6, #(day11_data_width-1)]
						run_step_skip_southwest:

						@ process SE
						cmp r3, #(day11_data_width-1)
						beq run_step_skip_southeast
							ldrb r1, [r6, #(day11_data_width+1)]
							add r1, #1
							strb r1, [r6, #(day11_data_width+1)]
						run_step_skip_southeast:
					run_step_skip_all_south:


					@ process W
					cmp r3, #0
					beq run_step_skip_west
						ldrb r1, [r6, #-1]
						add r1, #1
						strb r1, [r6, #-1]
					run_step_skip_west:


					@ process E
					cmp r3, #(day11_data_width-1)
					beq run_step_skip_east
						ldrb r1, [r6, #1]
						add r1, #1
						strb r1, [r6, #1]
					run_step_skip_east:

				run_step_next_cell:
				add r6, #1
				add r3, #1
				cmp r3, #day11_data_width
			blt run_step_propagate_per_col
			add r4, #1
			cmp r4, #day11_data_height
		blt run_step_propagate_per_row

		add r0, r2
		cmp r2, #0
	bne run_step_propagate_flashes @ loop until a pass encounters zero flashes

	
	@ zero flashing values
	mov r6, #0x03000000 @ ram ptr
	mov r4, #day11_data_height	@ y
	run_step_cleanup_per_row:
		mov r3, #day11_data_width	@ x
		run_step_cleanup_per_col:
			ldrb r1, [r6], #1
			tst r1, #0x80
			beq run_step_cleanup_next_cell
				mov r1, #0
				strb r1, [r6, #-1]
			run_step_cleanup_next_cell:
			subs r3, #1
		bne run_step_cleanup_per_col
		subs r4, #1
	bne run_step_cleanup_per_row


	pop {r1-r6}
	pop {lr}
	bx lr
.pool



arm_fn
aoc_day11_part1:
	push {r1-r3,lr}

	bl load_data_into_ram

	mov r2, #0 @ flash counter
	mov r3, #100 @ steps to run
	p1_loop_steps:
		bl run_one_step
		add r2, r0	@ update counter
		
		bl print_grid
		
		@ print flash count
		mov r0, r2
		mov r1, #0
		bl print_u32_dec
		
		subs r3, #1
	bne p1_loop_steps

	@ mov r0, r2 @ return flash counter

	pop {r1-r3}
	pop {lr}
	bx lr
.pool



arm_fn
aoc_day11_part2:
	push {r1-r2,lr}

	bl load_data_into_ram

	mov r2, #0 @ step counter
	p2_loop_steps:
		add r2, #1
		bl run_one_step
		mov r3, r0

		bl print_grid

		@ print step counter
		mov r0, r2
		mov r1, #1
		bl print_u32_dec

		cmp r3, #(day11_data_width*day11_data_height)
	bne p2_loop_steps

	@ mov r0, r2 @ return step counter

	pop {r1-r2}
	pop {lr}
	bx lr
.pool



arm_fn
main:
	bl setup_for_display

	@ set up bonus palette
	ldr r6, =0x05000020 @ pram ptr
	ldr r1, =0x42100000 @ darker palette
	str r1, [r6]

	bl aoc_day11_part1

	bl aoc_day11_part2

spin_halt:
	b spin_halt
.pool
