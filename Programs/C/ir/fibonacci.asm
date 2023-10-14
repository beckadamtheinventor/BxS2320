
DEFINE_FUNCTION "fib", $0, $B56EB010, $1
$3     : ENTER -$C
$5     : IMM_32 $1, $0
$8     : STORE_LOCAL -$8, $4
$B     : STORE_LOCAL -$4, $4
$E     : LEA_LOCAL $2
$10    : LOAD_CHAR
$11    : COMPARE_LT_CONST $2
$13    : BNZ $19, $B56EB290
$15    : LEA_LOCAL -$4
$17    : LOAD_LONG
$18    : LEAVE
$19    : LEA_LOCAL $2
$1B    : LOAD_CHAR
$1C    : DEC
$1D    : STORE_LOCAL $2, $1
$20    : BNZ $3C, $B56EB2E0
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
$3A    : JMP $19, $B56EB6A0
$3C    : LEA_LOCAL -$4
$3E    : LOAD_LONG
$3F    : LEAVE

DEFINE_FUNCTION "main", $40, $B56EB920, $0
$43    : ENTER -$2
$45    : IMM $0
$47    : STORE_LOCAL -$1, $1
$4A    : IMM $1
$4C    : STORE_LOCAL -$2, $1
$4F    : IMM_PROG_OFFSET $DE, $B56EADE0
$51    : PUSH_ARG
$52    : PUSH_ARG_IMM $7FFF
$54    : CALL "_print", $B55B0220
$56    : ADJ $2
$58    : LEA_LOCAL -$2
$5A    : LOAD_CHAR
$5B    : PUSH_ARG_32
$5C    : CALL "_printuint", $B55B0FD0
$5E    : ADJ $2
$60    : IMM_PROG_OFFSET $DB, $B56EB9C0
$62    : PUSH_ARG
$63    : CALL "_printline", $B55B0F70
$65    : ADJ $1
$67    : LEA_LOCAL -$2
$69    : LOAD_CHAR
$6A    : PUSH_ARG
$6B    : CALL "fib", $B56EB010
$6D    : ADJ $1
$6F    : PUSH_ARG_32
$70    : CALL "_printuint", $B55B0FD0
$72    : ADJ $2
$74    : PUSH_ARG_IMM $0
$76    : PUSH_ARG_IMM $0
$78    : CALL "_settextxy", $B55B1030
$7A    : ADJ $2
$7C    : CALL "_waitkeycycle", $B55B1090
$7E    : ADJ $0
$80    : STORE_LOCAL -$1, $1
$83    : LEA_LOCAL -$1
$85    : LOAD_CHAR
$86    : COMPARE_EQ_CONST $B
$88    : BNZ $8D, $B56EBA10
$8A    : LEAVE
$8B    : JMP $D7, $B56EB740
$8D    : LEA_LOCAL -$1
$8F    : LOAD_CHAR
$90    : COMPARE_EQ_CONST $9
$92    : BNZ $97, $B56EAFC0
$94    : LEAVE
$95    : JMP $D7, $B56EB600
$97    : LEA_LOCAL -$1
$99    : LOAD_CHAR
$9A    : COMPARE_EQ_CONST $4
$9C    : BNZ $A7, $B56EB560
$9E    : LEA_LOCAL -$2
$A0    : LOAD_CHAR
$A1    : INC
$A2    : STORE_LOCAL -$2, $1
$A5    : JMP $D7, $B56EAD90
$A7    : LEA_LOCAL -$1
$A9    : LOAD_CHAR
$AA    : COMPARE_EQ_CONST $1
$AC    : BNZ $B7, $B56EBBF0
$AE    : LEA_LOCAL -$2
$B0    : LOAD_CHAR
$B1    : DEC
$B2    : STORE_LOCAL -$2, $1
$B5    : JMP $D7, $B56EB6F0
$B7    : LEA_LOCAL -$1
$B9    : LOAD_CHAR
$BA    : COMPARE_EQ_CONST $3
$BC    : BNZ $C8, $B56EAE30
$BE    : LEA_LOCAL -$2
$C0    : LOAD_CHAR
$C1    : ADD_CONST $10
$C3    : STORE_LOCAL -$2, $1
$C6    : JMP $D7, $B56EAE80
$C8    : LEA_LOCAL -$1
$CA    : LOAD_CHAR
$CB    : COMPARE_EQ_CONST $2
$CD    : BNZ $D7, $B56EAED0
$CF    : LEA_LOCAL -$2
$D1    : LOAD_CHAR
$D2    : SUB_CONST $10
$D4    : STORE_LOCAL -$2, $1
$D7    : JMP $4F, $B56EBBA0
$D9    : LEAVE
$DA    : NOP
db $3D, 0
db $66, $69, $62, $28, 0
db 0
