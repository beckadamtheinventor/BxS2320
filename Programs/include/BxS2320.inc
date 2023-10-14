
r0  := 0
r0l := 32
r0h := 64
r0a := 96
r0b := 128
r0c := 160
r0d := 192
r0f := 224

repeat 31
	r#% := %
	r#%#l := %+32
	r#%#h := %+64
	r#%#a := %+96
	r#%#b := %+128
	r#%#c := %+160
	r#%#d := %+192
	r#%#f := %+224
end repeat

c := 0
nc := 1
z := 2
nz := 3
s := 4
ns := 5
never := 6
always := 7

macro label? name
	virtual at ($ shr 1)
		name:
	end virtual
	if $ and 1 <> 0
		err "label", `name, " is misaligned. All labels must be word aligned"
	end if
end macro

macro nop?
	dw 0
end macro

calminstruction (var) strcalc? val
	compute val, val        ; compute expression
	arrange val, val        ; convert result to a decimal token
	stringify val           ; convert decimal token to string
	publish var, val
end calminstruction


macro jr? arg&
	local here
	here = ($ shr 1) + 1
	match cc=, addr, arg
		if addr-here < -128 | addr-here >= 128
			err "jr offset out of range. Must be within -128<=x<=127"
		end if
		db $F0 or cc, addr-here
	else
		if arg-here < -128 | arg-here >= 128
			err "jr offset out of range. Must be within -128<=x<=127"
		end if
		db $F7, arg-here
	end match
end macro

macro jp? arg&
	match cc=, addr, arg
		db $E0 or cc, 0
		dd addr
	else
		db $E7, 0
		dd arg
	end match
end macro

macro jq? arg&
	local here
	here = ($ shr 1) + 1
	match cc=, addr, arg
		if addr-here >= -128 & addr-here < 128
			jr cc, addr
		else
			jp cc, addr
		end if
	else
		if arg-here >= -128 & arg-here < 128
			jr arg
		else
			jp arg
		end if
	end match
end macro

macro jpr? arg&
	match cc=, addr, arg
		db $E8 or cc, addr
	else
		db $EF, arg
	end match
end macro

macro call? arg&
	match cc=, addr, arg
		db $D0 or cc, 0
		dd addr
	else
		db $D7, 0
		dd arg
	end match
end macro

macro callr? arg&
	match cc=, addr, arg
		db $D8 or cc, addr
	else
		db $DF, arg
	end match
end macro

macro push? reg
	if reg < 256
		db $C0, reg
	else
		err "Invalid opcode argument. Should be 'push reg'"
	end if
end macro

macro pushb? val
	db $C4, val
end macro

macro pushw? val
	db $C5, 0
	dw val
end macro

macro pushl? val
	db $C6, 0
	dd val
end macro

macro pop? reg
	if reg < 256
		db $C1, reg
	else
		err "Invalid opcode argument. Should be 'push reg'"
	end if
end macro

macro ret? cc:always
	db $C8 or cc, 0
end macro

macro ld? dreg, sreg, offset:0
	if dreg < 256 & sreg < 256
		db $01, dreg, sreg, offset
	else
		err "Invalid opcode argument. Should be 'ld dreg, sreg'"
	end if
end macro
define load ld

macro ldz? dreg
	if dreg < 256
		db $02, dreg
	else
		err "Invalid opcode argument. Should be 'ldz dreg'"
	end if
end macro

macro ldi? dreg, val
	if dreg < 256
		db $03, dreg
		if dreg < r0l
			dd val
		else if dreg < r0a
			dw val
		else if dreg < r0f
			db val, 0
		else
			dd val
		end if
	else
		err "Invalid opcode argument. Should be 'ldi dreg'"
	end if
end macro

macro ex? dreg, sreg, offset:0
	if dreg < 256 & sreg < 256
		db $04, dreg, sreg, offset
	else
		err "Invalid opcode argument. Should be 'ld dreg, sreg'"
	end if
end macro

macro delay? reg
	if reg < 256
		db $F8, reg and $FF
	else
		err "Invalid opcode argument. Should be 'delay reg'"
	end if
end macro

macro testhalt? reg, val
	if reg < 256
		db $FF, reg and $FF
		if reg < r0l
			dd val
		else if reg < r0a
			dw val
		else if reg < r0f
			db val, 0
		else
			dd val
		end if
	else
		err "Invalid opcode argument. Should be 'testhalt reg, value'"
	end if
end macro


; load indirect sreg+offset -> dreg
macro ildr? dreg, sreg, offset:0
	if sreg < 256 & dreg < 256
		db $05, dreg, sreg, offset
	else
		err "Invalid opcode argument. Should be 'ildr sreg, dreg' or 'ildr sreg, dreg, offset'"
	end if
end macro

; load indirect immediate -> dreg
macro ild? dreg, val
	if dreg < 256
		db $06, dreg
		dd val
	else
		err "Invalid opcode argument. Should be 'ild sreg, imm32'"
	end if
end macro

; store sreg -> dreg+offset
macro str? sreg, dreg, offset:0
	if sreg < 256 & dreg < 256
		db $07, sreg, dreg, offset
	else
		err "Invalid opcode argument. Should be 'str sreg, dreg' or 'str sreg, dreg, offset'"
	end if
end macro

; store byte val -> dreg+offset
macro sti? val, dreg, offset:0
	if dreg < 256
		db $08, val, dreg, offset
	else
		err "Invalid opcode argument. Should be 'sti val, dreg' or 'sti val, dreg, offset'"
	end if
end macro

; store sreg -> val
macro sto? sreg, val
	if sreg < 256
		db $09, sreg
		dd val
	else
		err "Invalid opcode argument. Should be 'sto sreg, imm32'"
	end if
end macro

macro inc? reg
	if reg < 256
		db $0A, reg
	else
		err "Invalid opcode argument. Should be 'inc reg'"
	end if
end macro

macro dec? reg
	if reg < 256
		db $0B, reg
	else
		err "Invalid opcode argument. Should be 'inc reg'"
	end if
end macro

macro flagand? val
	db $0C, val
end macro

macro flagor? val
	db $0D, val
end macro

macro flagxor? val
	db $0E, val
end macro

; store sreg -> dreg+dreg2
macro strr? sreg, dreg, dreg2
	if sreg < 256 & dreg < 256 & dreg2 < 256
		db $0F, sreg, dreg, dreg2
	else
		err "Invalid opcode argument. Should be 'strr sreg, dreg, dreg2'"
	end if
end macro

; logical or
macro lor? rsrc, rdest, rdest2:$FFFFFFFFF
	if rsrc < 256 & rdest < 256
		if rdest2 >= 256
			db $3E, rdest, rsrc, rdest
		else
			db $3E, rdest, rsrc, rdest2
		end if
	else
		err "Invalid opcode argument. Should be 'land dreg, sreg' or 'land sreg, sreg, dreg'"
	end if
end macro

; logical and
macro land? rsrc, rdest, rdest2:$FFFFFFFFF
	if rsrc < 256 & rdest < 256
		if rdest2 >= 256
			db $3F, rdest, rsrc, rdest
		else
			db $3F, rdest, rsrc, rdest2
		end if
	else
		err "Invalid opcode argument. Should be 'land dreg, sreg' or 'land sreg, sreg, dreg'"
	end if
end macro

macro arithmetic_opcode code, opc
	macro code? rdest, rsrc, rdest2:$FFFFFFFFF
		if rsrc < 256 & rdest < 256
			if rdest2 >= 256
				db opc, rdest, rsrc, rdest
			else
				db opc, rdest, rsrc, rdest2
			end if
		else
			err "Invalid opcode argument. Should be '",`code," dreg, sreg' or '",`code," sreg, sreg, dreg'"
		end if
	end macro
end macro

arithmetic_opcode add, $40
arithmetic_opcode adc, $42
arithmetic_opcode sub, $44
arithmetic_opcode sbc, $46
arithmetic_opcode mul, $48
arithmetic_opcode div, $4A
arithmetic_opcode mod, $4C
arithmetic_opcode cmp, $4E
arithmetic_opcode and, $50
arithmetic_opcode or,  $52
arithmetic_opcode xor, $54
arithmetic_opcode shr, $56
arithmetic_opcode shl, $58
arithmetic_opcode ror, $5A
arithmetic_opcode rol, $5C
arithmetic_opcode ashr,$5E
arithmetic_opcode adds, $60
arithmetic_opcode adcs, $62
arithmetic_opcode subs, $64
arithmetic_opcode sbcs, $66
arithmetic_opcode muls, $68
arithmetic_opcode divs, $6A
arithmetic_opcode mods, $6C
arithmetic_opcode cmps, $6E

purge arithmetic_opcode

macro arithmetic_opcode code, opc
	macro code? rdest, imm
		if rdest < 256
			if rdest >= r0f
				db opc, rdest
				dd imm
			else
				db opc, rdest
				if rdest < r0l
					dd imm
				else if rdest < r0a
					dw imm
				else
					db imm, 0
				end if
			end if
		else
			err "Invalid opcode argument. Should be '",`code," reg, imm'"
		end if
	end macro
