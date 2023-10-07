call ._init
jp ._main
._exit := 0
label ._init
label ._1257669376928
label ._1257669335168
label ._1257669335088
label ._fib
push r12
ld r12,r2
addi r2,-6
ldi r30,1
str r30,r12,-4
str r30,r12,-2
ld r30,r24a
cmpi r30a,2
jq nc, ._1257669374048
ildr r30,r12,-2
ld r2,r12
pop r12
ret
label ._1257669374048
label ._1257669375648
ld r30,r24a
dec r30a
ld r24,r30a
or r30a,r30a
jq z, ._1257669374208
ildr r30,r12,-2
str r30,r12,-6
ildr r30,r12,-2
push r30
ildr r30,r12,-4
pop r31
add r30,r31
str r30,r12,-2
ildr r30,r12,-6
str r30,r12,-4
jq ._1257669375648
label ._1257669374208
ildr r30,r12,-2
ld r2,r12
pop r12
ret
label ._1257669374608
label ._main
push r12
ld r12,r2
addi r2,-1
ldz r30
str r30a,r12,0
ldi r30,1
str r30a,r12,-1
label ._1257669375728
ldi r30,.s_1257669377248
ld r24,r30
ldi r25,32767
call _print
ildr r30a,r12,-1
ld r24,r30a
call _printuint
ldi r30,.s_1257669377008
ld r24,r30
call _printline
ildr r30a,r12,-1
ld r24,r30a
call ._fib
ld r24,r30
call _printuint
ldi r24,0
ldi r25,0
call _settextxy
call _waitkeycycle
str r30a,r12,0
ildr r30a,r12,0
cmpi r30a,11
jq nz, ._1257669374128
ld r2,r12
pop r12
ret
jq ._1257669375568
label ._1257669374128
ildr r30a,r12,0
cmpi r30a,9
jq nz, ._1257669374288
ld r2,r12
pop r12
ret
jq ._1257669373488
label ._1257669374288
ildr r30a,r12,0
cmpi r30a,4
jq nz, ._1257669375168
ildr r30a,r12,-1
inc r30a
str r30a,r12,-1
jq ._1257669373408
label ._1257669375168
ildr r30a,r12,0
cmpi r30a,1
jq nz, ._1257669377168
ildr r30a,r12,-1
dec r30a
str r30a,r12,-1
jq ._1257669376848
label ._1257669377168
ildr r30a,r12,0
cmpi r30a,3
jq nz, ._1257669374688
ildr r30a,r12,-1
addi r30a,16
str r30a,r12,-1
jq ._1257669376688
label ._1257669374688
ildr r30a,r12,0
cmpi r30a,2
jq nz, ._1257669373328
ildr r30a,r12,-1
subi r30a,16
str r30a,r12,-1
label ._1257669375568
label ._1257669373488
label ._1257669373408
label ._1257669376848
label ._1257669376688
label ._1257669373328
jq ._1257669375728
ld r2,r12
pop r12
ret
label .s_1257669377008
dw $29
dw $3D
dw $0
label .s_1257669377248
dw $66
dw $69
dw $62
dw $28
dw $0
