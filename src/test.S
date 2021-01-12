.long 0x00000000
.long _start

_start:
	nop
	nop
	nop
	nop
	move.l #0x30313233, 0x80000000
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	jmp _start

