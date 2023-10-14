call ._init
jp ._main
._exit := 0
label ._init
label ._2270786662416
label ._2270786623616
label ._2270786623536
label ._fib
push r12
ld r12,r2
addi r2,-6
ldi r30,1
str r30,r12,-4
str r30,r12,-2
ld r30,r24a
cmpi r30a,2
jq nc, ._2270786663056
ildr r30,r12,-2
ld r2,r12
pop r12
ret
label ._2270786663056
label ._2270786664096
ld r30,r24a
dec r30a
ld r24,r30a
or r30a,r30a
jq z, ._2270786663136
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
jq ._2270786664096
label ._2270786663136
ildr r30,r12,-2
ld r2,r12
pop r12
ret
label ._2270786664736
label ._main
push r12
ld r12,r2
addi r2,-1
ldz r30
str r30a,r12,0
ldi r30,1
str r30a,r12,-1
label ._2270786665376
ldi r30,.s_2270786661856
ld r24,r30
ldi r25,32767
call _print
ildr r30a,r12,-1
ld r24,r30a
call _printuint
ldi r30,.s_2270786664896
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
jq nz, ._2270786664976
ld r2,r12
pop r12
ret
jq ._2270786664256
label ._2270786664976
ildr r30a,r12,0
cmpi r30a,9
jq nz, ._2270786662336
ld r2,r12
pop r12
ret
jq ._2270786663936
label ._2270786662336
ildr r30a,r12,0
cmpi r30a,4
jq nz, ._2270786663776
ildr r30a,r12,-1
inc r30a
str r30a,r12,-1
jq ._2270786661776
label ._2270786663776
ildr r30a,r12,0
cmpi r30a,1
jq nz, ._2270786665456
ildr r30a,r12,-1
dec r30a
str r30a,r12,-1
jq ._2270786664176
label ._2270786665456
ildr r30a,r12,0
cmpi r30a,3
jq nz, ._2270786661936
ildr r30a,r12,-1
addi r30a,16
str r30a,r12,-1
jq ._2270786662016
label ._2270786661936
ildr r30a,r12,0
cmpi r30a,2
jq nz, ._2270786662096
ildr r30a,r12,-1
subi r30a,16
str r30a,r12,-1
label ._2270786664256
label ._2270786663936
label ._2270786661776
label ._2270786664176
label ._2270786662016
label ._2270786662096
jq ._2270786665376
ld r2,r12
pop r12
ret
label .s_2270786664896
dw $29
dw $3D
dw $0
label .s_2270786661856
dw $66
dw $69
dw $62
dw $28
dw $0
