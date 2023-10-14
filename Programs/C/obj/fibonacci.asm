call ._init
jp ._main
._exit := 0
label ._init
label ._2682828271072
label ._2682828232832
label ._2682828232752
label ._fib
push r12
ld r12,r2
addi r2,-6
ldi r30,1
str r30,r12,-4
str r30,r12,-2
ld r30,r24a
cmpi r30a,2
jq nc, ._2682828270992
ildr r30,r12,-2
ld r2,r12
pop r12
ret
label ._2682828270992
label ._2682828272832
ld r30,r24a
dec r30a
ld r24,r30a
or r30a,r30a
jq z, ._2682828273392
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
jq ._2682828272832
label ._2682828273392
ildr r30,r12,-2
ld r2,r12
pop r12
ret
label ._2682828272112
label ._main
push r12
ld r12,r2
addi r2,-1
ldz r30
str r30a,r12,0
ldi r30,1
str r30a,r12,-1
label ._2682828274912
ldi r30,.s_2682828273152
ld r24,r30
ldi r25,32767
call _print
ildr r30a,r12,-1
ld r24,r30a
call _printuint
ldi r30,.s_2682828271152
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
jq nz, ._2682828274032
ld r2,r12
pop r12
ret
jq ._2682828274832
label ._2682828274032
ildr r30a,r12,0
cmpi r30a,9
jq nz, ._2682828274512
ld r2,r12
pop r12
ret
jq ._2682828274752
label ._2682828274512
ildr r30a,r12,0
cmpi r30a,4
jq nz, ._2682828274592
ildr r30a,r12,-1
inc r30a
str r30a,r12,-1
jq ._2682828271792
label ._2682828274592
ildr r30a,r12,0
cmpi r30a,1
jq nz, ._2682828271872
ildr r30a,r12,-1
dec r30a
str r30a,r12,-1
jq ._2682828272032
label ._2682828271872
ildr r30a,r12,0
cmpi r30a,3
jq nz, ._2682828273072
ildr r30a,r12,-1
addi r30a,16
str r30a,r12,-1
jq ._2682828273792
label ._2682828273072
ildr r30a,r12,0
cmpi r30a,2
jq nz, ._2682828272272
ildr r30a,r12,-1
subi r30a,16
str r30a,r12,-1
label ._2682828274832
label ._2682828274752
label ._2682828271792
label ._2682828272032
label ._2682828273792
label ._2682828272272
jq ._2682828274912
ld r2,r12
pop r12
ret
label .s_2682828271152
dw $29
dw $3D
dw $0
label .s_2682828273152
dw $66
dw $69
dw $62
dw $28
dw $0
