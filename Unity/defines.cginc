
#define R0_ADDR 0xff00
#define NUM_REGS 32
#define CACHE_SIZE_ADDR 0xff20
#define CACHE_ADDR 0xff21
#define CACHE_SIZE 48
#define F_CARRY 1
#define F_ZERO 2
#define F_SIGN 4
#define F_CARRYSAVE 8
#define F_HALT 32

#define ADDR_ROM_START    0x00000000
#define ADDR_ROM_END      0x0FFFFFFF
#define ADDR_ROM_MASK     0x0FFFFFFF
#define ROM_SIZE          0xF0000000
#define ADDR_RAM_START    0xF0000000
#define ADDR_RAM_END      0xF0FFFFFF
#define ADDR_RAM_MASK     0x0000FFFF
#define RAM_SIZE          0x00010000
#define ADDR_GRAM_START   0xF1000000
#define ADDR_GRAM_END     0xF1FFFFFF
#define ADDR_GRAM_MASK    0x000001FF
#define GRAM_SIZE         0x00000200
#define ADDR_FRAM_START   0xF2000000
#define ADDR_FRAM_END     0xF2FFFFFF
#define ADDR_FRAM_MASK    0x000000FF
#define FRAM_SIZE         0x00000100
#define ADDR_STACK_START  0xFF000000
#define ADDR_STACK_END    0xFFFFFFFF
#define ADDR_STACK_MASK   0x000000FF
#define STACK_SIZE        0x00000100
#define FONT_DATA_RAM_PTR 0x0000E000
#define KEYCODE_RAM_PTR   0x0000FFF0
#define FRAM_MASK ADDR_FRAM_MASK
#define GRAM_MASK ADDR_GRAM_MASK
#define STACK_MASK ADDR_STACK_MASK

#define SELECT(a,b,v) uint(lerp((a),(b),(v)))
#define ONE_IF_LT(v,a) ((v)<(a))
#define SELECT_IF_LT(v,a,c,d) SELECT(c,d,ONE_IF_LT(v,a))
#define ONE_IF_GT(v,a) ((v)>(a))
#define SELECT_IF_GT(v,a,c,d) SELECT(c,d,ONE_IF_GT(v,a))
#define ONE_IF_LTEQ(v,a) ((v)<=(a))
#define SELECT_IF_LTEQ(v,a,c,d) SELECT(c,d,ONE_IF_LTEQ(v,a))
#define ONE_IF_GTEQ(v,a) ((v)>=(a))
#define SELECT_IF_GTEQ(v,a,c,d) SELECT(c,d,ONE_IF_GTEQ(v,a))
#define ONE_IF_IN_RANGE(v,a,b) (ONE_IF_GTEQ(v,a)&&ONE_IF_LT(v,b))
#define SELECT_IF_IN_RANGE(v,a,b,c,d) SELECT(c,d,ONE_IF_IN_RANGE(v,a,b))
#define ONE_IF_EQUAL(v,a) ((v)==(a))
#define SELECT_IF_EQUAL(v,a,c,d) SELECT(c,d,ONE_IF_EQUAL(v,a))

#define read_emulator_word(addr, component) (_SelfTexture2D[uint2((addr) & 0xFF, (addr) >> 8)].component)
#define emu_read(addr, res) {res = (\
	((addr)>=ADDR_FRAM_START&&(addr)<=ADDR_FRAM_END)?((regs[0x100+NUM_REGS+((addr)&0xFF)]>>16)):\
	(((addr)>=ADDR_STACK_START&&(addr)<=ADDR_STACK_END)?((regs[0x100+NUM_REGS+((addr)&0xFF)])):\
	(((addr)>=ADDR_GRAM_START&&(addr)<=ADDR_GRAM_END)?((regs[NUM_REGS+((addr)&0xFF)]>>SELECT_IF_GTEQ((addr)&GRAM_MASK,0x100,16,0))):\
	(((addr)>=ADDR_ROM_START&&(addr)<=ADDR_ROM_END)?\
		uint(tex2Dlod(_RomTex, float4(((addr)&0xfff)/4096.0f, ((addr)>>12)/4096.0f,0,0.0)).r*65535.0f):\
	0))))&0xffff;\
	notfound = 1;\
	[unroll] for (ci=0; ci<CACHE_SIZE; ci++) {\
	found = ((regs[0x201+NUM_REGS+ci]&0xffff) == ((addr)&0xffff) && (regs[0x201+NUM_REGS+ci]&0xffff)>0)?1:0;\
	tmp = found?(regs[0x201+NUM_REGS+ci]>>16):tmp;\
	notfound = found?0:notfound;}\
	tmp = notfound?_SelfTexture2D[uint2((addr)&0xff, ((addr)>>8)&0xff)].r:tmp;\
	res = ((addr)>=ADDR_RAM_START&&(addr)<=ADDR_RAM_END)?tmp:res;}

#define overflowAdd(a, b) (((a)&0x80000000)&&((b)&0x80000000))
#define overflowAdds(a, b) ((((a)&0x80000000)^((b)&0x80000000))?0:((((a)&0x40000000)&&((b)&0x40000000))^((a+b)&0x80000000)))
#define overflowSub(a, b) ((a)<(b))
#define overflowSubs(a, b) ((int)(a)<(int)(b))
#define ddoffset(v) ((((v)&0x80)?((v)-0x100):(v)))
#define ddoffset16(v) (((v)&0x8000)?((v)-0x10000):(v))

#define TRUE 1
#define FALSE 0
#define intasfloat(value) asfloat(value);
#define floatasint(value) asint(value);


// the order here matters to the selection routines
#define T_WORD 1
#define T_LONG 3
#define T_BYTE 4

// return a with 32, 16, or 8 bits updated with b, determined by load type s
#define UPDATE_NUMBER_SECTION(s,a,b) (((s)>=T_BYTE)?(((a) & ~(0xff << (8*((s)-T_BYTE)))) | (((b)&0xff) << (8*((s)-T_BYTE)))):\
									  (((s)<=T_WORD+1)?(((a) & ~(0xffff << (16*((s)-T_WORD)))) | (((b)&0xffff) << (16*((s)-T_WORD)))):(b)))

#define SELECT_STNO(s) (((s)<32||(s)>=224)?T_LONG:((s)<96?(T_WORD+((s)/32)-1):(T_BYTE+((s)/32)-3)))
#define SELECT_SVAL(s,a) ((s)>=T_BYTE?(((a) >> (8*((s)-T_BYTE)))&0xff):((s)==T_LONG?(a):(((a) >> (16*((s)-T_WORD)))&0xffff)))
#define GET_WADDR(a) (((a)<=ADDR_ROM_END)?(0x202+NUM_REGS+CACHE_SIZE):((a)<=ADDR_RAM_END?(0x201+NUM_REGS+regs[0x200+NUM_REGS]):\
					 ((a)<=ADDR_GRAM_END?(NUM_REGS+((a)&0xFF)+((a)&0x100?0x10000:0)):((a)<=ADDR_FRAM_END?(0x10100+NUM_REGS+((a)&0xFF)):\
					 ((NUM_REGS+0x100+((a)&0xFF)))))))
