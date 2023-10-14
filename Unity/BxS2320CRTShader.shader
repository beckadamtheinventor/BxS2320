Shader "BeckATI/BxS2320/CRTShader"
{
    Properties
    {
        _RomTex ("ROM Texture (R16)", 2D) = "black" {}
		_FontTex ("Font Texture", 2D) = "black" {}
		_InputCharTex ("Input Char", 2D) = "black" {}
		_IPF("Target Instructions per second", Int) = 65536
		_IPF_MAX("Maximum Instructions per frame", Int) = 4096
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #include "rvc-crt.cginc"
			
            sampler2D _RomTex;
            sampler2D _FontTex;
			sampler2D _InputCharTex;
			float _IPF;
			float _IPF_MAX;

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

// Registers are stored in row 255 column 0-31 channel B
// Cache size is stored in row 255 column 32 channel B
// Cache is stored in row 255 columns 33-255 channel B
// GRAM is stored in row 255 columns 0-255 channel G
// Stack RAM is stored in row 255 columns 0-127 channel A
// FRAM is stored in row 255 columns 128-255 channel A
// RAM is stored in channel R


#define SELECT(a,b,v) ((v)?(a):(b))
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
#define emu_read(addr, res) {res = uint(\
	((addr)>=ADDR_FRAM_START&&(addr)<=ADDR_FRAM_END)?((regs[0x180+NUM_REGS+((addr)&0x7F)]>>SELECT_IF_GTEQ((addr)&FRAM_MASK,0x80,16,0))):\
	(((addr)>=ADDR_STACK_START&&(addr)<=ADDR_STACK_END)?((regs[0x100+NUM_REGS+((addr)&0x7F)]>>SELECT_IF_GTEQ((addr)&STACK_MASK,0x80,16,0))):\
	(((addr)>=ADDR_GRAM_START&&(addr)<=ADDR_GRAM_END)?((regs[NUM_REGS+((addr)&0xFF)]>>SELECT_IF_GTEQ((addr)&GRAM_MASK,0x100,16,0))):\
	(((addr)>=ADDR_ROM_START&&(addr)<=ADDR_ROM_END)?\
	(tex2Dlod(_RomTex, float4(((addr)&0xfff)/4096.0f, ((addr)>>12)/4096.0f,0,0.0)).r*65535.0f):0))))&0xffff;\
	if ((addr)>=ADDR_RAM_START&&(addr)<=ADDR_RAM_END) {notfound = 1;\
	for (ci=regs[0x200+NUM_REGS]-1; ci>=0&&notfound>0; ci--) {\
	res = ((regs[0x201+NUM_REGS+ci]&0xffff) == ((addr)&0xffff))?(regs[0x201+NUM_REGS+ci]>>16):res;\
	notfound = ((regs[0x201+NUM_REGS+ci]&0xffff) == ((addr)&0xffff))?1:notfound;\
	} res = notfound?_SelfTexture2D[uint2((addr)&0xff, ((addr)>>8)&0xff)].r:res;}}

#define overflowAdd(a, b) (((a)&0x80000000)&&((b)&0x80000000))
#define overflowAdds(a, b) ((((a)&0x80000000)^((b)&0x80000000))?0:((((a)&0x40000000)&&((b)&0x40000000))^((a+b)&0x80000000)))
#define overflowSub(a, b) ((a)<(b))
#define overflowSubs(a, b) ((int)(a)<(int)(b))
#define ddoffset(v) ((((v)&0x80)?((v)-0x100):(v)))
#define ddoffset16(v) (((v)&0x8000)?((v)-0x10000):(v))
#define emu_write(addr, value) {j = (((addr)>=ADDR_FRAM_START&&(addr)<=ADDR_FRAM_END)?(0x180+((addr)&0x7F)):\
	(((addr)>=ADDR_STACK_START&&(addr)<=ADDR_STACK_END)?(0x100+((addr)&0x7F)):\
	(((addr)>=ADDR_GRAM_START&&(addr)<=ADDR_GRAM_END)?((addr)&0xFF):(0x201+regs[0x200+NUM_REGS]))))+NUM_REGS;\
	regs[j] = (j<0x200+NUM_REGS)?((regs[j] & (0xffff<<SELECT_IF_GTEQ((addr)&((j<0x100+NUM_REGS)?GRAM_MASK:FRAM_MASK),\
	(j<0x100+NUM_REGS)?0x100:0x80,0,16)))|\
	(((value)&0xffff) << ((j<0x100+NUM_REGS)?(((addr)&0x100)?16:0):(((addr)&0x80)?16:0)))):\
	(((addr)&0xffff) | ((value) << 16));\
	regs[0x200+NUM_REGS] += ((addr)>=ADDR_RAM_START&&(addr)<=ADDR_RAM_END)?1:0;}

