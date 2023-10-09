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
#define CACHE_SIZE_ADDR 0xff40
#define CACHE_ADDR 0xff41
#define CACHE_SIZE (0xfd-0x41)
#define F_CARRY 1
#define F_ZERO 2
#define F_SIGN 4
#define F_CARRYSAVE 8
#define F_HALT 32

#define ADDR_ROM_START    0x00000000
#define ADDR_ROM_END      0x0FFFFFFF
#define ADDR_ROM_MASK     0x0FFFFFFF
#define ROM_SIZE          0x10000000
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
#define ONE_IF_IN_RANGE(v,a,b) (ONE_IF_GTEQ(v,a)-ONE_IF_GTEQ(v,b))
#define SELECT_IF_IN_RANGE(v,a,b,c,d) SELECT(c,d,ONE_IF_IN_RANGE(v,a,b))
#define ONE_IF_EQUAL(v,a) ((v)==(a))
#define SELECT_IF_EQUAL(v,a,c,d) SELECT(c,d,ONE_IF_EQUAL(v,a))

#define read_emulator_word(addr, component) (_SelfTexture2D[uint2((addr) & 0xFF, (addr) >> 8)].component)
#define _emu_read_fram(addr, res) res = (regs[0x180+NUM_REGS+((addr)&0x7F)]>>SELECT_IF_GTEQ((addr)&FRAM_MASK,0x80,16,0))&0xffff;
#define _emu_read_stack(addr, res) res = (regs[0x100+NUM_REGS+((addr)&0x7F)]>>SELECT_IF_GTEQ((addr)&STACK_MASK,0x80,16,0))&0xffff;
#define _emu_read_gram(addr, res) res = (regs[NUM_REGS+((addr)&0xFF)]>>SELECT_IF_GTEQ((addr)&GRAM_MASK,0x100,16,0))&0xffff;
#define _emu_read_ram(addr, res) res = _SelfTexture2D[uint2((addr)&0xff, ((addr)>>8)&0xff)].r;
#define _emu_read_rom(addr, res) res = tex2Dlod(_RomTex, float4(((addr)&0xfff)/4096.0f, ((addr)>>12)/4096.0f,0,0.0)).r*65535.0f;
#define emu_read(addr, res) { if ((addr)>=ADDR_FRAM_START&&(addr)<=ADDR_FRAM_END) _emu_read_fram(addr, res) else if ((addr)>=ADDR_GRAM_START&&(addr)<=ADDR_GRAM_END) _emu_read_gram(addr, res) else if ((addr)>=ADDR_STACK_START&&(addr)<=ADDR_STACK_END) _emu_read_stack(addr, res) else if ((addr)>=ADDR_ROM_START&&(addr)<=ADDR_ROM_END) _emu_read_rom(addr, res) else if ((addr)>=ADDR_RAM_START && (addr)<=ADDR_RAM_END) { notfound = 1; [loop] for (ci=cacheSize-1; ci>=0; ci--) { if (cache[ci] & 0xffff == (addr)) {res = cache[ci] >> 16; notfound = 0; break; }} if (notfound) _emu_read_ram(addr, res) } else res = 0; }
#define emu_read_long(addr, res) {emu_read(addr, val); emu_read(addr+1, tmp); val |= tmp << 16; }
#define overflowAdd(a, b) (((a)&0x80000000)&&((b)&0x80000000))
#define overflowAdds(a, b) ((((a)&0x80000000)^((b)&0x80000000))?0:((((a)&0x40000000)&&((b)&0x40000000))^((a+b)&0x80000000)))
#define overflowSub(a, b) ((a)<(b))
#define overflowSubs(a, b) ((int)(a)<(int)(b))
#define ddoffset(v) ((((v)&0x80)?((v)-0x100):(v)))
#define ddoffset16(v) (((v)&0x8000)?((v)-0x10000):(v))
#define _emu_write_fram(addr, value) regs[0x180+NUM_REGS+((addr)&0x7F)] = (regs[0x180+NUM_REGS+((addr)&0x7F)] & SELECT_IF_GTEQ((addr)&FRAM_MASK,0x80,0x0000ffff,0xffff0000)) | (((value)&0xffff)<<SELECT_IF_GTEQ((addr)&FRAM_MASK,0x80,16,0));
#define _emu_write_stack(addr, value) regs[0x100+NUM_REGS+((addr)&0x7F)] = (regs[0x100+NUM_REGS+((addr)&0x7F)] & SELECT_IF_GTEQ((addr)&STACK_MASK,0x80,0x0000ffff,0xffff0000)) | (((value)&0xffff)<<SELECT_IF_GTEQ((addr)&STACK_MASK,0x80,16,0));
#define _emu_write_gram(addr, value) regs[NUM_REGS+((addr)&0xFF)] = (regs[NUM_REGS+((addr)&0xFF)] & SELECT_IF_GTEQ((addr)&GRAM_MASK,0x100,0x0000ffff,0xffff0000)) | (((value)&0xffff)<<SELECT_IF_GTEQ((addr)&GRAM_MASK,0x100,16,0));
#define emu_write(addr, value) { if ((addr)>=ADDR_FRAM_START&&(addr)<=ADDR_FRAM_END) _emu_write_fram(addr, value) else if ((addr)>=ADDR_GRAM_START&&(addr)<=ADDR_GRAM_END) _emu_write_gram(addr, value) else if ((addr)>=ADDR_STACK_START&&(addr)<=ADDR_STACK_END) _emu_write_stack(addr, value) else cache[cacheSize++] = ((addr) & 0xffff) | ((value) << 16);}
#define emu_write_long(addr, value) { emu_write(addr, value); emu_write((addr)+1, (value)>>16); }
#define TRUE 1
#define FALSE 0
#define intasfloat(value) (float)(*(uint32_t*)&(value));
#define floatasint(value) (int32_t)(*(float*)&(value));


