.long 0x00000000
.long 0x40000008

_start:
	nop
	move.b #'A', 0xC0000000
	move.b #'B', 0xC0000000
	move.b #'C', 0xC0000000
	move.b #'D', 0xC0000000
	
	move.b #'\r', 0xC0000000
	move.b #'\n', 0xC0000000

	move.w #0x6000, %d0
1:
	dbeq %d0, 1b

	bra.s _start
