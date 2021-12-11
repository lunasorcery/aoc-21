.macro arm_swi id
	swi (\id << 16)
.endm

.macro arm_fn
	.balign 4
	.arm
.endm



.arm
setup_for_display:
	@ enable BG0
	ldr r0, =0x04000000
	mov r1, #0x0100
	strh r1, [r0]

	@ set up BG0 settings (bank addresses)
	ldr r0, =0x04000008
	mov r1, #0x0004
	strh r1, [r0]

	@ copy font to vram
	ldr r0, =font_data_start
	ldr r1, =0x06004020
	ldr r2, =font_data_cpuset_info
	arm_swi 0x0b @ CpuSet

	@ set up palette
	ldr r0, =0x05000000
	ldr r1, =0x7fff0000
	str r1, [r0]

	bx lr
.pool



arm_fn
@ inputs:
@ r0: value
@ r1: screen row to display on
print_u32_dec:
display_number:
	push {r0-r3}
	ldr r2, =0x06000030
	add r2, r1, lsl #6

display_number_loop:
	@ div/mod by 10
	mov r1, #10
	arm_swi 0x06 @ div (stomps r3)

	@ store modulo value to vram and decrement the write pointer
	add r1, #1
	strh r1, [r2]
	sub r2, #2

	@ loop until the value is zero
	cmp r0, #0
	bne display_number_loop

	pop {r0-r3}
	bx lr
.pool





arm_fn
@ adapted from http://homepage.cs.uiowa.edu/~jones/bcd/decimal.html
@ inputs:
@ r0: value, low bits
@ r1: value, high bits
@ r2: screen row to display on
.global print_u64_dec
print_u64_dec:
	@ cheap trick:
	@ if the input is < 2^32, just use the u32 function instead
	@cmp r1, #0
	@moveq r1, r2
	@beq print_u32_dec

	@ otherwise, do this for reals:
	push {r0-r12,lr}

	ldr r7, =0xffff
	and r4, r0, r7		@ d0 = n       & 0xFFFF;
	lsr r5, r0, #16		@ d1 = (n>>16) & 0xFFFF;
	and r6, r1, r7		@ d2 = (n>>32) & 0xFFFF;
	lsr r7, r1, #16		@ d3 = (n>>48) & 0xFFFF;

	@ d0 = 656 * d3 + 7296 * d2 + 5536 * d1 + d0;
	ldr r3, =5536
	mla r4, r5, r3, r4 @ d0 = d1 * 5536 + d0
	ldr r3, =7296
	mla r4, r6, r3, r4 @ d0 = d2 * 7296 + d0
	ldr r3, =656
	mla r4, r7, r3, r4 @ d0 = d3 * 656 + d0
	
	@ q = d0 / 10000;
	@ d0 = d0 % 10000;
	mov r0, r4		@ r0 = d0
	ldr r1, =10000	@ r1 = 10000
	arm_swi 0x06 @ div
	mov r8, r0	@ q = d0 / 10000;
	mov r4, r1	@ d0 = d0 % 10000;

	@ d1 = q + 7671 * d3 + 9496 * d2 + 6 * d1;
	mov r3, #6
	mul r5, r3	@ d1 *= 6
	add r5, r8	@ d1 += q
	ldr r3, =9496
	mla r5, r6, r3, r5 @ d1 = d2 * 9496 + d1
	ldr r3, =7671
	mla r5, r7, r3, r5 @ d1 = d3 * 7671 + d1

	@ q = d1 / 10000;
	@ d1 = d1 % 10000;
	mov r0, r5		@ r0 = d1
	ldr r1, =10000	@ r1 = 10000
	arm_swi 0x06 @ div
	mov r8, r0	@ q = d1 / 10000;
	mov r5, r1	@ d1 = d1 % 10000;

	@ d2 = q + 4749 * d3 + 42 * d2;
	mov r3, #42
	mul r6, r3	@ d2 *= 42
	add r6, r8	@ d2 += q
	ldr r3, =4749
	mla r6, r7, r3, r6 @ d2 = d3 * 4749 + d2

	@ q = d2 / 10000;
	@ d2 = d2 % 10000;
	mov r0, r6		@ r0 = d2
	ldr r1, =10000	@ r1 = 10000
	arm_swi 0x06 @ div
	mov r8, r0	@ q = d2 / 10000;
	mov r6, r1	@ d2 = d2 % 10000;

	@ d3 = q + 281 * d3;
	ldr r3, =281
	mul r7, r3 @ d3 *= 281
	add r7, r8 @ d3 += q

	@ q = d3 / 10000;
	@ d3 = d3 % 10000;
	mov r0, r7		@ r0 = d3
	ldr r1, =10000	@ r1 = 10000
	arm_swi 0x06 @ div
	mov r8, r0	@ q = d3 / 10000;
	mov r7, r1	@ d3 = d3 % 10000;

	@ d4 = q;
	@ ^ implict, as d4 is already in r8


	@ prepare vram pointer
	ldr r3, =0x06000030
	add r2, r3, r2, lsl #6

	.macro print_dec_four_digits
	.rept 4
		mov r1, #10
		arm_swi 0x06 @ div (remember this stomps r3 too)
		add r1, #1
		strh r1, [r2]
		sub r2, #2
	.endr
	.endm

	mov r0, r4
	print_dec_four_digits
	mov r0, r5
	print_dec_four_digits
	mov r0, r6
	print_dec_four_digits
	mov r0, r7
	print_dec_four_digits
	mov r0, r8
	print_dec_four_digits

	pop {r0-r12}
	pop {lr}
	bx lr