// the order here matters to the selection routines
#define T_WORD 1
#define T_LONG 3
#define T_BYTE 4

// return a with 32, 16, or 8 bits updated with b, determined by load type s
#define UPDATE_NUMBER_SECTION(s,a,b) (((a) & ~(0xff << (8*((s)-T_BYTE))) | ((b) << (8*((s)-T_BYTE))))*ONE_IF_GTEQ(s,T_BYTE)+\
									  (((a) & ~(0xffff << (16*((s)-T_WORD)))) | ((b) << (16*((s)-T_WORD))))*ONE_IF_LTEQ(s,T_WORD)+\
									  sval*ONE_IF_EQUAL(s,T_LONG))

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
					return uint4(v*ONE_IF_IN_RANGE(idx,0xE000,0xE800), idx==0?0xAA55AA55:0, 0, 0);
				}

				// return this if unchanged
                col = _SelfTexture2D[uint2(idxx, idxy)];
				
				[branch]
				if (i.primitiveID) {
					uint cacheSize = read_emulator_word(CACHE_SIZE_ADDR, b);
					for (ci = 0x41+cacheSize - 1; ci >= 0x41; ci--) {
						uint val = _SelfTexture2D[uint2(ci, 0xFF)].b;
						col.r = (idx == (val & 0xffff))?(val>>16):col.r;
					}
					col.b = (idx>=CACHE_SIZE_ADDR)?0:col.b;
					col.r = (idx==KEYCODE_RAM_PTR)?_InputChar:col.r;
				}
				// Compute next machine state
				else {
					uint regs[NUM_REGS + GRAM_SIZE/2 + STACK_SIZE/2 + FRAM_SIZE/2];
					uint cacheSize = 0;
					uint cache[CACHE_SIZE];
					uint notfound, arg, val, val2, val3, sval, sval2, sval3, opcode, jump;
					uint stno, stno2, stno3, rno;

					[unroll]
					for (ci=255; ci>=0; ci--) {
						col2 = _SelfTexture2D[uint2(ci, 0xFF)];
						regs[NUM_REGS+ci] = col2.g;
						regs[NUM_REGS+0x100+ci] = col2.a;
						regs[ci&(NUM_REGS-1)] = col2.b;
					}

					int loops = min(_IPF_MAX, _IPF * unity_DeltaTime.x);

					[loop]
					for (int loop=0; (loop<loops)-(cacheSize>=CACHE_SIZE-1); loop++) {
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
						jump = ((regs[1] >> ((opcode & 0x6) >> 1)) ^ (opcode & 1)) & 1;
						// ret, call and jump opcodes
						opcode = SELECT_IF_IN_RANGE(opcode,0xC8,0xF8,opcode&0xF8,opcode);
						[branch]
						if (opcode >= 0x3E && opcode < 0x70) {
							regs[0]++;
							if (opcode & 1 && opcode >= 0x40) { // arithmetic opcodes with immediate
								if ((opcode < 0x56 || opcode >= 0x60)) { // arithmetic opcodes with variable length immediate
									if (stno == T_LONG) {
										emu_read(regs[0], val2);
										regs[0]++;
										sval2 = val | (val2 << 16);
									} else {
										sval2 = val;
									}
								} else { // bit shift opcodes
									sval2 = val;
								}
								stno3 = stno;
								val = rno << 8;
							}
							opcode &= 0xFE;
						} else {
							// many non arithmetic opcodes have an 8 bit displacement
							sval2 += ddoffset(val >> 8);
						}

						[branch]
						switch (opcode) {
							case 0x00: // nop
								break;
							case 0x01: // ld
								regs[0]++;
								if (stno == T_LONG) {
									regs[rno] = sval2;
								} else if (stno < T_BYTE) {
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | (sval2 << (16*(stno-T_WORD)));
								} else {
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | (sval2 << (8*(stno-T_BYTE)));
								}
								break;
							case 0x02: // ldz
								if (stno == T_LONG) {
									regs[rno] = 0;
								} else if (stno < T_BYTE) {
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD))));
								} else {
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE))));
								}
								break;
							case 0x03: // ldi
								regs[0]++;
								if (stno == T_LONG) {
									emu_read(regs[0], val2);
									regs[0]++;
									regs[rno] = val | (val2 << 16);
								} else if (stno < T_BYTE) {
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | (val << (16*(stno-T_WORD)));
								} else {
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | ((val & 0xff) << (8*(stno-T_BYTE)));
								}
								break;
							case 0x04: // ex
								regs[0]++;
								if (stno == T_LONG) {
									regs[rno] = sval2;
									regs[rno2] = sval;
								} else if (stno < T_BYTE) {
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | ((sval2 & 0xffff) << (16*(stno-T_WORD)));
									regs[rno2] = (regs[rno2] & ~(0xffff << (16*(stno2-T_WORD)))) | ((sval & 0xffff) << (16*(stno2-T_WORD)));
								} else {
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | ((sval2 & 0xff) << (8*(stno-T_BYTE)));
									regs[rno2] = (regs[rno2] & ~(0xff << (8*(stno2-T_BYTE)))) | ((sval & 0xff) << (8*(stno2-T_BYTE)));
								}
								break;
							case 0x05: // ildr rX, rY, offset
								regs[0]++;
								emu_read(sval2, val2);
								if (stno == T_LONG) {
									regs[rno] = val2;
									emu_read(sval2+1, val2);
									regs[rno] |= val2 << 16;
								} else if (stno < T_BYTE) {
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | (val2 << (16*(stno-T_WORD)));
								} else {
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | ((val2 & 0xff) << (8*(stno-T_BYTE)));
								}
								break;
							case 0x06: // ild rX, imm32
								regs[0]++;
								emu_read(regs[0], val2);
								regs[0]++;
								val2 = val | (val2 << 16);
								emu_read(val2, val3);
								if (stno == T_LONG) {
									emu_read(val2+1, val);
									regs[rno] = val3 | (val << 16);
								} else if (stno < T_BYTE) {
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | (val3 << (16*(stno-T_WORD)));
								} else {
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | ((val3 & 0xff) << (8*(stno-T_BYTE)));
								}
								break;
							case 0x07: // str rX, rY, offset
								regs[0]++;
								if (stno == T_LONG) {
									emu_write(sval2, sval);
									emu_write(sval2+1, sval>>16);
								} else if (stno < T_BYTE) {
									emu_write(sval2, sval&0xffff);
								} else {
									emu_write(sval2, sval&0xff);
								}
								break;
							case 0x08: // sti imm8, rX, offset
								regs[0]++;
								emu_write(sval2, arg);
								break;
							case 0x09: // sto rX, imm32
								regs[0]++;
								emu_read(regs[0], val2);
								regs[0]++;
								val2 = val | (val2 << 16);
								if (stno == T_LONG) {
									emu_write(val2, sval);
									emu_write(val2+1, sval>>16);
								} else if (stno < T_BYTE) {
									emu_write(val2, sval&0xffff);
								} else {
									emu_write(val2, sval&0xff);
								}
								break;
							case 0x0A: // inc rX
								sval++;
								if (stno == T_LONG) {
									regs[rno] = sval;
								} else if (stno < T_BYTE) {
									sval &= 0xffff;
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | ((sval & 0xffff) << (16*(stno-T_WORD)));
								} else {
									sval &= 0xff;
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | (sval << (8*(stno-T_BYTE)));
								}
								if (sval == 0) {
									regs[1] |= F_ZERO|F_CARRY;
								} else {
									regs[1] &= ~(F_ZERO|F_CARRY);
								}
								break;
							case 0x0B: // dec rX
								if (sval == 0) {
									regs[1] |= F_CARRY;
								} else {
									regs[1] &= ~F_CARRY;
								}
								sval--;
								if (stno == T_LONG) {
									regs[rno] = sval;
								} else if (stno < T_BYTE) {
									sval &= 0xffff;
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | ((sval & 0xffff) << (16*(stno-T_WORD)));
								} else {
									sval &= 0xff;
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | (sval << (8*(stno-T_BYTE)));
								}
								if (sval == 0) {
									regs[1] |= F_ZERO;
								} else {
									regs[1] &= ~F_ZERO;
								}
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
								if (stno == T_LONG) {
									emu_write(sval2+sval3+1, sval >> 16);
								}
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
								if (sval2 == 0) {
									regs[1] |= F_CARRYSAVE;
									sval = 0xffffffff;
								} else {
									sval /= sval2;
								}
								break;
							case 0x4C: // mod
								if (sval2 == 0) {
									regs[1] |= F_CARRYSAVE;
									sval = 0xffffffff;
								} else {
									sval %= sval2;
								}
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
								if (sval2 < 32 && sval2 > 0) {
									regs[1] |= (((sval>>(sval2-1))&1)?F_CARRYSAVE:0);
								}
								sval >>= sval2;
								break;
							case 0x58: // shl
								if (sval2 < 32 && sval2 > 0) {
									regs[1] |= (((sval<<(sval2-1))&0x80000000)?F_CARRYSAVE:0);
								}
								sval <<= sval2;
								break;
							case 0x5A: // ror
								if (sval2 < 32 && sval2 > 0) {
									regs[1] |= (((sval>>(sval2-1))&1)?F_CARRYSAVE:0);
								}
								sval = (sval >> sval2) | (sval << (32 - sval2));
								break;
							case 0x5C: // rol
								if (sval2 < 32 && sval2 > 0) {
									regs[1] |= (((sval<<(sval2-1))&0x80000000)?F_CARRYSAVE:0);
								}
								sval = (sval << sval2) | (sval >> (32 - sval2));
								break;
							case 0x5E: // ashr
								if (sval2 < 32 && sval2 > 0) {
									regs[1] |= (((sval>>(sval2-1))&1)?F_CARRYSAVE:0);
								}
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
								if (sval2 == 0) {
									regs[1] |= F_CARRYSAVE;
									sval = 0xffffffff;
								} else {
									sval = (int)sval / (int)sval2;
								}
								break;
							case 0x6C: // mods
								if (sval2 == 0) {
									regs[1] |= F_CARRYSAVE;
									sval = 0xffffffff;
								} else {
									sval = (int)sval % (int)sval2;;
								}
								break;
							case 0x6E: // cmps
								regs[1] |= (((int)sval < (int)sval2)?F_CARRYSAVE:0);
								sval -= sval2;
								break;
							case 0xC0: // push rX
								regs[2]--;
								if (stno == T_LONG) {
									regs[2]--;
									emu_write_long(regs[2], sval);
								} else {
									emu_write(regs[2], sval);
								}
								break;
							case 0xC1: // pop rX
								if (stno == T_LONG) {
									emu_read(regs[2], val);
									regs[2]++;
									emu_read(regs[2], val2);
									regs[rno] = val | (val2 << 16);
								} else if (stno < T_BYTE) {
									emu_read(regs[2], val);
									regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | (val << (16*(stno-T_WORD)));
								} else {
									emu_read(regs[2], val);
									regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | ((val & 0xff) << (8*(stno-T_BYTE)));
								}
								regs[2]++;
								break;
							case 0xC2: // pea rX, rY, offset
								regs[0]++;
								regs[2]--;
								regs[2]--;
								emu_write_long(regs[2], sval2+sval);
								break;
							case 0xC3: // pea rX, offset16
								regs[0]++;
								regs[2]--;
								regs[2]--;
								emu_write_long(regs[2], ddoffset16(val)+sval);
								break;
							case 0xC4: // pushb
								regs[2]--;
								emu_write(regs[2], arg);
								break;
							case 0xC5: // pushw
								regs[0]++;
								regs[2]--;
								emu_write(regs[2], val);
								break;
							case 0xC6: // pushl
								regs[0]++;
								emu_read(regs[0], val2);
								regs[0]++;
								regs[2]--;
								emu_write(regs[2], val2);
								regs[2]--;
								emu_write(regs[2], val);
								break;
							case 0xC8: // ret
								if (jump) {
									emu_read(regs[2], val);
									regs[2]++;
									emu_read(regs[2], val2);
									regs[2]++;
									regs[0] = val | (val2 << 16);
								}
								break;
							case 0xD0: // call imm32
								regs[0]++;
								if (jump) {
									emu_read(regs[0], val2);
									regs[0]++;
									regs[2] -= 2;
									emu_write_long(regs[2], regs[0]);
									regs[0] = val | (val2 << 16);
								} else {
									regs[0]++;
								}
								break;
							case 0xD8: // call rX
								regs[0]++;
								if (jump) {
									regs[2] -= 2;
									emu_write_long(regs[2], regs[0]);
									regs[0] = sval;
								}
								break;
							case 0xE0: // jp imm32
								regs[0]++;
								if (jump) {
									emu_read(regs[0], val2);
									regs[0] = val | (val2 << 16);
								} else {
									regs[0]++;
								}
								break;
							case 0xE8: // jp rX
								if (jump) {
									regs[0] = sval;
								}
								break;
							case 0xF0: // jr offset
								if (jump) {
									regs[0] += ddoffset(arg);
								}
								break;
							case 0xF8: // delay rX
								if (sval > 0) {
									regs[0]--;
									sval--;
									if (stno == T_LONG) {
										regs[rno] = sval;
									} else if (stno < T_BYTE) {
										regs[rno] = (regs[rno] & ~(0xffff << (16*(stno-T_WORD)))) | (sval << (16*(stno-T_WORD)));
									} else {
										regs[rno] = (regs[rno] & ~(0xff << (8*(stno-T_BYTE)))) | (sval << (8*(stno-T_BYTE)));
									}
								}
								break;
							default:
								regs[5] = regs[0];
								regs[6] = opcode;
								regs[0] = 0;
								break;
						}
						[branch]
						if (opcode >= 0x3E && opcode < 0x70) { // lor, land, arithmetic opcodes
							regs[1] = (regs[1] & ~(F_CARRY|F_CARRYSAVE|F_ZERO)) | ((regs[1] & F_CARRYSAVE)?F_CARRY:0) | (sval==0?F_ZERO:0);
							if (opcode != 0x4E && opcode != 0x6E) { // don't store registers for cmp opcodes
								if (stno3 == T_LONG) {
									regs[rno3] = sval;
								} else if (stno3 < T_BYTE) {
									regs[rno3] = (regs[rno3] & ~(0xffff << (16*(stno3-T_WORD)))) | (sval << (16*(stno3-T_WORD)));
								} else {
									regs[rno3] = (regs[rno3] & ~(0xff << (8*(stno3-T_BYTE))) | (sval << (8*(stno3-T_BYTE))));
								}
							}
						}
					}
					col.b = SELECT_IF_LT(idxx,NUM_REGS,regs[idxx],SELECT_IF_GTEQ(idxx,0x41,cache[idxx-0x41],cacheSize));
					col.g = regs[NUM_REGS+idxx];
					col.a = regs[NUM_REGS+0x100+idxx];
				}
                return col;
            }
            ENDCG
        }
    }
}
