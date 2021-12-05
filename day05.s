.section .text
.include "crt0.s"
.include "common.s"
.include "day05-data.s"


.equ line_type_vertical,    0b0001
.equ line_type_horizontal,  0b0010
.equ line_type_diagonal_tl, 0b0100
.equ line_type_diagonal_tr, 0b1000

.equ line_type_vh,  (line_type_vertical | line_type_horizontal)
.equ line_type_all, (line_type_vertical | line_type_horizontal | line_type_diagonal_tl | line_type_diagonal_tr)


@ lovely bit of xor-sort
.macro sort rA, rB
	cmp \rA, \rB
	eorgt \rA, \rB
	eorgt \rB, \rA
	eorgt \rA, \rB
.endm




arm_fn
plot_pixel:
	and r6, r3, #7
	mov r7, #1
	lsl r7, r6

	ldr r6, =0x02000000
	add r6, r3, lsr #3

	ldrb r5, [r6]	@ load from ram
	tst r5, r7		@ check the pixel
	beq plot_pixel_write_hit

	@ if it's already set, check if it's already been hit a second time...
	add r6, #0x20000
	ldrb r5, [r6]	@ load from ram
	tst r5, r7		@ check the pixel
	bne plot_pixel_ret @ if it's been hit a second time already, bail out
	add r11, #1		@ increment the counter if this is the second hit
	@ and then fallthrough into writing the second hit into the second table
plot_pixel_write_hit:
	orr r5, r7		@ set it
	strb r5, [r6]	@ and write it back
	b plot_pixel_ret

plot_pixel_ret:
	bx lr



arm_fn
draw_diagonal_topleft:
	push {lr}
	@ r3 = A.x
	lsl r3, r1, #16
	lsr r3, r3, #16

	@ r4 = A.y
	lsr r4, r1, #16

	@ r5 = B.y
	lsr r5, r2, #16

	add r3, r3, r4, lsl #10 @ r3 = A.y * 1024 + A.x
	sub r4, r5, r4 @ r4 = B.y - A.y

	draw_diagonal_topleft_loop:
		bl plot_pixel
		add r3, #1024
		add r3, #1
		subs r4, #1 @ loop until we've plotted the whole line
	bge draw_diagonal_topleft_loop

	pop {lr}
	bx lr



arm_fn
draw_diagonal_topright:
	push {lr}
	@ r3 = A.x
	lsl r3, r1, #16
	lsr r3, r3, #16

	@ r4 = A.y
	lsr r4, r1, #16

	@ r5 = B.y
	lsr r5, r2, #16

	add r3, r3, r4, lsl #10 @ r3 = A.y * 1024 + A.x
	sub r4, r5, r4 @ r4 = B.y - A.y

	draw_diagonal_topright_loop:
		bl plot_pixel
		add r3, #1024
		sub r3, #1
		subs r4, #1 @ loop until we've plotted the whole line
	bge draw_diagonal_topright_loop

	pop {lr}
	bx lr




arm_fn
draw_horizontal:
	push {lr}
	@ r3 = A.y
	lsr r3, r1, #16

	@ r4 = A.x
	lsl r4, r1, #16
	lsr r4, r4, #16

	@ r5 = B.x
	lsl r5, r2, #16
	lsr r5, r5, #16

	add r3, r4, r3, lsl #10 @ r3 = A.y * 1024 + A.x
	sub r4, r5, r4 @ r4 = B.x - A.x

	draw_horizontal_loop:
		bl plot_pixel
		add r3, #1
		subs r4, #1 @ loop until we've plotted the whole line
	bge draw_horizontal_loop

	pop {lr}
	bx lr




arm_fn
draw_vertical:
	push {lr}
	@ r3 = A.x
	lsl r3, r1, #16
	lsr r3, r3, #16

	@ r4 = A.y
	lsr r4, r1, #16

	@ r5 = B.y
	lsr r5, r2, #16

	add r3, r3, r4, lsl #10 @ r3 = A.y * 1024 + A.x
	sub r4, r5, r4 @ r4 = B.y - A.y

	draw_vertical_loop:
		bl plot_pixel
		add r3, #1024
		subs r4, #1 @ loop until we've plotted the whole line
	bge draw_vertical_loop

	pop {lr}
	bx lr





arm_fn
@ r1: start point
@ r2: end point
get_line_type:
	push {r3-r4}

	@ compare the y component (top 16 bits),
	@ by shifting the bottom 16 bits out
	lsr r3, r1, #16
	lsr r4, r2, #16
	cmp r3, r4
	moveq r0, #line_type_horizontal
	beq get_line_type_ret

	@ compare the x component (bottom 16 bits),
	@ by shifting the top 16 bits out
	lsl r3, r1, #16
	lsl r4, r2, #16
	cmp r3, r4
	moveq r0, #line_type_vertical
	movlt r0, #line_type_diagonal_tl
	movgt r0, #line_type_diagonal_tr

get_line_type_ret:
	pop {r3-r4}
	bx lr
.pool





arm_fn
aoc_day05:
	push {r1-r12,lr}

	@ backup mode mask
	mov r12, r0

	@ set up counter
	mov r11, #0

	@ clear ram
	mov r0, #0x0
	mov r1, #0x02000000
	str r0, [r1]
	mov r0, r1
	ldr r2, =0x01010000
	arm_swi 0x0c @ CpuFastSet


	@ r1-r2: current line (r1 = start point, r2 = end point, each register has X in 16 low bits and Y in 16 high bits)
	@ r8: current line pointer
	@ r9: end line pointer
	@ r11: score counter
	@ r12: mode mask (which line types to include)



	ldr r8, =day05_data_start
	ldr r9, =day05_data_end
	p1_loop_per_line:
		ldmia r8!, {r1-r2} @ load the line into two registers (x component in lower 16 bits, y component in upper 16)
		sort r1, r2	
		bl get_line_type
		tst r0, r12 @ check if it's an allowed line type
		beq p1_next_line

			cmp r0, #line_type_diagonal_tl
			bleq draw_diagonal_topleft

			cmp r0, #line_type_diagonal_tr
			bleq draw_diagonal_topright
		
			cmp r0, #line_type_horizontal
			bleq draw_horizontal
		
			cmp r0, #line_type_vertical
			bleq draw_vertical

		p1_next_line:
		cmp r8, r9
	bne p1_loop_per_line

	mov r0, r11

	pop {r1-r12}
	pop {lr}
	bx lr
.pool


arm_fn
main:
	bl setup_for_display

	mov r0, #line_type_vh
	bl aoc_day05
	mov r1, #0
	bl display_number

	mov r0, #line_type_all
	bl aoc_day05
	mov r1, #1
	bl display_number

spin_halt:
	b spin_halt
.pool