.pool





@ font data
.equ font_data_cpuset_info, 0x04000000+(font_data_end-font_data_start)/4

.balign 4
font_data_start:
	.4byte 0x00011100
	.4byte 0x00110010
	.4byte 0x01100011
	.4byte 0x01100011
	.4byte 0x01100011
	.4byte 0x00100110
	.4byte 0x00011100
	.4byte 0x00000000

	.4byte 0x00011000
	.4byte 0x00011100
	.4byte 0x00011000
	.4byte 0x00011000
	.4byte 0x00011000
	.4byte 0x00011000
	.4byte 0x01111110
	.4byte 0x00000000

	.4byte 0x00111110
	.4byte 0x01100011
	.4byte 0x01110000
	.4byte 0x00111100
	.4byte 0x00011110
	.4byte 0x00000111
	.4byte 0x01111111
	.4byte 0x00000000

	.4byte 0x01111110
	.4byte 0x00110000
	.4byte 0x00011000
	.4byte 0x00111100
	.4byte 0x01100000
	.4byte 0x01100011
	.4byte 0x00111110
	.4byte 0x00000000

	.4byte 0x00111000
	.4byte 0x00111100
	.4byte 0x00110110
	.4byte 0x00110011
	.4byte 0x01111111
	.4byte 0x00110000
	.4byte 0x00110000
	.4byte 0x00000000

	.4byte 0x00111111
	.4byte 0x00000011
	.4byte 0x00111111
	.4byte 0x01100000
	.4byte 0x01100000
	.4byte 0x01100011
	.4byte 0x00111110
	.4byte 0x00000000

	.4byte 0x00111100
	.4byte 0x00000110
	.4byte 0x00000011
	.4byte 0x00111111
	.4byte 0x01100011
	.4byte 0x01100011
	.4byte 0x00111110
	.4byte 0x00000000

	.4byte 0x01111111
	.4byte 0x01100011
	.4byte 0x00110000
	.4byte 0x00011000
	.4byte 0x00001100
	.4byte 0x00001100
	.4byte 0x00001100
	.4byte 0x00000000

	.4byte 0x00111110
	.4byte 0x01100011
	.4byte 0x01100011
	.4byte 0x00111110
	.4byte 0x01100011
	.4byte 0x01100011
	.4byte 0x00111110
	.4byte 0x00000000

	.4byte 0x00111110
	.4byte 0x01100011
	.4byte 0x01100011
	.4byte 0x01111110
	.4byte 0x01100000
	.4byte 0x00110000
	.4byte 0x00011110
	.4byte 0x00000000
font_data_end:





