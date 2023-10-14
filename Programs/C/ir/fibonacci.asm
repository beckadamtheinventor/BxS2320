
DEFINE_FUNCTION "fib", $0, $A506ADE0, $1
$3     : ENTER -$C
$5     : IMM_32 $1, $0
$8     : STORE_LOCAL -$8, $4
$B     : STORE_LOCAL -$4, $4
$E     : LEA_LOCAL $2
$10    : LOAD_CHAR
$11    : COMPARE_LT_CONST $2
$13    : BNZ $19, $A506AD90
$15    : LEA_LOCAL -$4
$17    : LOAD_LONG
$18    : LEAVE
$19    : LEA_LOCAL $2
$1B    : LOAD_CHAR
$1C    : DEC
$1D    : STORE_LOCAL $2, $1
$20    : BNZ $3C, $A506B6F0
$22    : LEA_LOCAL -$4
$24    : LOAD_LONG
$25    : STORE_LOCAL -$C, $4
$28    : LEA_LOCAL -$4
$2A    : LOAD_LONG
$2B    : PUSH_32
$2C    : LEA_LOCAL -$8
$2E    : LOAD_LONG
$2F    : POP_32
$30    : ADD
$31    : STORE_LOCAL -$4, $4
$34    : LEA_LOCAL -$C
$36    : LOAD_LONG
$37    : STORE_LOCAL -$8, $4
$3A    : JMP $19, $A506B4C0
$3C    : LEA_LOCAL -$4
$3E    : LOAD_LONG
$3F    : LEAVE

DEFINE_FUNCTION "main", $40, $A506B1F0, $0
$43    : ENTER -$2
$45    : IMM $0
$47    : STORE_LOCAL -$1, $1
$4A    : IMM $1
$4C    : STORE_LOCAL -$2, $1
$4F    : IMM_PROG_OFFSET $DE, $A506B600
$51    : PUSH_ARG
$52    : PUSH_ARG_IMM $7FFF
$54    : CALL "_print", $A58D04A0
$56    : ADJ $2
$58    : LEA_LOCAL -$2
$5A    : LOAD_CHAR
$5B    : PUSH_ARG_32
$5C    : CALL "_printuint", $A58D0FD0
$5E    : ADJ $2
$60    : IMM_PROG_OFFSET $DB, $A506AE30
$62    : PUSH_ARG
$63    : CALL "_printline", $A58D0F70
$65    : ADJ $1
$67    : LEA_LOCAL -$2
$69    : LOAD_CHAR
$6A    : PUSH_ARG
$6B    : CALL "fib", $A506ADE0
$6D    : ADJ $1
$6F    : PUSH_ARG_32
$70    : CALL "_printuint", $A58D0FD0
$72    : ADJ $2
$74    : PUSH_ARG_IMM $0
$76    : PUSH_ARG_IMM $0
$78    : CALL "_settextxy", $A58D1030
$7A    : ADJ $2
$7C    : CALL "_waitkeycycle", $A58D1090
$7E    : ADJ $0
$80    : STORE_LOCAL -$1, $1
$83    : LEA_LOCAL -$1
$85    : LOAD_CHAR
$86    : COMPARE_EQ_CONST $B
$88    : BNZ $8D, $A506B970
$8A    : LEAVE
$8B    : JMP $D7, $A506BC90
$8D    : LEA_LOCAL -$1
$8F    : LOAD_CHAR
$90    : COMPARE_EQ_CONST $9
$92    : BNZ $97, $A506BB50
$94    : LEAVE
$95    : JMP $D7, $A506BC40
$97    : LEA_LOCAL -$1
$99    : LOAD_CHAR
$9A    : COMPARE_EQ_CONST $4
$9C    : BNZ $A7, $A506BBA0
$9E    : LEA_LOCAL -$2
$A0    : LOAD_CHAR
$A1    : INC
$A2    : STORE_LOCAL -$2, $1
$A5    : JMP $D7, $A506B0B0
$A7    : LEA_LOCAL -$1
$A9    : LOAD_CHAR
$AA    : COMPARE_EQ_CONST $1
$AC    : BNZ $B7, $A506B100
$AE    : LEA_LOCAL -$2
$B0    : LOAD_CHAR
$B1    : DEC
$B2    : STORE_LOCAL -$2, $1
$B5    : JMP $D7, $A506B1A0
$B7    : LEA_LOCAL -$1
$B9    : LOAD_CHAR
$BA    : COMPARE_EQ_CONST $3
$BC    : BNZ $C8, $A506B5B0
$BE    : LEA_LOCAL -$2
$C0    : LOAD_CHAR
$C1    : ADD_CONST $10
$C3    : STORE_LOCAL -$2, $1
$C6    : JMP $D7, $A506B880
$C8    : LEA_LOCAL -$1
$CA    : LOAD_CHAR
$CB    : COMPARE_EQ_CONST $2
$CD    : BNZ $D7, $A506B290
$CF    : LEA_LOCAL -$2
$D1    : LOAD_CHAR
$D2    : SUB_CONST $10
$D4    : STORE_LOCAL -$2, $1
$D7    : JMP $4F, $A506BCE0
$D9    : LEAVE
$DA    : NOP
db $3D, 0
db $66, $69, $62, $28, 0
db 0
