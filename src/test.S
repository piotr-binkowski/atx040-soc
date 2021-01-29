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
	move.l #0x00100000, %a0
1:
	move.l %d0, (%a0)
	move.l (%a0), %d1
	add.l #4, %a0
	dbeq %d0, 1b

	bra.s _start