end macro

arithmetic_opcode addi, $41
arithmetic_opcode adci, $43
arithmetic_opcode subi, $45
arithmetic_opcode sbci, $47
arithmetic_opcode muli, $49
arithmetic_opcode divi, $4B
arithmetic_opcode modi, $4D
arithmetic_opcode cmpi, $4F
arithmetic_opcode andi, $51
arithmetic_opcode ori,  $53
arithmetic_opcode xori, $55
arithmetic_opcode shri, $57
arithmetic_opcode shli, $59
arithmetic_opcode rori, $5B
arithmetic_opcode roli, $5D
arithmetic_opcode ashri,$5F
arithmetic_opcode addsi, $61
arithmetic_opcode adcsi, $63
arithmetic_opcode subsi, $65
arithmetic_opcode sbcsi, $67
arithmetic_opcode mulsi, $69
arithmetic_opcode divsi, $6B
arithmetic_opcode modsi, $6D
arithmetic_opcode cmpsi, $6F


purge arithmetic_opcode

macro ddb? args&
	iterate arg, args
		db arg, 0
	end iterate
end macro

macro ddw? args&
	iterate arg, args
		dw arg, 0
	end iterate
end macro

macro drb? amount
	rb amount
	rb amount
end macro

macro dbs? data
	local _data, _len, _location
	virtual
		db data, 0
		load _data : $-$$ from $$
		_len = $-$$
	end virtual
	_location = $
	db data, 0
	db data, 0
	repeat _len
		load a : byte from (_location + %% - %)
		store a : word at (_location + %%*2 - %*2)
	end repeat
end macro

macro dbsl? data
	local _data, _len, _location
	virtual
		db data, 0
		load _data : $-$$ from $$
		_len = $-$$
	end virtual
	_location = $
	db data, $A
	db data, $A
	repeat _len
		load a : byte from (_location + %% - %)
		store a : word at (_location + %%*2 - %*2)
	end repeat
end macro

macro dw_color? r, g, b, i:0
	dw (i shl 15) or (r shr 3) shl 10 or (g shr 3) shl 5 or (b shr 3)
end macro
