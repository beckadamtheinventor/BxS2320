
include "include/BxS2321.inc"
include "include/defines.inc"

	ldz r2
	call _inittty
label _main
	call _cleartty
	ldi arg0, menu_main
	call _menu
	cmpi rvala, sk_a
	jr nz,_main
	ldi r8, _mainmenujumps

label _jumptable_r8_rvalb
	ildr r9l, r8
	cmp rvalb, r9l
	jr nc,_main
	inc r8
	add r8, rvalb
	ildr r8l, r8
	pushl 0
	call _cleartty
	jpr r8

label _programsmenu
	call _cleartty
	ldi arg0, menu_programs
	call _menu
	cmpi rvala, sk_b
	ret z
	ldi r8, _programjumps
	jr _jumptable_r8_rvalb

label _mainmenujumps
	dw 7
	dw _infoaboutmenu
	dw _programsmenu
	dw _keytest
	dw _gfxtest
	dw _typingtest
	dw _inputtest
	dw _randinttest
	dw _perftest

label _programjumps
	dw 2
	; dw _boxman
	dw _fibonacci
	dw _main

label str_option_back
	dbs "Back"

label menu_main
	dw .str_title
	dw 0
	dw .str_option_info
	dw .str_option_programs
	dw .str_option_keytest
	dw .str_option_gfxtest
	dw .str_option_typingtest
	dw 0
	dw .str_option_3
	dw .str_option_4
	dw .str_option_5
	dw 0

label .str_title
	dbs "-- Main  Menu --"
label .str_option_programs
	dbs "Programs"
label .str_option_keytest
	dbs "Key test"
label .str_option_gfxtest
	dbs "Graphics test"
label .str_option_typingtest
	dbs "Typing test"
label .str_option_info
	dbs "About"
label .str_option_3
	dbs "Input test"
label .str_option_4
	dbs "Randint test"
label .str_option_5
	dbs "Perf test"


label menu_programs
	dw .str_title
	dw 0
	; dw .str_option_boxman
	dw .str_option_fibonacci
	dw str_option_back
	dw 0

label .str_title
	dbs "--  Programs  --"
label .str_option_boxman
	dbs "Boxman"
label .str_option_fibonacci
	dbs "Fibonacci"

padto $800

virtual as "inc"
	exports::
end virtual

calminstruction (var) strcalc? val
	compute val, val        ; compute expression
	arrange val, val        ; convert result to a decimal token
	stringify val           ; convert decimal token to string
	publish var, val
end calminstruction

