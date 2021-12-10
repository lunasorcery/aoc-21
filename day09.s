.section .text
.include "crt0.s"
.include "common.s"
.include "day09-data.s"


arm_fn
aoc_day09_part1:
	push {r1-r12,lr}

	@ load data into ram
	mov r6, #0x03000000
	ldr r5, =day09_data_start
	mov r4, #day09_data_height
	p1_copy_to_ram_per_row:
		mov r3, #day09_data_width
		p1_copy_to_ram_per_col:
			ldrb r1, [r5], #1
			sub r1, #'0'
			strb r1, [r6], #1
			subs r3, #1
		bne p1_copy_to_ram_per_col
		add r5, #1 @ skip null terminator
		subs r4, #1
	bne p1_copy_to_ram_per_row

	@ counter
	mov r0, #0

	@ read ptr
	mov r5, #0x03000000

	mov r4, #0 @ y coord
	p1_loop_per_row:
		mov r3, #0 @ x coord
		p1_loop_per_col:
			ldrb r1, [r5]

			@ test north
			cmp r4, #0
			beq p1_skip_north
				ldrb r2, [r5, #-day09_data_width]
				cmp r1, r2
				bge p1_next_cell
			p1_skip_north:

			@ test west
			cmp r3, #0
			beq p1_skip_west
				ldrb r2, [r5, #-1]
				cmp r1, r2
				bge p1_next_cell
			p1_skip_west:

			@ test south
			cmp r4, #(day09_data_height-1)
			beq p1_skip_south
				ldrb r2, [r5, #day09_data_width]
				cmp r1, r2
				bge p1_next_cell
			p1_skip_south:

			@ test east
			cmp r3, #(day09_data_width-1)
			beq p1_skip_east
				ldrb r2, [r5, #1]
				cmp r1, r2
				bge p1_next_cell
			p1_skip_east:

			add r1, #1 @ risk = height + 1
			add r0, r1 @ add to total

			p1_next_cell:
			add r5, #1
			add r3, #1
			cmp r3, #day09_data_width
		blt p1_loop_per_col

		add r4, #1
		cmp r4, #day09_data_height
	blt p1_loop_per_row

	pop {r1-r12}
	pop {lr}
	bx lr
.pool



arm_fn
@ inputs:
@ r2: x
@ r3: y
@ returns:
@ r0: size
flood_fill:
	push {r1-r12,lr}

	@ get memory address of target pixel
	mov r5, #day09_data_width
	mla r5, r3, r5, r2
	add r5, #0x03000000

	mov r4, #0	@ size counter

	ldrb r1, [r5]	@ read the target pixel
	cmp r1, #9
	bge flood_fill_done	@ bail early if it shouldn't be filled

		@ back up input position
		mov r6, r2	@ r6 = x
		mov r7, r3	@ r7 = y

		@ increment the counter
		add r4, #1

		@ paint the target pixel so we don't revisit it
		mov r1, #9
		strb r1, [r5]

		@ recurse north
		cmp r7, #0
		beq flood_fill_skip_north
			@ if y > 0, flood_fill(x, y-1)
			mov r2, r6
			sub r3, r7, #1
			bl flood_fill
			add r4, r0
		flood_fill_skip_north:

		@ recurse west
		cmp r6, #0
		beq flood_fill_skip_west
			@ if x > 0, flood_fill(x-1, y)
			sub r2, r6, #1
			mov r3, r7
			bl flood_fill
			add r4, r0
		flood_fill_skip_west:

		@ recurse south
		cmp r7, #(day09_data_height-1)
		beq flood_fill_skip_south
			@ if y < height-1, flood_fill(x, y+1)
			mov r2, r6
			add r3, r7, #1
			bl flood_fill
			add r4, r0
		flood_fill_skip_south:

		@ recurse east
		cmp r6, #(day09_data_width-1)
		beq flood_fill_skip_east
			@ if x < width-1, flood_fill(x+1, y)
			add r2, r6, #1
			mov r3, r7
			bl flood_fill
			add r4, r0
		flood_fill_skip_east:

	flood_fill_done:

	mov r0, r4	@ return size counter
	
	pop {r1-r12}
	pop {lr}
	bx lr
.pool



arm_fn
aoc_day09_part2:
	push {r1-r12,lr}
	
	mov r4, #0 @ 3rd-biggest basin
	mov r5, #0 @ 2nd-biggest basin
	mov r6, #0 @ 1st-biggest basin

	mov r3, #(day09_data_height-1)
	p2_loop_per_row:
		mov r2, #(day09_data_width-1)
		p2_loop_per_col:
			bl flood_fill
			cmp r0, #0
			beq p2_next_cell

				@ test for 1st place
				cmp r0, r6			@ if result >= r6
					movge r4, r5	@ \
					movge r5, r6	@  } insert r0 at the top
					movge r6, r0	@ /
					bge p2_next_cell
				
				@ test for 2nd place
				cmp r0, r5			@ else if result >= r5
					movge r4, r5	@ \
					movge r5, r0	@ / insert r0 at r5
					bge p2_next_cell
				
				@ test for 3rd place
				cmp r0, r4			@ else if result > r4
					movgt r4, r0	@ } insert r0 at r4

			p2_next_cell:
			subs r2, #1
		bge p2_loop_per_col
		subs r3, #1
	bge p2_loop_per_row

	@ return r4*r5*r6
	mul r0, r4, r5
	mul r0, r6

	pop {r1-r12}
	pop {lr}
	bx lr
.pool



arm_fn
main:
	bl setup_for_display

	bl aoc_day09_part1
	mov r1, #0
	bl print_u32_dec

	bl aoc_day09_part2
	mov r1, #1
	bl print_u32_dec

spin_halt:
	b spin_halt
.pool
