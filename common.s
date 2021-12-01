.macro arm_swi id
	swi (\id << 16)
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



.arm
display_number:
	push {r0-r2}
	ldr r2, =0x06000020
	add r2, r1, lsl #6

display_number_loop:
	@ div/mod by 10
	mov r1, #10
	arm_swi 0x06 @ div

	@ store modulo value to vram and decrement the write pointer
	add r1, #1
	strh r1, [r2]
	sub r2, #2

	@ loop until the value is zero
	cmp r0, #0
	bne display_number_loop

	pop {r0-r2}
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