popcount_table:
	.byte 0+0+0+0+0+0+0+0
	.byte 0+0+0+0+0+0+0+1
	.byte 0+0+0+0+0+0+1+0
	.byte 0+0+0+0+0+0+1+1
	.byte 0+0+0+0+0+1+0+0
	.byte 0+0+0+0+0+1+0+1
	.byte 0+0+0+0+0+1+1+0
	.byte 0+0+0+0+0+1+1+1
	.byte 0+0+0+0+1+0+0+0
	.byte 0+0+0+0+1+0+0+1
	.byte 0+0+0+0+1+0+1+0
	.byte 0+0+0+0+1+0+1+1
	.byte 0+0+0+0+1+1+0+0
	.byte 0+0+0+0+1+1+0+1
	.byte 0+0+0+0+1+1+1+0
	.byte 0+0+0+0+1+1+1+1
	.byte 0+0+0+1+0+0+0+0
	.byte 0+0+0+1+0+0+0+1
	.byte 0+0+0+1+0+0+1+0
	.byte 0+0+0+1+0+0+1+1
	.byte 0+0+0+1+0+1+0+0
	.byte 0+0+0+1+0+1+0+1
	.byte 0+0+0+1+0+1+1+0
	.byte 0+0+0+1+0+1+1+1
	.byte 0+0+0+1+1+0+0+0
	.byte 0+0+0+1+1+0+0+1
	.byte 0+0+0+1+1+0+1+0
	.byte 0+0+0+1+1+0+1+1
	.byte 0+0+0+1+1+1+0+0
	.byte 0+0+0+1+1+1+0+1
	.byte 0+0+0+1+1+1+1+0
	.byte 0+0+0+1+1+1+1+1
	.byte 0+0+1+0+0+0+0+0
	.byte 0+0+1+0+0+0+0+1
	.byte 0+0+1+0+0+0+1+0
	.byte 0+0+1+0+0+0+1+1
	.byte 0+0+1+0+0+1+0+0
	.byte 0+0+1+0+0+1+0+1
	.byte 0+0+1+0+0+1+1+0
	.byte 0+0+1+0+0+1+1+1
	.byte 0+0+1+0+1+0+0+0
	.byte 0+0+1+0+1+0+0+1
	.byte 0+0+1+0+1+0+1+0
	.byte 0+0+1+0+1+0+1+1
	.byte 0+0+1+0+1+1+0+0
	.byte 0+0+1+0+1+1+0+1
	.byte 0+0+1+0+1+1+1+0
	.byte 0+0+1+0+1+1+1+1
	.byte 0+0+1+1+0+0+0+0
	.byte 0+0+1+1+0+0+0+1
	.byte 0+0+1+1+0+0+1+0
	.byte 0+0+1+1+0+0+1+1
	.byte 0+0+1+1+0+1+0+0
	.byte 0+0+1+1+0+1+0+1
	.byte 0+0+1+1+0+1+1+0
	.byte 0+0+1+1+0+1+1+1
	.byte 0+0+1+1+1+0+0+0
	.byte 0+0+1+1+1+0+0+1
	.byte 0+0+1+1+1+0+1+0
	.byte 0+0+1+1+1+0+1+1
	.byte 0+0+1+1+1+1+0+0
	.byte 0+0+1+1+1+1+0+1
	.byte 0+0+1+1+1+1+1+0
	.byte 0+0+1+1+1+1+1+1
	.byte 0+1+0+0+0+0+0+0
	.byte 0+1+0+0+0+0+0+1
	.byte 0+1+0+0+0+0+1+0
	.byte 0+1+0+0+0+0+1+1
	.byte 0+1+0+0+0+1+0+0
	.byte 0+1+0+0+0+1+0+1
	.byte 0+1+0+0+0+1+1+0
	.byte 0+1+0+0+0+1+1+1
	.byte 0+1+0+0+1+0+0+0
	.byte 0+1+0+0+1+0+0+1
	.byte 0+1+0+0+1+0+1+0
	.byte 0+1+0+0+1+0+1+1
	.byte 0+1+0+0+1+1+0+0
	.byte 0+1+0+0+1+1+0+1
	.byte 0+1+0+0+1+1+1+0
	.byte 0+1+0+0+1+1+1+1
	.byte 0+1+0+1+0+0+0+0
	.byte 0+1+0+1+0+0+0+1
	.byte 0+1+0+1+0+0+1+0
	.byte 0+1+0+1+0+0+1+1
	.byte 0+1+0+1+0+1+0+0
	.byte 0+1+0+1+0+1+0+1
	.byte 0+1+0+1+0+1+1+0
	.byte 0+1+0+1+0+1+1+1
	.byte 0+1+0+1+1+0+0+0
	.byte 0+1+0+1+1+0+0+1
	.byte 0+1+0+1+1+0+1+0
	.byte 0+1+0+1+1+0+1+1
	.byte 0+1+0+1+1+1+0+0
	.byte 0+1+0+1+1+1+0+1
	.byte 0+1+0+1+1+1+1+0
	.byte 0+1+0+1+1+1+1+1
	.byte 0+1+1+0+0+0+0+0
	.byte 0+1+1+0+0+0+0+1
	.byte 0+1+1+0+0+0+1+0
	.byte 0+1+1+0+0+0+1+1
	.byte 0+1+1+0+0+1+0+0
	.byte 0+1+1+0+0+1+0+1
	.byte 0+1+1+0+0+1+1+0
	.byte 0+1+1+0+0+1+1+1
	.byte 0+1+1+0+1+0+0+0
	.byte 0+1+1+0+1+0+0+1
	.byte 0+1+1+0+1+0+1+0
	.byte 0+1+1+0+1+0+1+1
	.byte 0+1+1+0+1+1+0+0
	.byte 0+1+1+0+1+1+0+1
	.byte 0+1+1+0+1+1+1+0
	.byte 0+1+1+0+1+1+1+1
	.byte 0+1+1+1+0+0+0+0
	.byte 0+1+1+1+0+0+0+1
	.byte 0+1+1+1+0+0+1+0
	.byte 0+1+1+1+0+0+1+1
	.byte 0+1+1+1+0+1+0+0
	.byte 0+1+1+1+0+1+0+1
	.byte 0+1+1+1+0+1+1+0
	.byte 0+1+1+1+0+1+1+1
	.byte 0+1+1+1+1+0+0+0
	.byte 0+1+1+1+1+0+0+1
	.byte 0+1+1+1+1+0+1+0
	.byte 0+1+1+1+1+0+1+1
	.byte 0+1+1+1+1+1+0+0
	.byte 0+1+1+1+1+1+0+1
	.byte 0+1+1+1+1+1+1+0
	.byte 0+1+1+1+1+1+1+1
	.byte 1+0+0+0+0+0+0+0
	.byte 1+0+0+0+0+0+0+1
	.byte 1+0+0+0+0+0+1+0
	.byte 1+0+0+0+0+0+1+1
	.byte 1+0+0+0+0+1+0+0
	.byte 1+0+0+0+0+1+0+1
	.byte 1+0+0+0+0+1+1+0
	.byte 1+0+0+0+0+1+1+1
	.byte 1+0+0+0+1+0+0+0
	.byte 1+0+0+0+1+0+0+1
	.byte 1+0+0+0+1+0+1+0
	.byte 1+0+0+0+1+0+1+1
	.byte 1+0+0+0+1+1+0+0
	.byte 1+0+0+0+1+1+0+1
	.byte 1+0+0+0+1+1+1+0
	.byte 1+0+0+0+1+1+1+1
	.byte 1+0+0+1+0+0+0+0
	.byte 1+0+0+1+0+0+0+1
	.byte 1+0+0+1+0+0+1+0
	.byte 1+0+0+1+0+0+1+1
	.byte 1+0+0+1+0+1+0+0
	.byte 1+0+0+1+0+1+0+1
	.byte 1+0+0+1+0+1+1+0
	.byte 1+0+0+1+0+1+1+1
	.byte 1+0+0+1+1+0+0+0
	.byte 1+0+0+1+1+0+0+1
	.byte 1+0+0+1+1+0+1+0
	.byte 1+0+0+1+1+0+1+1
	.byte 1+0+0+1+1+1+0+0
	.byte 1+0+0+1+1+1+0+1
	.byte 1+0+0+1+1+1+1+0
	.byte 1+0+0+1+1+1+1+1
	.byte 1+0+1+0+0+0+0+0
	.byte 1+0+1+0+0+0+0+1
	.byte 1+0+1+0+0+0+1+0
	.byte 1+0+1+0+0+0+1+1
	.byte 1+0+1+0+0+1+0+0
	.byte 1+0+1+0+0+1+0+1
	.byte 1+0+1+0+0+1+1+0
	.byte 1+0+1+0+0+1+1+1
	.byte 1+0+1+0+1+0+0+0
	.byte 1+0+1+0+1+0+0+1
	.byte 1+0+1+0+1+0+1+0
	.byte 1+0+1+0+1+0+1+1
	.byte 1+0+1+0+1+1+0+0
	.byte 1+0+1+0+1+1+0+1
	.byte 1+0+1+0+1+1+1+0
	.byte 1+0+1+0+1+1+1+1
	.byte 1+0+1+1+0+0+0+0
	.byte 1+0+1+1+0+0+0+1
	.byte 1+0+1+1+0+0+1+0
	.byte 1+0+1+1+0+0+1+1
	.byte 1+0+1+1+0+1+0+0
	.byte 1+0+1+1+0+1+0+1
	.byte 1+0+1+1+0+1+1+0
	.byte 1+0+1+1+0+1+1+1
	.byte 1+0+1+1+1+0+0+0
	.byte 1+0+1+1+1+0+0+1
	.byte 1+0+1+1+1+0+1+0
	.byte 1+0+1+1+1+0+1+1
	.byte 1+0+1+1+1+1+0+0
	.byte 1+0+1+1+1+1+0+1
	.byte 1+0+1+1+1+1+1+0
	.byte 1+0+1+1+1+1+1+1
	.byte 1+1+0+0+0+0+0+0
	.byte 1+1+0+0+0+0+0+1
	.byte 1+1+0+0+0+0+1+0
	.byte 1+1+0+0+0+0+1+1
	.byte 1+1+0+0+0+1+0+0
	.byte 1+1+0+0+0+1+0+1
	.byte 1+1+0+0+0+1+1+0
	.byte 1+1+0+0+0+1+1+1
	.byte 1+1+0+0+1+0+0+0
	.byte 1+1+0+0+1+0+0+1
	.byte 1+1+0+0+1+0+1+0
	.byte 1+1+0+0+1+0+1+1
	.byte 1+1+0+0+1+1+0+0
	.byte 1+1+0+0+1+1+0+1
	.byte 1+1+0+0+1+1+1+0
	.byte 1+1+0+0+1+1+1+1
	.byte 1+1+0+1+0+0+0+0
	.byte 1+1+0+1+0+0+0+1
	.byte 1+1+0+1+0+0+1+0
	.byte 1+1+0+1+0+0+1+1
	.byte 1+1+0+1+0+1+0+0
	.byte 1+1+0+1+0+1+0+1
	.byte 1+1+0+1+0+1+1+0
	.byte 1+1+0+1+0+1+1+1
	.byte 1+1+0+1+1+0+0+0
	.byte 1+1+0+1+1+0+0+1
	.byte 1+1+0+1+1+0+1+0
	.byte 1+1+0+1+1+0+1+1
	.byte 1+1+0+1+1+1+0+0
	.byte 1+1+0+1+1+1+0+1
	.byte 1+1+0+1+1+1+1+0
	.byte 1+1+0+1+1+1+1+1
	.byte 1+1+1+0+0+0+0+0
	.byte 1+1+1+0+0+0+0+1
	.byte 1+1+1+0+0+0+1+0
	.byte 1+1+1+0+0+0+1+1
	.byte 1+1+1+0+0+1+0+0
	.byte 1+1+1+0+0+1+0+1
	.byte 1+1+1+0+0+1+1+0
	.byte 1+1+1+0+0+1+1+1
	.byte 1+1+1+0+1+0+0+0
	.byte 1+1+1+0+1+0+0+1
	.byte 1+1+1+0+1+0+1+0
	.byte 1+1+1+0+1+0+1+1
	.byte 1+1+1+0+1+1+0+0
	.byte 1+1+1+0+1+1+0+1
	.byte 1+1+1+0+1+1+1+0
	.byte 1+1+1+0+1+1+1+1
	.byte 1+1+1+1+0+0+0+0
	.byte 1+1+1+1+0+0+0+1
	.byte 1+1+1+1+0+0+1+0
	.byte 1+1+1+1+0+0+1+1
	.byte 1+1+1+1+0+1+0+0
	.byte 1+1+1+1+0+1+0+1
	.byte 1+1+1+1+0+1+1+0
	.byte 1+1+1+1+0+1+1+1
	.byte 1+1+1+1+1+0+0+0
	.byte 1+1+1+1+1+0+0+1
	.byte 1+1+1+1+1+0+1+0
	.byte 1+1+1+1+1+0+1+1
	.byte 1+1+1+1+1+1+0+0
	.byte 1+1+1+1+1+1+0+1
	.byte 1+1+1+1+1+1+1+0
	.byte 1+1+1+1+1+1+1+1