#define emu_write_long(addr, value) { emu_write(addr, value); emu_write((addr)+1, (value)>>16); }
#define TRUE 1
#define FALSE 0
#define intasfloat(value) asfloat(value);
#define floatasint(value) asint(value);


// the order here matters to the selection routines
#define T_WORD 1
#define T_LONG 3
#define T_BYTE 4

// return a with 32, 16, or 8 bits updated with b, determined by load type s
#define UPDATE_NUMBER_SECTION(s,a,b) (((s)>=T_BYTE)?((a) & ~(0xff << (8*((s)-T_BYTE))) | (((b)&0xff) << (8*((s)-T_BYTE)))):\
									  (((s)<=T_WORD+1)?(((a) & ~(0xffff << (16*((s)-T_WORD)))) | (((b)&0xffff) << (16*((s)-T_WORD)))):(b)))

#define SELECT_STNO(s) (((s)<32||(s)>=224)?T_LONG:((s)<96?(T_WORD+((s)/32)-1):(T_BYTE+((s)/32)-3)))
#define SELECT_SVAL(s,a) ((s)>=T_BYTE?(((a) >> (8*((s)-T_BYTE)))&0xff):((s)==T_LONG?(a):(((a) >> (16*((s)-T_WORD)))&0xffff)))


            uint4 frag (v2f_customrendertexture i) : SV_Target
            {
				uint idxx = i.globalTexcoord.x * 256.0f;
				uint idxy = i.globalTexcoord.y * 256.0f;
				uint idx = idxy * 256 + idxx;
				uint j;
				int ci;
				uint4 col, col2;
				uint _InputChar = tex2D(_InputCharTex, float2(0.5f, 0.5f)).g*255.0f;
				[branch]
				if (read_emulator_word(0, g) != 0xAA55AA55 || _InputChar >= 0xFF) {
					uint v = 0;
					[unroll]
					for (j=0; j<8; j++) {
						col = tex2D(_FontTex, float2(((idx>>3)&15)/16.0f + j/128.0f, (16 - ((idx>>7)&15))/16.0f - ((idx&7)+1)/128.0f));
						v |= uint((1 << (7-j)) * ONE_IF_GTEQ(col.r, 0.5));
					}
					return uint4(ONE_IF_IN_RANGE(idx,0xE000,0xE800)?v:0, idx==0?0xAA55AA55:0, 0, 0);
				}

				// return this if unchanged
                col = _SelfTexture2D[uint2(idxx, idxy)];
				
				[branch]
				if (i.primitiveID) {
					uint cacheSize = read_emulator_word(CACHE_SIZE_ADDR, b);
					for (ci = 0; ci < cacheSize; ci++) {
						uint val = _SelfTexture2D[uint2(ci+0x21, 0xFF)].b;
						col.r = (idx == (val & 0xffff))?(val>>16):col.r;
					}
					col.b = (idx>=CACHE_SIZE_ADDR)?0:col.b;
					col.r = (idx==KEYCODE_RAM_PTR)?_InputChar:col.r;
				}
				// Compute next machine state
				else {
					uint regs[NUM_REGS + GRAM_SIZE/2 + STACK_SIZE/2 + FRAM_SIZE/2 + CACHE_SIZE + 1];
					uint notfound, arg, val, val2, val3, sval, sval2, sval3, opcode, jump;
					uint stno, stno2, stno3, rno;
					regs[0x200+NUM_REGS] = 0;

					[unroll]
					for (ci=255; ci>=0; ci--) {
						col2 = _SelfTexture2D[uint2(ci, 0xFF)];
						regs[NUM_REGS+ci] = col2.g;
						regs[NUM_REGS+0x100+ci] = col2.a;
						regs[ci&(NUM_REGS-1)] = col2.b;
					}

					int loops = min(_IPF_MAX, _IPF * unity_DeltaTime.x);

					[loop]
					for (int loop=0; (loop<loops)&&(regs[0x200+NUM_REGS]<CACHE_SIZE-1)&&!(regs[1]&F_HALT); loop++) {
						regs[4] = loops;
						regs[3]++;
						emu_read(regs[0], opcode);
						arg = (opcode >> 8) & 0xff;
						regs[0]++;
						emu_read(regs[0], val);
						opcode &= 0xff;
						rno = arg & 31;
					#define rno2 (val&31)
					#define rno3 ((val>>8)&31)
						stno = SELECT_STNO(arg);
						sval = SELECT_SVAL(stno, regs[rno]);
						stno2 = SELECT_STNO(val&0xff);
						sval2 = SELECT_SVAL(stno2, regs[rno2]);
						stno3 = SELECT_STNO(val>>8);
						sval3 = SELECT_SVAL(stno3, regs[rno3]);
					// prep for conditionals
						jump = ((regs[1] >> ((opcode & 0x6) >> 1)) ^ opcode) & 1;
					// ret, call and jump opcodes
						opcode = (opcode>=0xC8 && opcode<0xF8)?(opcode&0xF8):opcode;
					
					// increment past 2nd opcode word if applicable
						regs[0] += (opcode>=0x3E && opcode<0x70 || opcode>0x00 && opcode<=0x09 && opcode!=0x02 ||\
									opcode==0xD0 || opcode==0xE0 || opcode==0xFF || opcode>=0xC2 && opcode<=0xC6 && opcode!=0xC4)?1:0;
					// load 3rd opcode word
						emu_read(regs[0], val3);
						sval2 = ((opcode>=0x40 && opcode<0x70) && (opcode & 1))?\
							((stno==T_LONG&&(opcode<0x56||opcode>=0x60))?(val | (val3 << 16)):val):sval2;
						sval2 = (opcode==0x03 || opcode==0x09 || opcode==0xFF)?((stno==T_LONG)?(val | (val3 << 16)):val):sval2;
						sval2 = (opcode==0x06 || opcode==0xC6 || opcode==0xD0 || opcode==0xE0)?(val | (val3 << 16)):sval2;
					// opcodes with 3rd opcode word
						regs[0] += ((stno==T_LONG && (opcode==0x03 || opcode==0x06 || opcode==0x09 ||\
									(opcode & 1) && (opcode>=0x40 && opcode<0x56 || opcode>=0x60 && opcode<0x70))) ||\
									opcode==0xD0 || opcode==0xE0 || stno==T_LONG && opcode==0xFF)?1:0;

						stno3 = (opcode>=0x3E && opcode<0x70 && (opcode&1))?stno:stno3;
						val = (opcode>=0x40 && opcode<0x70 && (opcode & 1))?(rno<<8):val;
						opcode = (opcode>=0x40 && opcode<0x70)?(opcode&0xFE):opcode;
						sval2 += (opcode!=0x03 && opcode<0x3E)?ddoffset(val>>8):0;

						[branch]
						switch (opcode) {
							case 0x00: // nop
								break;
							case 0x01: // ld
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval2);
								break;
							case 0x02: // ldz
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], 0);
								break;
							case 0x03: // ldi
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval2);
								break;
							case 0x04: // ex
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval2);
								regs[rno2] = UPDATE_NUMBER_SECTION(stno2, regs[rno2], sval);
								break;
							case 0x05: // ildr rX, rY, offset
								emu_read(sval2, val2);
								emu_read(sval2+1, val3);
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], (val2|(val3<<16)));
								break;
							case 0x06: // ild rX, imm32
								emu_read(sval2, val2);
								emu_read(sval2+1, val3);
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], (val2|(val3<<16)));
								break;
							case 0x07: // str rX, rY, offset
								emu_write(sval2, (stno>=T_BYTE)?(sval&0xff):sval);
								if (stno == T_LONG) {
									emu_write(sval2+1, sval>>16);
								}
								break;
							case 0x08: // sti imm8, rX, offset
								emu_write(sval2, arg);
								break;
							case 0x09: // sto rX, imm32
								emu_write(sval2, (stno>=T_BYTE)?(sval&0xff):sval);
								if (stno == T_LONG) {
									emu_write(sval2+1, sval>>16);
								}
								break;
							case 0x0A: // inc rX
								sval++;
								sval = (stno>=T_BYTE)?(sval&0xff):((stno<=T_WORD+1)?(sval&0xffff):sval);
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval);
								regs[1] = (regs[1] & ~(F_ZERO|F_CARRY)) | ((sval==0)?(F_ZERO|F_CARRY):0);
								break;
							case 0x0B: // dec rX
								regs[1] = (regs[1]&~F_CARRY) | ((sval==0)?F_CARRY:0);
								sval--;
								sval = (stno>=T_BYTE)?(sval&0xff):((stno<=T_WORD+1)?(sval&0xffff):sval);
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval);
								regs[1] = (regs[1]&~F_ZERO) | ((sval==0)?F_ZERO:0);
								break;
							case 0x0C: // flagand
								regs[1] &= arg;
								break;
							case 0x0D: // flagor
								regs[1] |= arg;
								break;
							case 0x0E: // flagxor
								regs[1] ^= arg;
								break;
							case 0x0F: // strr rX, rY, rZ
								regs[0]++;
								emu_write(sval2+sval3, sval);
								if (stno == T_LONG)
									emu_write(sval2+sval3+1, sval >> 16);
								break;
							case 0x3E: // lor rX, rY, rZ
								sval = (sval || sval2) ? 1 : 0;
								break;
							case 0x3F: // land rX, rY, rZ
								sval = (sval && sval2) ? 1 : 0;
								break;
							case 0x40: // add
								regs[1] |= (overflowAdd(sval, sval2))?F_CARRYSAVE:0;
								sval += sval2;
								break;
							case 0x42: // adc
								regs[1] |= (overflowAdd(sval, sval2 + (regs[1] & F_CARRY)))?F_CARRYSAVE:0;
								sval += sval2 + (regs[1] & F_CARRY);
								break;
							case 0x44: // sub
								regs[1] |= (overflowSub(sval, sval2))?F_CARRYSAVE:0;
								sval -= sval2;
								break;
							case 0x46: // sbc
								regs[1] |= (overflowSub(sval, sval2 + (regs[1] & F_CARRY)))?F_CARRYSAVE:0;
								sval -= sval2 + (regs[1] & F_CARRY);
								break;
							case 0x48: // mul
								sval *= sval2;
								break;
							case 0x4A: // div
								regs[1] |= (sval2==0)?F_CARRYSAVE:0;
								sval = (sval==0?0xffffffff:(sval/sval2));
								break;
							case 0x4C: // mod
								regs[1] |= (sval2==0)?F_CARRYSAVE:0;
								sval = (sval==0?0xffffffff:(sval%sval2));
								break;
							case 0x4E: // cmp
								regs[1] |= ((sval<sval2)?F_CARRYSAVE:0);
								sval -= sval2;
								break;
							case 0x50: // and
								sval &= sval2;
								break;
							case 0x52: // or
								sval |= sval2;
								break;
							case 0x54: // xor
								sval ^= sval2;
								break;
							case 0x56: // shr
								regs[1] |= sval2>0&&sval2<32&&((sval>>(sval2-1))&1)?F_CARRYSAVE:0;
								sval >>= sval2;
								break;
							case 0x58: // shl
								regs[1] |= sval2>0&&sval2<32&&((sval<<(sval2-1))&0x80000000)?F_CARRYSAVE:0;
								sval <<= sval2;
								break;
							case 0x5A: // ror
								regs[1] |= sval2>0&&sval2<32&&((sval>>(sval2-1))&1)?F_CARRYSAVE:0;
								sval = (sval >> sval2) | (sval << (32 - sval2));
								break;
							case 0x5C: // rol
								regs[1] |= sval2>0&&sval2<32&&((sval<<(sval2-1))&0x80000000)?F_CARRYSAVE:0;
								sval = (sval << sval2) | (sval >> (32 - sval2));
								break;
							case 0x5E: // ashr
								regs[1] |= sval2>0&&sval2<32&&((sval>>(sval2-1))&1)?F_CARRYSAVE:0;
								sval = ((sval & 0x80000000)?(0x80000000|(0xffffffff << (32 - sval2))):0) | ((sval & 0x7FFFFFFF) >> sval2);
								break;
							case 0x60: // adds
								regs[1] |= (overflowAdds(sval, sval2))?F_CARRYSAVE:0;
								sval = (int)sval + (int)sval2;
								break;
							case 0x62: // adcs
								regs[1] |= (overflowAdds(sval, sval2 + (regs[1] & F_CARRY)))?F_CARRYSAVE:0;
								sval = (int)sval + (int)sval2 + (regs[1] & F_CARRY);
								break;
							case 0x64: // subs
								regs[1] |= (overflowSubs(sval, sval2))?F_CARRYSAVE:0;
								sval = (int)sval - (int)sval2;
								break;
							case 0x66: // sbcs
								regs[1] |= (overflowSubs(sval, sval2 + (regs[1] & F_CARRY)))?F_CARRYSAVE:0;
								sval = (int)sval - (int)sval2 + (regs[1] & F_CARRY);
								break;
							case 0x68: // muls
								sval = (int)sval * (int)sval2;
								break;
							case 0x6A: // divs
								regs[1] |= (sval2==0)?F_CARRYSAVE:0;
								sval = (sval==0?0xffffffff:(sval/sval2));
								break;
							case 0x6C: // mods
								regs[1] |= (sval2==0)?F_CARRYSAVE:0;
								sval = (sval==0?0xffffffff:(sval%sval2));
								break;
							case 0x6E: // cmps
								regs[1] |= (((int)sval < (int)sval2)?F_CARRYSAVE:0);
								sval -= sval2;
								break;
							case 0xC0: // push rX
								if (stno == T_LONG) {
									emu_write_long(regs[2]-2, sval);
								} else {
									emu_write(regs[2]-1, sval);
								}
								regs[2] -= (stno == T_LONG)?2:1;
								break;
							case 0xC1: // pop rX
								emu_read(regs[2], val);
								emu_read(regs[2]+1, val2);
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], val | (val2 << 16));
								regs[2] += (stno == T_LONG)?2:1;
								break;
							case 0xC2: // pea rX, rY, offset
								regs[2] -= 2;
								emu_write_long(regs[2], sval+sval2);
								break;
							case 0xC3: // pea rX, offset16
								regs[2] -= 2;
								emu_write_long(regs[2], sval+ddoffset16(val));
								break;
							case 0xC4: // pushb
								regs[2]--;
								emu_write(regs[2], arg);
								break;
							case 0xC5: // pushw
								regs[2]--;
								emu_write(regs[2], val);
								break;
							case 0xC6: // pushl
								regs[2] -= 2;
								emu_write_long(regs[2], sval2);
								break;
							case 0xC8: // ret
								emu_read(regs[2], val);
								emu_read(regs[2]+1, val2);
								regs[2] += jump?2:0;
								regs[0] = jump?(val | (val2 << 16)):regs[0];
								break;
							case 0xD0: // call imm32
								if (jump) {
									emu_write_long(regs[2]-2, regs[0]);
								}
								regs[2] -= jump?2:0;
								regs[0] = jump?sval2:regs[0];
								break;
							case 0xD8: // call rX
								if (jump) {
									emu_write_long(regs[2]-2, regs[0]);
								}
								regs[2] -= jump?2:0;
								regs[0] = jump?sval:regs[0];
								break;
							case 0xE0: // jp imm32
								regs[0] = jump?sval2:regs[0];
								break;
							case 0xE8: // jp rX
								regs[0] = jump?sval:regs[0];
								break;
							case 0xF0: // jr offset
								regs[0] += jump?ddoffset(arg):0;
								break;
							case 0xF8: // delay rX
								regs[0] -= (sval > 0)?1:0;
								sval -= (sval > 0)?1:0;
								regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval);
								break;
							case 0xFF: // testhalt rX, value
								regs[1] |= (sval != sval2)?F_HALT:0;
								break;
							default:
								regs[5] = opcode;
								regs[1] |= F_HALT;
								break;
						}
						
						regs[1] = (opcode>=0x3E&&opcode<0x70)?\
							((regs[1] & ~(F_CARRY|F_CARRYSAVE|F_ZERO)) | ((regs[1] & F_CARRYSAVE)?F_CARRY:0) | (sval==0?F_ZERO:0)):regs[1];
						regs[rno3] = (opcode>=0x3E && opcode<0x70 && opcode!=0x4E && opcode!=0x6E)?\
							UPDATE_NUMBER_SECTION(stno3, regs[rno3], sval):regs[rno3];
					}
					col.b = (idxx<NUM_REGS)?regs[idxx]:((idxx<=NUM_REGS+regs[0x200+NUM_REGS])?regs[0x200+idxx]:0);
					col.g = regs[NUM_REGS+idxx];
					col.a = regs[NUM_REGS+0x100+idxx];
				}
                return col;
            }
            ENDCG
        }
    }
}
