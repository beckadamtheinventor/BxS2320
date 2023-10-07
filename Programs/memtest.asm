
include "include/BxS2320.inc"
include "include/defines.inc"

	ldi r8, RAM_START
	ldi r9l, 0xAA55
	ldz r9h
label .loop
	ex r9a, r9b
	str r9a, r8
	inc r8
	dec r9h
	jr nz,.loop

label trap
	jr trap
