call ._init
jp ._main
._exit := 0
label ._init
label ._2468810200800
label ._2468811162048
label ._2468811120112
label ._2468811117968
label ._LoadLevel
push r12
ld r12,r2
ld r30,r24l
cmpi r30l,0
jq nz, ._2468811161888
ldi r30,$F0000004
ildr r30,r30
ld r24,r30
ldi r30,.s_2468811160768
ld r25,r30
call _strcpy
jq ._2468811158768
label ._2468811161888
ld r30,r24l
cmpi r30l,1
jq nz, ._2468811161728
ldi r30,$F0000004
ildr r30,r30
ld r24,r30
ldi r30,.s_2468811159168
ld r25,r30
call _strcpy
label ._2468811161728
label ._2468811158768
ld r2,r12
pop r12
ret
label ._2468810201024
label ._BoxManDrawC
push r12
ld r12,r2
ld r30,r24a
cmpi r30a,65
jq nz, ._2468811161808
ldi r24,35
ldi r25,31744
call _printchar
jq ._2468811161008
label ._2468811161808
ld r30,r24a
cmpi r30a,66
jq nz, ._2468811162608
ldi r24,35
ldi r25,992
call _printchar
jq ._2468811160608
label ._2468811162608
ld r30,r24a
cmpi r30a,67
jq nz, ._2468811159408
ldi r24,35
ldi r25,31
call _printchar
jq ._2468811160528
label ._2468811159408
ld r30,r24a
cmpi r30a,68
jq nz, ._2468811162288
ldi r24,35
ldi r25,32736
call _printchar
jq ._2468811160288
label ._2468811162288
ld r30,r24a
cmpi r30a,69
jq nz, ._2468811162368
ldi r24,35
ldi r25,1023
call _printchar
jq ._2468811161328
label ._2468811162368
ld r30,r24a
cmpi r30a,97
jq nz, ._2468811159888
ldi r24,79
ldi r25,31744
call _printchar
jq ._2468811161648
label ._2468811159888
ld r30,r24a
cmpi r30a,98
jq nz, ._2468811159808
ldi r24,79
ldi r25,992
call _printchar
jq ._2468811162448
label ._2468811159808
ld r30,r24a
cmpi r30a,99
jq nz, ._2468811159648
ldi r24,79
ldi r25,31
call _printchar
jq ._2468811161248
label ._2468811159648
ld r30,r24a
cmpi r30a,100
jq nz, ._2468811161088
ldi r24,79
ldi r25,32736
call _printchar
jq ._2468811160688
label ._2468811161088
ld r30,r24a
cmpi r30a,101
jq nz, ._2468811159328
ldi r24,79
ldi r25,1023
call _printchar
jq ._2468811161168
label ._2468811159328
ld r30,r24a
ld r24,r30a
ldi r25,32767
call _printchar
label ._2468811161168
label ._2468811160688
label ._2468811161248
label ._2468811162448
label ._2468811161648
label ._2468811161328
label ._2468811160288
label ._2468811160528
label ._2468811160608
label ._2468811161008
ld r2,r12
pop r12
ret
label ._2468810201152
label ._BoxManDrawScreen
push r12
ld r12,r2
addi r2,-2
call _cleartty
ldi r30,$F0000004
ildr r30,r30
ildr r30a,r30
sto r30a,$F0000001
ldi r30,$F0000004
ildr r30,r30
addi r30,1
str r30,r12,-1
ldi r30,$F0000001
ildr r30a,r30
andi r30a,15
sto r30a,$F0000000
ldi r30,$F0000001
ildr r30a,r30
shri r30a,4
sto r30a,$F0000001
ldi r30,$F0000000
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
subi r30,1
ld r24,r30
ldi r30,$F0000001
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
subi r30,1
ld r25,r30
call _settextxy
ldz r30
str r30a,r12,-1
label ._2468811162528
ildr r30a,r12,-1
push r30
ldi r30,$F0000000
ildr r30a,r30
addi r30a,2
pop r31
cmp r30a,r31a
jq nc, ._2468811162128
ldi r24,35
ldi r25,32767
call _printchar
ildr r30a,r12,-1
inc r30a
str r30a,r12,-1
jq ._2468811162528
label ._2468811162128
ldi r30,$F0000000
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
subi r30,1
ld r24,r30
ldi r30,$F0000001
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
push r30
ldi r30,$F0000001
ildr r30a,r30
pop r31
add r30a,r31a
ld r25,r30a
call _settextxy
ldz r30
str r30a,r12,-1
label ._2468811161968
ildr r30a,r12,-1
push r30
ldi r30,$F0000000
ildr r30a,r30
addi r30a,2
pop r31
cmp r30a,r31a
jq nc, ._2468811161568
ldi r24,35
ldi r25,32767
call _printchar
ildr r30a,r12,-1
inc r30a
str r30a,r12,-1
jq ._2468811161968
label ._2468811161568
ldz r30
str r30a,r12,-2
label ._2468811159568
ildr r30a,r12,-2
push r30
ldi r30,$F0000001
ildr r30a,r30
pop r31
cmp r30a,r31a
jq nc, ._2468811162208
ldi r30,$F0000000
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
subi r30,1
ld r24,r30
ldi r30,$F0000001
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
push r30
ildr r30a,r12,-2
pop r31
add r30a,r31a
ld r25,r30a
call _settextxy
ldi r24,35
ldi r25,32767
call _printchar
ldz r30
str r30a,r12,-1
label ._2468811160048
ildr r30a,r12,-1
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
cmp r30a,r31a
jq nc, ._2468811162688
ildr r30,r12,-1
ildr r30a,r30
ld r24,r30a
call ._BoxManDrawC
ildr r30,r12,-1
inc r30
str r30a,r12,-1
ildr r30a,r12,-1
inc r30a
str r30a,r12,-1
jq ._2468811160048
label ._2468811162688
ldi r24,35
ldi r25,32767
call _printchar
ildr r30a,r12,-2
inc r30a
str r30a,r12,-2
jq ._2468811159568
label ._2468811162208
ld r2,r12
pop r12
ret
label ._2468810201280
label ._BoxmanMain
push r12
ld r12,r2
addi r2,-9
ldz r30
str r30l,r12,-8
ldi r30,2
str r30a,r12,-9
label ._2468811163040
ildr r30a,r12,-9
cmpi r30a,2
jq c, ._2468811164880
ildr r30l,r12,-8
push r30
ldi r30,$F0000006
ildr r30l,r30
pop r31
inc r31l
cmp r30l,r31l
jq nc, ._2468811164720
ldi r30,.s_2468811166320
ld r24,r30
ldi r25,32767
call _print
call _waitkeycycle
str r30a,r12,-9
ildr r30a,r12,-9
cmpi r30a,11
jq nz, ._2468811166000
ldi r30,1
ld r2,r12
pop r12
ret
label ._2468811166000
label ._2468811164720
ildr r30l,r12,-8
ld r24,r30l
call ._LoadLevel
ldz r30
str r30l,r12,-4
str r30l,r12,-3
ldz r30
sto r30l,$F0000002
ldz r30
str r30l,r12,-7
label ._2468811166720
ldi r30,$F0000004
ildr r30,r30
push r30
ildr r30l,r12,-7
pop r31
add r30l,r31l
ildr r30a,r30
str r30a,r12,-2
or r30a,r30a
jq z, ._2468811166400
ildr r30a,r12,-2
cmpi r30a,65
flagxor 1
flagand 1
ld r30,r1a
push r30
ildr r30a,r12,-2
cmpi r30a,70
pop r31
flagand 1
ld r30,r1a
land r30a,r31a
or r30a,r30a
jq z, ._2468811165200
ldi r30,$F0000002
ildr r30l,r30
inc r30l
sto r30l,$F0000002
label ._2468811165200
ildr r30l,r12,-7
inc r30l
str r30l,r12,-7
jq ._2468811166720
label ._2468811166400
label ._2468811164880
ildr r30a,r12,-9
cmpi r30a,1
jq c, ._2468811165280
call ._BoxManDrawScreen
ldi r30,$F0000000
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
str r30a,r12,0
ldi r30,$F0000001
ildr r30a,r30
ex r30,r31
ldi r30,16
sub r30,r31
shri r30,1
str r30a,r12,-1
label ._2468811165280
ldi r30,$F0000002
ildr r30l,r30
cmpi r30l,0
jq nz, ._2468811166560
ldi r24,0
ldi r25,0
call _settextxy
ldi r30,.s_2468811164960
ld r24,r30
ldi r25,32767
call _print
call _waitkeycycle
call _cleartty
ildr r30l,r12,-8
inc r30l
str r30l,r12,-8
ldi r30,2
str r30a,r12,-9
jq ._2468811163840
label ._2468811166560
ldi r30,$F0000004
ildr r30,r30
push r30
ildr r30l,r12,-3
push r30
ildr r30l,r12,-4
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
mul r30a,r31a
pop r31
add r30a,r31a
addi r30a,1
pop r31
add r30a,r31a
ildr r30a,r30
str r30a,r12,-1
ldi r24,79
ildr r30a,r12,0
push r30
ildr r30l,r12,-3
pop r31
add r30l,r31l
ld r25,r30l
ildr r30a,r12,-1
push r30
ildr r30l,r12,-4
pop r31
add r30l,r31l
ld r26,r30l
call _printcharat
call _waitkeycycle
str r30a,r12,-9
ldz r30
str r30l,r12,-6
str r30l,r12,-5
ildr r30a,r12,-9
cmpi r30a,3
jq nz, ._2468811166480
ldi r30,1
str r30l,r12,-5
jq ._2468811165440
label ._2468811166480
ildr r30a,r12,-9
cmpi r30a,2
jq nz, ._2468811165520
ldi r30,4294967295
str r30l,r12,-5
jq ._2468811166800
label ._2468811165520
ildr r30a,r12,-9
cmpi r30a,1
jq nz, ._2468811166640
ldi r30,1
str r30l,r12,-6
jq ._2468811165120
label ._2468811166640
ildr r30a,r12,-9
cmpi r30a,4
jq nz, ._2468811163120
ldi r30,4294967295
str r30l,r12,-6
jq ._2468811162880
label ._2468811163120
ildr r30a,r12,-9
cmpi r30a,10
jq nz, ._2468811165680
ldz r30
ld r2,r12
pop r12
ret
jq ._2468811164240
label ._2468811165680
ildr r30a,r12,-9
cmpi r30a,11
jq nz, ._2468811165840
ldi r30,1
ld r2,r12
pop r12
ret
jq ._2468811165360
label ._2468811165840
ldi r30,2
ld r2,r12
pop r12
ret
label ._2468811165360
label ._2468811164240
label ._2468811162880
label ._2468811165120
label ._2468811166800
label ._2468811165440
ildr r30l,r12,-3
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
cmp r30a,r31a
flagand 1
ld r30,r1a
push r30
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ldi r30,$F0000001
ildr r30a,r30
pop r31
cmp r30a,r31a
pop r31
flagand 1
ld r30,r1a
land r30a,r31a
or r30a,r30a
jq z, ._2468811165760
ldi r30,$F0000004
ildr r30,r30
push r30
ildr r30l,r12,-3
push r30
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
mul r30a,r31a
pop r31
add r30a,r31a
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
addi r30l,1
pop r31
add r30l,r31l
ildr r30a,r30
str r30a,r12,-2
cmpi r30a,32
jq nz, ._2468811163360
ildr r30l,r12,-3
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
str r30l,r12,-3
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
str r30l,r12,-4
ldi r30,1
str r30a,r12,-9
jq ._2468811165920
label ._2468811163360
ildr r30a,r12,-2
cmpi r30a,97
flagxor 1
flagand 1
ld r30,r1a
push r30
ildr r30a,r12,-2
cmpi r30a,102
pop r31
flagand 1
ld r30,r1a
land r30a,r31a
or r30a,r30a
jq z, ._2468811162960
ildr r30l,r12,-3
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
cmp r30a,r31a
flagand 1
ld r30,r1a
push r30
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ldi r30,$F0000001
ildr r30a,r30
pop r31
cmp r30a,r31a
pop r31
flagand 1
ld r30,r1a
land r30a,r31a
or r30a,r30a
jq z, ._2468811165600
ldi r30,$F0000004
ildr r30,r30
push r30
ildr r30l,r12,-3
push r30
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
mul r30a,r31a
pop r31
add r30a,r31a
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
addi r30l,1
pop r31
add r30l,r31l
ildr r30a,r30
str r30a,r12,-2
cmpi r30a,32
flagand 2
ld r30,r1a
shri r30a,1
push r30
ildr r30a,r12,-2
push r30
ildr r30a,r12,-2
pop r31
sub r30a,r31a
cmpi r30a,32
pop r31
flagand 2
ld r30,r1a
shri r30a,1
lor r30a,r31a
or r30a,r30a
jq z, ._2468811163440
ldi r30,$F0000004
ildr r30,r30
push r30
ildr r30l,r12,-3
push r30
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
mul r30a,r31a
pop r31
add r30a,r31a
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
addi r30l,1
pop r31
add r30l,r31l
push r30
ildr r30a,r12,-2
cmpi r30a,32
ildr r30a,r12,-2
ildr r30a,r12,-2
pop r31
str r30,r31
ldi r30,$F0000004
ildr r30,r30
push r30
ildr r30l,r12,-3
push r30
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
push r30
ldi r30,$F0000000
ildr r30a,r30
pop r31
mul r30a,r31a
pop r31
add r30a,r31a
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
addi r30l,1
pop r31
add r30l,r31l
ex r30,r31
ldi r30,32
str r30,r31
ildr r30a,r12,-2
cmpi r30a,32
jq z, ._2468811165040
ldi r30,$F0000002
ildr r30l,r30
dec r30l
sto r30l,$F0000002
label ._2468811165040
ildr r30l,r12,-3
push r30
ildr r30l,r12,-5
pop r31
add r30l,r31l
str r30l,r12,-3
ildr r30l,r12,-4
push r30
ildr r30l,r12,-6
pop r31
add r30l,r31l
str r30l,r12,-4
ldi r30,1
str r30a,r12,-9
label ._2468811163840
label ._2468811165920
label ._2468811162960
label ._2468811165600
label ._2468811163440
label ._2468811165760
jq ._2468811163040
ld r2,r12
pop r12
ret
label ._2468811163200
label ._main
push r12
ld r12,r2
ldi r30,4060086273
sto r30,$F0000004
ldi r30,2
sto r30l,$F0000006
call _waitkeycycle
label ._2468811163280
call ._BoxmanMain
cmpi r30a,1
jq z, ._2468811166080
jq ._2468811163280
label ._2468811166080
ld r2,r12
pop r12
ret
label .s_2468811164960
dw $59
dw $6F
dw $75
dw $20
dw $77
dw $69
dw $6E
dw $21
dw $0
label .s_2468811166320
dw $59
dw $6F
dw $75
dw $20
dw $57
dw $69
dw $6E
dw $21
dw $0
label .s_2468811159168
dw $55
dw $20
dw $20
dw $23
dw $41
dw $42
dw $20
dw $62
dw $23
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $61
dw $20
dw $20
dw $20
dw $20
dw $20
dw $23
dw $23
dw $20
dw $0
dw $0
dw $0
dw $0
label .s_2468811160768
dw $55
dw $20
dw $23
dw $23
dw $41
dw $23
dw $62
dw $20
dw $61
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $20
dw $42
dw $23
dw $20
dw $20
dw $20
dw $0
dw $0
dw $0
dw $0