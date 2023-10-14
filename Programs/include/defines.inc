
rval       = r30
rvall      = r30l
rvalh      = r30h
rvala      = r30a
rvalb      = r30b
rvalc      = r30c
rvald      = r30d
arg0       = r24
arg0l      = r24l
arg0h      = r24h
arg0a      = r24a
arg0b      = r24b
arg0c      = r24c
arg0d      = r24d
arg1       = r25
arg1l      = r25l
arg1h      = r25h
arg1a      = r25a
arg1b      = r25b
arg1c      = r25c
arg2d      = r25d
arg2       = r26
arg2l      = r26l
arg2h      = r26h
arg2a      = r26a
arg2b      = r26b
arg2c      = r26c
arg2d      = r26d
arg3       = r27
arg3l      = r27l
arg3h      = r27h
arg3a      = r27a
arg3b      = r27b
arg3c      = r27c
arg3d      = r27d
arg4       = r28
arg4l      = r28l
arg4h      = r28h
arg4a      = r28a
arg4b      = r28b
arg4c      = r28c
arg4d      = r28d
arg5       = r29
arg5l      = r29l
arg5h      = r29h
arg5a      = r29a
arg5b      = r29b
arg5c      = r29c
arg5d      = r29d

sk_down          := 1
sk_left          := 2
sk_right         := 3
sk_up            := 4
sk_a             := 8
sk_b             := 9
sk_x             := 10
sk_y             := 11

TTY_NUM_ROWS     := 16
TTY_NUM_COLS     := 16

RAM_START        := $F0000000
RAM_END          := $F000FFFF
RAM_SIZE         := $00010000
GRAM_START       := $F1000000
GRAM_END         := $F10001FF
GRAM_SIZE        := $00000200
FRAM_START       := $F2000000
FRAM_END         := $F20000FF
FRAM_SIZE        := $00000080

TTY_FONT_LOC     := RAM_START + $E000
KEYCODE_ADDR     := RAM_START + $FFF0
TTY_FONT_LOC_REG := RAM_START + $FFFE
GFX_DFLAGS_REG   := RAM_START + $FFFF

TTY_TEXT_ROW_COL := FRAM_START + $0000

macro align? amount, val:0
	if ($ shr 1) and (amount - 1)
		repeat amount - (($ shr 1) and (amount - 1))
			ddb val
		end repeat
	end if
end macro

macro padto? address, val:0
	if ($ shr 1) < address
		repeat address - ($ shr 1)
			ddb val
		end repeat
	else
		err "failed to pad to address, already past that address"
	end if
end macro

macro section_at? addr
	virtual at (addr shl 1)
	macro end?.section_at?
		local data
		load data: $-$$ from $$
		end virtual
		db data
		purge end?.section_at?
	end macro
end macro

macro c_call? cond, fname, args&
	local argument_register, dontcall
	argument_register = arg0
	if cond <> always
		if cond = c
			jp nc, dontcall
		else if cond = s
			jp ns, dontcall
		else if cond = z
			jp nz, dontcall
		else
			err "Invalid condition to c_call"
		end if
	end if
	iterate arg, args
		if argument_register <= arg5
			if arg <> argument_register
				ld argument_register, arg
			end if
		else
			push arg
		end if
		argument_register = argument_register + 1
	end iterate
	call fname
	if argument_register = arg5
		pop r8
	else if argument_register > arg5
		add r2, 2*(argument_register - arg5)
	end if
	dontcall = $ shr 1
end macro

macro return? value
	ld r16, value
	ret
end macro

macro argument? reg, argno:0
	if argno > 5
		err "argument macro can only be used for functions with 6 or less arguments"
	else
		ld reg, arg0+argno
	end if
end macro

macro expr? reg, args&
	iterate arg, args
		match +jval, arg
			add reg, val
		else match -jval, arg
			sub reg, val
		else match *jval, arg
			mul reg, val
		else match /jval, arg
			div reg, val
		else match &jval, arg
			and reg, val
		else match |jval, arg
			or reg, val
		else match =^jval, arg
			xor reg, val
		else match ==jval, arg
			ld reg, val
		else
			display `arg
			err "Invalid operation to expr"
		end match
	end iterate
end macro


