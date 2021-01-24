.long 0x00000000
.long 0x10000008

_start:
	nop
	move.b #'A', 0x30000000
	move.b #'B', 0x30000000
	move.b #'C', 0x30000000
	move.b #'D', 0x30000000
	move.b #'\r', 0x30000000
	move.b #'\n', 0x30000000
	move.w #0x6000, %d0
loop:
	dbeq %d0, loop
	bra.s _start

