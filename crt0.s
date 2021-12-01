.global _start

.arm
_start:
	b _crt_main

@ rest of cart header,
@ will be populated by gbafix
.zero 0xbc


.arm
_crt_main:
	@ set supervisor stack
	mov r0, #0xd2
	msr cpsr_cf, r0
	ldr sp, =0x03007fa0

	@ set user stack
	mov r0, #0x1f
	msr cpsr_cf, r0
	ldr sp, =0x03007f00
	
	@ set interrupt handler
	ldr r9, =0x03007ffc
	ldr r0, =irq_handler
	str r0, [r1, #0x0]

	@ call main!
	ldr r0, =main
	mov lr, pc
	bx r0

	b _crt_main
.pool


.arm
@ dummy handler, does nothing
irq_handler:
	ldr r0, =0x04000200
	ldr r1, [r0, #0] @ read both IE and IF
	and r1, r1, r1, lsr #16 @ mask them together
	strh r1, [r0, #2] @ write back to IF, to acknowledge the request
	bx lr
.pool
