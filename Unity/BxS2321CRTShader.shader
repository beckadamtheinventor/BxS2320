Shader "BeckATI/BxS2321/CRTShader"
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

// Registers are stored in row 255 column 0-31 channel B
// Cache size is stored in row 255 column 32 channel B
// Cache is stored in row 255 columns 33-255 channel B
// GRAM is stored in row 255 columns 0-255 channel G
// Stack RAM is stored in row 255 columns 0-127 channel A
// FRAM is stored in row 255 columns 128-255 channel A
// RAM is stored in channel R

		Pass
		{
			Tags { "RenderType"="Opaque" }
			LOD 100
			CGPROGRAM
			#pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #include "rvc-crt.cginc"
			#include "defines.cginc"
			
            sampler2D _RomTex;
            sampler2D _FontTex;
			sampler2D _InputCharTex;

            uint4 frag (v2f_customrendertexture i) : SV_Target
            {
				uint idxx = i.globalTexcoord.x * 256.0f;
				uint idxy = i.globalTexcoord.y * 256.0f;
				uint idx = idxy * 256 + idxx;
				uint j;
				uint4 col;
				uint v = 0;
				if (ONE_IF_IN_RANGE(idx,0xE000,0xE800)) {
					[unroll]
					for (j=0; j<8; j++) {
						col = tex2D(_FontTex, float2(((idx>>3)&15)/16.0f + j/128.0f, (16 - ((idx>>7)&15))/16.0f - ((idx&7)+1)/128.0f));
						v |= uint((1 << (7-j)) * ONE_IF_GTEQ(col.r, 0.5));
					}
				}
				col = uint4(v, idx==0?0xAA55AA55:0, 0, 0);
                return (read_emulator_word(0, g) != 0xAA55AA55 || tex2D(_InputCharTex, float2(0.5f, 0.5f)).g >= 1.0f)?col:_SelfTexture2D[uint2(idxx, idxy)];
			}
			ENDCG
		}

        Pass
        {
			Tags { "RenderType"="Opaque" }
			LOD 1000
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #include "rvc-crt.cginc"
			#include "defines.cginc"
			
            sampler2D _RomTex;
            sampler2D _FontTex;
			sampler2D _InputCharTex;
			float _IPF;
			float _IPF_MAX;

            uint4 frag (v2f_customrendertexture i) : SV_Target
            {
				uint idxx = i.globalTexcoord.x * 256.0f;
				uint idxy = i.globalTexcoord.y * 256.0f;
				uint idx = idxy * 256 + idxx;
				uint j;
				int ci;
				uint4 col, col2;
                col = _SelfTexture2D[uint2(idxx, idxy)];

				uint regs[NUM_REGS + 0x200 + CACHE_SIZE + 3];
				uint notfound, found, arg, val, val2, val3, sval, sval2, sval3, opcode, jump;
				uint stno, stno2, stno3, rno, tmp, waddr, paddr, wval, wsize, wshift;
				regs[0x200+NUM_REGS] = 0;

				[unroll]
				for (ci=0; ci<256; ci++) {
					col2 = _SelfTexture2D[uint2(ci, 0xFF)];
					regs[NUM_REGS+ci] = col2.g;
					regs[NUM_REGS+0x100+ci] = col2.a;
				}

				[unroll]
				for (ci=0; ci<NUM_REGS; ci++) {
					regs[ci] = _SelfTexture2D[uint2(ci, 0xFF)].b;
				}

				int loops = min(_IPF_MAX, _IPF * unity_DeltaTime.x);

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
					opcode -= (opcode>=0xC8 && opcode<0xF8)*(opcode&7);

				// increment past 2nd opcode word if applicable
					regs[0] += ((opcode>=0x3E && opcode<0x56) || (opcode>0x00 && opcode<=0x08) ||\
								opcode==0xD0 || opcode==0xE0 || opcode==0xFF || (opcode>=0xC2 && opcode<=0xC6 && opcode!=0xC4));
				// load 3rd opcode word
					emu_read(regs[0], val3);
					sval2 += (opcode==0x03 || opcode==0xFF || (opcode>=0x40 && opcode<0x56 && opcode&1)) * (val + (stno==T_LONG)*(val3 << 16) - sval2);
					sval2 += (opcode==0x02 || opcode==0x06 || opcode==0xC6 || opcode==0xD0 || opcode==0xE0) * ((val | (val3 << 16))-sval2);
				// increment past 3rd opcode word if applicable
					regs[0] += ((stno==T_LONG && (opcode==0x03 || opcode==0xFF ||\
								((opcode & 1) && (opcode>=0x40 && opcode<0x56)))) ||\
								opcode==0xD0 || opcode==0xE0 || opcode==0x02 || opcode==0x06);

					stno3 += (opcode>=0x3E && opcode<0x56 && (opcode&1))*(stno-stno3);
					val += (opcode>=0x40 && opcode<0x56 && (opcode&1))*((rno<<8)-val);
					opcode -= (opcode>=0x40 && opcode<0x56)*(opcode&1);
					sval2 += (opcode!=0x02 && opcode!=0x03 && opcode!=0x06 && opcode<0x3E)*ddoffset(val>>8);

					waddr = wval = wsize = 0;

					switch (opcode) {
						case 0x00: // nop
							break;
						case 0x01: // ld
							regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval2);
							break;
						case 0x02: // sto rX, imm32
							paddr = sval2;
							waddr = GET_WADDR(sval2);
							wval = (stno>=T_BYTE)?(sval&0xff):sval;
							wsize = 1+(stno==T_LONG);
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
							paddr = sval2;
							waddr = GET_WADDR(sval2);
							wval = (stno>=T_BYTE)?(sval&0xff):sval;
							wsize = 1+(stno==T_LONG);
							break;
						case 0x08: // sti imm8, rX, offset
							paddr = sval2;
							waddr = GET_WADDR(sval2);
							wval = arg;
							wsize = 1;
							break;
						case 0x09: // ldz
							regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], 0);
							break;
						case 0x0A: // inc rX
							sval++;
							regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval);
							regs[1] = (regs[1] & ~(F_ZERO|F_CARRY)) | ((sval&(0xffffffff*(sval==T_LONG)+0xffff-(0xff00*(stno>=T_BYTE))*(sval!=T_LONG))==0)*(F_CARRY+F_ZERO));
							break;
						case 0x0B: // dec rX
							regs[1] = (regs[1]&~F_CARRY) | ((sval==0)*F_CARRY);
							sval--;
							regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval);
							regs[1] = (regs[1]&~F_ZERO) | ((sval&(0xffffffff*(sval==T_LONG)+0xffff-(0xff00*(stno>=T_BYTE))*(sval!=T_LONG))==0)*F_ZERO);
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
							paddr = sval2+sval3;
							waddr = GET_WADDR(sval2+sval3);
							wval = sval;
							wsize = 1;
							break;
						case 0x3E: // lor rX, rY, rZ
							sval = (sval || sval2);
							break;
						case 0x3F: // land rX, rY, rZ
							sval = (sval && sval2);
							break;
						case 0x40: // add
							regs[1] |= (overflowAdd(sval, sval2))*F_CARRYSAVE;
							sval += sval2;
							break;
						case 0x42: // adc
							regs[1] |= (overflowAdd(sval, sval2 + (regs[1] & F_CARRY)))*F_CARRYSAVE;
							sval += sval2 + (regs[1] & F_CARRY);
							break;
						case 0x44: // sub
							regs[1] |= (overflowSub(sval, sval2))*F_CARRYSAVE;
							sval -= sval2;
							break;
						case 0x46: // sbc
							regs[1] |= (overflowSub(sval, sval2 + (regs[1] & F_CARRY)))*F_CARRYSAVE;
							sval -= sval2 + (regs[1] & F_CARRY);
							break;
						case 0x48: // mul
							sval *= sval2;
							break;
						case 0x4A: // div
							regs[1] |= (sval2==0)*F_CARRYSAVE;
							sval = (sval2==0?0xffffffff:(sval/sval2));
							break;
						case 0x4C: // mod
							regs[1] |= (sval2==0)*F_CARRYSAVE;
							sval = (sval2==0?0xffffffff:(sval%sval2));
							break;
						case 0x4E: // cmp
							regs[1] |= ((sval<sval2)*F_CARRYSAVE);
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
							regs[1] |= (sval2>0&&sval2<32&&((sval>>(sval2-1))&1))*F_CARRYSAVE;
							sval >>= sval2;
							break;
						case 0x58: // shl
							regs[1] |= (sval2>0&&sval2<32&&((sval<<(sval2-1))&0x80000000))*F_CARRYSAVE;
							sval <<= sval2;
							break;
						case 0x5A: // ror
							regs[1] |= (sval2>0&&sval2<32&&((sval>>(sval2-1))&1))*F_CARRYSAVE;
							sval = (sval >> sval2) | (sval << (32 - sval2));
							break;
						case 0x5C: // rol
							regs[1] |= (sval2>0&&sval2<32&&((sval<<(sval2-1))&0x80000000))*F_CARRYSAVE;
							sval = (sval << sval2) | (sval >> (32 - sval2));
							break;
						case 0x5E: // ashr
							regs[1] |= sval2>0&&sval2<32&&((sval>>(sval2-1))&1)?F_CARRYSAVE:0;
							sval = (uint(sval / 0x80000000)*(0x80000000|(0xffffffff << (32 - sval2)))) | ((sval & 0x7FFFFFFF) >> sval2);
							break;
						case 0xC0: // push rX
							regs[2] -= (stno == T_LONG)?2:1;
							paddr = regs[2];
							waddr = GET_WADDR(regs[2]);
							wval = sval;
							wsize = 1+(stno == T_LONG);
							break;
						case 0xC1: // pop rX
							emu_read(regs[2], val);
							emu_read(regs[2]+1, val2);
							regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], val | (val2 << 16));
							regs[2] += 1+(stno == T_LONG);
							break;
						case 0xC2: // pea rX, rY, offset
							regs[2] -= 2;
							waddr = GET_WADDR(regs[2]);
							wval = sval+sval2;
							wsize = 2;
							break;
						case 0xC3: // pea rX, offset16
							regs[2] -= 2;
							paddr = regs[2];
							waddr = GET_WADDR(regs[2]);
							wval = sval+ddoffset16(val);
							wsize = 2;
							break;
						case 0xC4: // pushb
							regs[2]--;
							paddr = regs[2];
							waddr = GET_WADDR(regs[2]);
							wval = arg;
							wsize = 1;
							break;
						case 0xC5: // pushw
							regs[2]--;
							paddr = regs[2];
							waddr = GET_WADDR(regs[2]);
							wval = val;
							wsize = 1;
							break;
						case 0xC6: // pushl
							regs[2] -= 2;
							paddr = regs[2];
							waddr = GET_WADDR(regs[2]);
							wval = sval2;
							wsize = 2;
							break;
						case 0xC8: // ret
							emu_read(regs[2], val);
							emu_read(regs[2]+1, val2);
							regs[2] += jump*2;
							regs[0] += jump*((val | (val2 << 16))-regs[0]);
							break;
						case 0xD0: // call imm32
							regs[2] -= jump*2;
							paddr = regs[2];
							waddr += jump*(GET_WADDR(regs[2])-waddr);
							wval = regs[0];
							wsize = 2;
							regs[0] += jump*(sval2-regs[0]);
							break;
						case 0xD8: // call rX
							regs[2] -= jump*2;
							paddr = regs[2];
							waddr += jump*(GET_WADDR(regs[2])-waddr);
							wval = regs[0];
							wsize = 2;
							regs[0] += jump*(sval-regs[0]);
							break;
						case 0xE0: // jp imm32
							regs[0] += jump*(sval2-regs[0]);
							break;
						case 0xE8: // jp rX
							regs[0] += jump*(sval-regs[0]);
							break;
						case 0xF0: // jr offset
							regs[0] += jump*ddoffset(arg);
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

					wshift = waddr>>12;
					waddr &= 0xfff;
					if (wsize > 0) {
						regs[waddr] = ((regs[waddr] & ~(0xffff<<wshift)) | (wval << wshift));
						if (waddr>=0x201+NUM_REGS)
							regs[waddr] = (paddr&0xffff) | (wval<<16);
					}
					if (wsize > 1) {
						regs[waddr+1] = ((regs[waddr+1] & ~(0xffff<<wshift)) | ((wval >> 16) << wshift));
						if (waddr+1>=0x201+NUM_REGS)
							regs[waddr+1] = ((paddr+1)&0xffff) | (wval&0xffff0000);
					}
					regs[0x200+NUM_REGS] += (waddr>=0x201+NUM_REGS)*wsize;

					if (opcode>=0x3E&&opcode<0x56)
						regs[1] = (regs[1] & ~(F_CARRY|F_CARRYSAVE|F_ZERO)) | ((regs[1] & F_CARRYSAVE)*F_CARRY)/F_CARRYSAVE | (sval==0)*F_ZERO;
					if (opcode>=0x3E && opcode<0x56 && opcode!=0x4E)
						regs[rno3] = UPDATE_NUMBER_SECTION(stno3, regs[rno3], sval);
				}
				col.b = (idxx<NUM_REGS)*regs[idxx] + (uint(idxx-NUM_REGS)<=regs[0x200+NUM_REGS])*regs[0x200+idxx];
				col.g = regs[NUM_REGS+idxx];
				col.a = regs[NUM_REGS+0x100+idxx];
                return col;
            }
            ENDCG
        }

		Pass
		{
			Tags { "RenderType"="Opaque" }
			LOD 100
			CGPROGRAM
			#pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #include "rvc-crt.cginc"
			#include "defines.cginc"
			
            sampler2D _RomTex;
            sampler2D _FontTex;
			sampler2D _InputCharTex;

            uint4 frag (v2f_customrendertexture i) : SV_Target
            {
				uint idxx = i.globalTexcoord.x * 256.0f;
				uint idxy = i.globalTexcoord.y * 256.0f;
				uint idx = idxy * 256 + idxx;
				uint4 col = _SelfTexture2D[uint2(idxx, idxy)];
				uint cacheSize = read_emulator_word(CACHE_SIZE_ADDR, b);
				if (idx==KEYCODE_RAM_PTR) {
					col.r = tex2Dlod(_InputCharTex, float4(0.0f, 0.0f, 0, 0.0f)).g*255.0f;
				} else {
					for (int ci = cacheSize; ci >= 0; ci--) {
						uint val = _SelfTexture2D[uint2(ci+0x21, 0xFF)].b;
						if (idx == (val & 0xffff)) {
							col.r = val>>16;
							break;
						}
					}
					col.b = (idx>=CACHE_SIZE_ADDR)?0:col.b;
				}
				return col;
			}
			ENDCG
		}
    }
}
