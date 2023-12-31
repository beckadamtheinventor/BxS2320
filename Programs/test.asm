
include "include/BxS2321.inc"
include "include/defines.inc"

	ldz r2
	testhalt r2, 0
	
	ldi r8, $DEADBEEF
	testhalt r8, $DEADBEEF
	ldi r9a, $AA
	ldi r9b, $55
	ldi r9c, $5A
	ldi r9d, $A5
	testhalt r9, $A55A55AA
	ld r10d,r9a
	ld r10c,r9b
	ld r10b,r9c
	ld r10a,r9d
	testhalt r10, $AA555AA5
	ld r11l,r9h
	ld r11h,r9l
	testhalt r11, $55AAA55A
	
	ex r11,r8
	testhalt r8, $55AAA55A
	testhalt r11, $DEADBEEF
	ex r10l,r10h
	testhalt r10, $5AA5AA55
	ex r9a,r9c
	testhalt r9, $A5AA555A

	add r8, r9, r12
	testhalt r12, $FB54FAB4
	sub r8, r9, r13
	testhalt r13, $B0005000
	mul r8, r9, r14
	testhalt r14, $96A903A4
	div r8, r9, r15
	testhalt r15, $00000000
	mod r8, r9, r16
	testhalt r16, $55AAA55A

	ild r8l, _testdata
	testhalt r8l, 12345
	ild r8h, _testdata+1
	testhalt r8h, 6789
	ldi r8, _testdata
	ildr r9l, r8
	testhalt r9l, 12345
	ildr r9h, r8, 1
	testhalt r9h, 6789
	
	ldi r8, 1234567
	sto r8, $F0000001
	ild r9, $F0000001
	testhalt r9, 1234567
	
	ldi r10, $F000FFFE
	ldi r8l, $8000
	str r8l, r10, 1
	ildr r9l, r10, 1
	testhalt r9l, $8000

	ldi r8l, $E000
	str r8l, r10, 0
	ildr r9l, r10, 0
	testhalt r9l, $E000
	
	ldi r8l, $41
	sto r8l, $F1000000
	ild r9l, $F1000000
	testhalt r9l, $41

	ldi r8l, $FFFF
	sto r8l, $F1000100
	ild r9l, $F1000100
	testhalt r9l, $FFFF

	ldi r8l, 1011
	sto r8l, $F2000000
	ild r9l, $F2000000
	testhalt r9l, 1011

	call _routine_a
	call _routine_b

label trap
	jr trap

label _routine_a
	ldi r6,$F10001FF
label .loop
	sto r6c, r6
	dec r6l
	jr nz,.loop
	ret

label _routine_b
	ldi r7,$FF0000FF
label .loop
	inc r7h
	dec r7l
	ret z
	jr .loop

label _testdata
	dw 12345
	dw 6789