macro export? routine
	local address
	address strcalc ($ shr 1)
	jp routine
	dw 0
	virtual exports
		db `routine, $9, ':=', $9, address, $A
	end virtual
end macro
; romcall jump table
	export _memcpy
	export _rmemcpy
	export _strlen
	export _strcpy
	export _strncpy
	export _memcmp
	export _strcmp
	export _strncmp
	export _memset
	export _memcpy_repeat

padto $900
	export _inittty
	export _cleartty
	export _print
	export _printchar
	export _printcharat
	export _printline
	export _printint
	export _printuint
	export _settextxy
	export _nextcol
	export _newline
	export _getkey
	export _waitkey
	export _waitkeycycle
	export _menu

label _menu
	ldi arg1l,$ffff
	ld r10, arg0
label .headerloop
	ildr arg0l, r10
	inc r10
	or arg0l, arg0l
	jr z,.endheaderloop
	call _printline
	jr .headerloop
label .endheaderloop
	ild r7l, TTY_TEXT_ROW_COL
	ld r11a, r7b
	ldi arg1l, $7bde
label .itemsloop
	ildr arg0l, r10
	inc r10
	or arg0l, arg0l
	jr z,.doneitemsloop
	call _nextcol
	call _printline
	jr .itemsloop
label .doneitemsloop
	sub r7b, r11a, r11b
	ldz rvalb
label .menuloop
	add r11a, rvalb, arg2b
	ldz arg2a
	ldi arg0a, '>'
	ldi arg1l, 0x7fff
	call _printcharat
	; push arg2
	call _waitkeycycle
	; pop arg2
	dec arg2b
	sti ' ', arg2
	cmpi rvala, sk_up
	jr z,.moveup
	cmpi rvala, sk_down
	jr z,.movedown
	cmpi rvala, sk_b
	ret z
	cmpi rvala, sk_a
	ret z
	jr .menuloop

label .moveup
	dec rvalb
	jr nc,.menuloop
	ld rvalb, r11b, -1
	jr .menuloop
label .movedown
	inc rvalb
	mod rvalb, r11b
	jr .menuloop

label _waitkeycycle
	call _waitkey ; wait until keypress != 0
	push rvala ; save the keypress
label .loop ; wait until keypress == 0
	call _getkey
	jr nz, .loop
	pop rvala ; restore the keypress
	ret

label _waitkey
	call _getkey
	jr z,_waitkey
	ret

label _getkey
	ild rvala, KEYCODE_ADDR
	or rvala, rvala
	ret

label _memcpy_repeat
	push arg2
	push arg1
	call _memcpy
	pop arg1
	pop arg2
	dec arg3
	jr nz,_memcpy_repeat
	ret

label _memcpy
	ld rval, arg0
label .loop
	ildr r6l, arg1
	str r6l, arg0
	inc arg0
	inc arg1
	dec arg2
	jr nz, .loop
	ret

label _rmemcpy
	ld rval, arg0
label .loop
	ildr r6l, arg1
	str r6l, arg0
	dec arg0
	dec arg1
	dec arg2
	jr nz, .loop
	ret

label _strlen
	ldz rval
label .loop
	ildr r6l, arg0
	or r6l, r6l
	ret z
	inc arg0
	inc rval
	jr .loop

label _strcpy
	ld rval, arg0
label .loop
	ildr r6l, arg1
	str r6l, arg0
	or r6l, r6l
	ret z
	inc arg0
	inc arg1
	jr .loop

label _strncpy
	ld rval, arg0
label .loop
	ildr r6l, arg1
	str r6l, arg0
	or r6l, r6l
	ret z
	inc arg0
	inc arg1
	dec arg2
	ret z
	jr .loop

label _memcmp
	ildr r6l, arg0
	ildr r6h, arg1
	sub r6l, r6h, rval
	ret nz
	inc arg0
	inc arg1
	dec arg2
	ret z
	jr _memcmp

label _strcmp
	ildr r6l, arg0
	ildr r6h, arg1
	sub r6l, r6h, rval
	ret nz
	or r6l, r6h
	ret z
	inc arg0
	inc arg1
	jr _strcmp

label _strncmp
	ildr r6l, arg0
	ildr r6h, arg1
	sub r6l, r6h, rval
	ret nz
	or r6l, r6h
	ret z
	inc arg0
	inc arg1
	dec arg2
	ret z
	jr _strncmp

label _settextxy
	ld r7a, arg0
	ld r7b, arg1
	jr _newline.set_row_col

label _printline
	pushl _newline ; return to newline from _print

label _print
	ld r9, arg0
label .loop
	ildr r6a, r9
	inc r9
	or r6a, r6a
	ret z
	cmpi r6a, $A
	pushl .loop ; return to the loop from _newline or _printchar
	jr z,_newline
	ld arg0a, r6a

label _printchar
	ild r7l, TTY_TEXT_ROW_COL
	ldi r7c, TTY_NUM_COLS
	cmp r7a, r7c
	jr c,.within_row
	ldz r7a
	inc r7b
label .within_row
	mul r7c, r7b
	add r7c, r7a
	ldi r8, GRAM_START
	add r8, r7c
	str arg0a, r8
	inc r8b
	str arg1l, r8

label _nextcol
	ild r7l, TTY_TEXT_ROW_COL
	inc r7a
	cmpi r7a, TTY_NUM_COLS
	jr c,_newline.set_row_col

label _newline
	ild r7l, TTY_TEXT_ROW_COL
label .next_row
	ldz r7a
	inc r7b
	cmpi r7b, TTY_NUM_ROWS
	jr c,.set_row_col
	ldz r7b
label .set_row_col
	sto r7l, TTY_TEXT_ROW_COL
	ret

label _printuint
	ld r9, arg0
	jr _printint.entry

label _printint
	ld r9, arg0
	cmpi r9h, $8000
	jr c,.entry
	ldi arg0, '-'
	call _printchar
	ldz r10
	sub r10, r9, r9 ; 0 - r9 -> r9
label .entry
	ldi r10d, 11
	ldi r10c, 10
	ldi r6, 1000000000
label .loop
	dec r10d
	ret z
	div r9, r6, arg0
	mod arg0, r10c
	addi arg0, '0'
	div r6, r10c
	call _printchar
	jr .loop

label _printcharat
	muli arg2b, TTY_NUM_COLS
	add arg2b, arg2a
	ldi r8, GRAM_START
	add r8, arg2b, arg2
	str arg0a, arg2
	inc arg2b
	str arg1l, arg2
	ret


label _inittty
	ldi r8l, $8000
	sto r8l, GFX_DFLAGS_REG
	ldi r8l, TTY_FONT_LOC and $FFFF
	sto r8l, TTY_FONT_LOC_REG

label _cleartty
	ldi arg0, GRAM_START
assert ~GRAM_START and $FFFF
	sto arg0l, TTY_TEXT_ROW_COL
	ldz arg1l
	ldi arg2, GRAM_SIZE

label _memset
	str arg1l, arg0
	inc arg0
	dec arg2
	jr nz,_memset
	ret


padto $2000

label _infoaboutmenu
	ldi arg0, .str_about
	ldi arg1l, $7fff
	call _print
	jp _waitkeycycle

label .str_about
	dbsl "BxS2320"
	dbsl "Custom CPU Architecture."
	dbsl "Made using a fragment shader and a couple CRTs."
	dw $A
	dbsl "Made by:"
	dbsl " beckadam"
	dw $A
	dbs "Press any key"

label _keytest
	ldz r16a
label .loop
	ldz arg0l
	sto arg0l, TTY_TEXT_ROW_COL
	ldi arg0, .str_info
	ldi arg1l, $7bde
	call _printline
	call _waitkeycycle
	cmpi rvala, sk_b
	jr nz,.b_not_pressed
	inc r16a
	cmpi r16a, 2
	ret nc
	jr .print_keystr
label .b_not_pressed
	ldz r16a
label .print_keystr
	ldi arg0, .keys
	add arg0, rvala
	ildr arg0l, arg0
	ldi arg1l, $7fff
	call _printline
	jr .loop

label .str_info
	dbs "Press keys. Press B twice to go back."
label .keys
	dw 0
	dw .keystr_down
	dw .keystr_left
	dw .keystr_right
	dw .keystr_up
	dw 0
	dw 0
	dw 0
	dw .keystr_a
	dw .keystr_b
	dw .keystr_x
	dw .keystr_y
label .keystr_down
	dbs "Down "
label .keystr_left
	dbs "Left "
label .keystr_right
	dbs "Right"
label .keystr_up
	dbs "Up   "
label .keystr_a
	dbs "A    "
label .keystr_b
	dbs "B    "
label .keystr_x
	dbs "X    "
label .keystr_y
	dbs "Y    "

label _gfxtest
	ldi r8, GRAM_START
	ldi r9, $7FFF
label .loop
	str r9c, r8
	inc r8b
	str r9l, r8
	dec r8b
	inc r8
	inc r9c
	dec r9d
	jr nz,.loop
	call _waitkeycycle
	ldi arg0, GRAM_START
	ldz arg1
	ldi arg2, $100
	call _memset
	; ldi arg0, GRAM_START+$100
	ldi arg1l, .colors1
	ldi arg2a, 8
	ldi arg3, 32
	push arg3
	push arg2
	call _memcpy_repeat
	call _waitkeycycle
	pop arg2
	pop arg3
	ldi arg0, GRAM_START+$100
	ldi arg1, .colors2
	call _memcpy_repeat
	jp _waitkeycycle

label .colors1
	dw $ffff, $fc00, $83e0, $801f, $fc1f, $ffe0, $83ff, $8000

label .colors2
	dw $ffff, $c800, $ca40, $ca52, $8252, $8012, $c812, $ef7b

label _typingtest
	ldi arg0, GRAM_START+$100
	ldi arg1l,$7fff
	ldi arg2, $100
	call _memset
	ldi r12, 'A'
label .loop
	ild r8l, TTY_TEXT_ROW_COL
	ldi r8c, TTY_NUM_COLS
	mul r8c, r8b
	add r8c, r8a
	ldi r9, GRAM_START
	add r9, r8c
	str r12a, r9
	inc r9b
	ldi r8l, $43f0
	str r8l, r9
	push r9
	call _waitkeycycle
	pop r9
	ldi r8l, $7fff
	str r8l, r9
	dec r9b
	cmpi rvala, sk_y
	jr z,.pressed_y
	ldz r12d
	cmpi rvala, sk_b
	jr nz,.notb
	sti 0, r9
	ild r8l, TTY_TEXT_ROW_COL
	dec r8a
	jr nc,.col_over_0
	ldi r8a,$F
	dec r8b
	jr nc,.row_over_0
	ldz r8l
label .row_over_0
label .col_over_0
	sto r8l, TTY_TEXT_ROW_COL
	jr .loop
label .notb
	cmpi rvala, sk_a
	jr nz,.nota
	str r12a, r9
	call _nextcol
	jr .loop
label .nota
	cmpi rvala, sk_up
	jr nz,.notup
	dec r12a
label .notup
	cmpi rvala, sk_down
	jr nz,.notdown
	inc r12a
label .notdown
	cmpi rvala, sk_left
	jr nz,.notleft
	subi r12a, $10
label .notleft
	cmpi rvala, sk_right
	jr nz,.loop
	addi r12a, $10
	jr .loop
label .pressed_y
	inc r12d
	cmpi r12d, 4
	jr c,.loop
	ret

label _inputtest
label _randinttest
label _perftest
	ret

label _fibonacci
	include "C/obj/fibonacci.asm"

label _boxman
	include "C/obj/boxman.asm"
