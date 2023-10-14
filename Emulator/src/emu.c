
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include "emu.h"

Emu *emuInit(const char *romfile) {
	Emu *emu;
	FILE *fd;
	size_t len;
	if (!(fd = fopen(romfile, "rb")))
		return NULL;
	if (!(emu = malloc(sizeof(Emu))))
		return NULL;
	if (!(emu->rom = malloc(ROM_SIZE*sizeof(uint16_t))))
		return NULL;
	if (!(emu->ram = malloc(RAM_SIZE*sizeof(uint16_t))))
		return NULL;
	if (!(emu->fram = malloc(FRAM_SIZE*sizeof(uint16_t))))
		return NULL;
	if (!(emu->gram = malloc(GRAM_SIZE*sizeof(uint16_t))))
		return NULL;
	if (!(emu->stack = malloc(STACK_SIZE*sizeof(uint16_t))))
		return NULL;
	fseek(fd, 0, 2);
	len = ftell(fd);
	fseek(fd, 0, 0);
	if (len >= ROM_SIZE) {
		fread(emu->rom, sizeof(uint16_t), ROM_SIZE, fd);
	} else {
		memset(&emu->rom[len], 0, (ROM_SIZE - len)*sizeof(uint16_t));
		fread(emu->rom, len, 1, fd);
	}
	fclose(fd);
	emuReset(emu);
	emu->breakpoint = emu->wpf = 0;
	emu->breakpointenabled = false;
	memset(&emu->writelogaddrs, 0, MAX_WRITE_CACHE*sizeof(uint32_t));
	memset(&emu->writelogvalues, 0, MAX_WRITE_CACHE*sizeof(uint16_t));
	emu->writelogindex = 0;
	return emu;
}

void emuDeinit(Emu *emu) {
	free(emu->stack);
	free(emu->gram);
	free(emu->fram);
	free(emu->ram);
	free(emu->rom);
	free(emu);
}

void emuReset(Emu *emu) {
	memset(&emu->regs, 0, NUM_REGS*sizeof(uint32_t));
	memset(emu->ram, 0, RAM_SIZE*sizeof(uint16_t));
	memset(emu->fram, 0, FRAM_SIZE*sizeof(uint16_t));
	memset(emu->gram, 0, GRAM_SIZE*sizeof(uint16_t));
	memset(emu->stack, 0, STACK_SIZE*sizeof(uint16_t));
	emuInputChar(emu, 0);
	for (unsigned int i = 0; i < font_data_len; i++) {
		emu->ram[FONT_DATA_RAM_PTR+i] = font_data[i];
	}
}

void emuSetBreakpoint(Emu *emu, unsigned int addr) {
	emu->breakpoint = addr;
	emu->breakpointenabled = true;
}

void emuUnsetBreakpoint(Emu *emu) {
	emu->breakpointenabled = false;
}

unsigned int emuRun(Emu *emu, unsigned int cycles) {
	unsigned int ranCycles = 0;
	emu->memWrites = 0;
	emu->ipf = cycles;
	// for (int i=0; i<32; i++) {
		// printf("r%d = %X\n", i, emu->regs[i]);
	// }
	do {
		if (emu->breakpointenabled && emu->regs[0] == emu->breakpoint)
			return 0;
		if (emu->wpf > 0 && emu->memWrites >= emu->wpf)
			break;
		emuTick(emu);
	} while (++ranCycles < cycles);
	// printf("Ran %d cycles this frame\n", cycles);
	return ranCycles-1;
}

void emuInputChar(Emu *emu, int c) {
	emu->ram[0xfff0] = (uint16_t)c;
}

void emuSetWriteLimit(Emu *emu, unsigned int limit) {
	emu->wpf = limit;
}

uint16_t emuRead(Emu *emu, uint32_t addr) {
	if (addr>=ADDR_ROM_START && addr<=ADDR_ROM_END) {
		return emu->rom[(addr-ADDR_ROM_START) & ADDR_ROM_MASK];
	} else if (addr>=ADDR_RAM_START && addr<=ADDR_RAM_END) {
		return emu->ram[(addr-ADDR_RAM_START) & ADDR_RAM_MASK];
	} else if (addr>=ADDR_GRAM_START && addr<=ADDR_GRAM_END) {
		return emu->gram[(addr-ADDR_GRAM_START) & ADDR_GRAM_MASK];
	} else if (addr>=ADDR_FRAM_START && addr<=ADDR_FRAM_END) {
		return emu->fram[(addr-ADDR_FRAM_START) & ADDR_FRAM_MASK];
	} else if (addr>=ADDR_STACK_START && addr<=ADDR_STACK_END) {
		return emu->stack[(addr-ADDR_STACK_START) & ADDR_STACK_MASK];
	}
	return 0;
}

void emuWrite(Emu *emu, uint32_t addr, uint16_t val) {
	emu->writelogaddrs[emu->writelogindex%MAX_WRITE_CACHE] = addr;
	emu->writelogvalues[emu->writelogindex%MAX_WRITE_CACHE] = val;
	emu->writelogindex++;
	// printf("Writing 0x%X to 0x%X\n", val, addr);
	if (addr>=ADDR_ROM_START && addr<=ADDR_ROM_END) {
		printf("Write to flash 0x%X value 0x%X preceeding PC 0x%X\n", addr, val, emu->regs[0]);
		emu->regs[5] = emu->regs[0];
		// emu->regs[0] = 0;
	} else if (addr>=ADDR_RAM_START && addr<=ADDR_RAM_END) {
		emu->memWrites++;
		emu->ram[(addr-ADDR_RAM_START) & ADDR_RAM_MASK] = val;
	} else if (addr>=ADDR_GRAM_START && addr<=ADDR_GRAM_END) {
		emu->gram[(addr-ADDR_GRAM_START) & ADDR_GRAM_MASK] = val;
	} else if (addr>=ADDR_FRAM_START && addr<=ADDR_FRAM_END) {
		emu->fram[(addr-ADDR_FRAM_START) & ADDR_FRAM_MASK] = val;
	} else if (addr>=ADDR_STACK_START && addr<=ADDR_STACK_END) {
		emu->stack[(addr-ADDR_STACK_START) & ADDR_STACK_MASK] = val;
	} else {
		printf("Out of bounds write to 0x%X value 0x%X preceeding PC 0x%X\n", addr, val, emu->regs[0]);
		emu->regs[5] = emu->regs[0];
		// emu->regs[0] = 0;
	}
}

void emuTick(Emu *emu) {
	#define regs emu->regs
	#define gram emu->gram
	#define T_WORD 1
	#define T_LONG 3
	#define T_BYTE 4
	#define stshift8 (8*(stno-T_BYTE))
	#define stshift16 (16*(stno-T_WORD))
	#define stshift8b (8*(stno2-T_BYTE))
	#define stshift16b (16*(stno2-T_WORD))
	#define stshift8c (8*(stno3-T_BYTE))
	#define stshift16c (16*(stno3-T_WORD))
	#define rno2 (val&31)
	#define rno3 ((val>>8)&31)
	uint32_t val2, val3, val = 0, sval, sval2, sval3;
	uint16_t opcode;
	uint8_t arg, jump, stno, stno2, stno3, rno;
	regs[4] = emu->ipf;
	regs[3]++;
	emu_read(regs[0], opcode);
	arg = (opcode >> 8) & 0xff;
	regs[0]++;
	emu_read(regs[0], val);
	// if ((opcode & 0xff) >= 0xF4) {
		// return;
	// }
	// printf("PC=%8X : %2X %2X\n", regs[0]-1, opcode, val);
	opcode &= 0xff;
	
	jump = ((regs[1] >> ((opcode & 0x6) >> 1)) ^ (opcode & 1)) & 1;
	rno = arg & 31;
	if (arg < 32 || arg >= 224) { // rX || rXf
		sval = regs[rno];
		stno = T_LONG;
	} else if (arg < 64) { // rXl
		sval = regs[rno] & 0xffff;
		stno = T_WORD;
	} else if (arg < 96) { // rXh
		sval = regs[rno] >> 16;
		stno = T_WORD + 1;
	} else if (arg < 128) { // rXa
		sval = (regs[rno] >> 0) & 0xff;
		stno = T_BYTE + 0;
	} else if (arg < 160) { // rXb
		sval = (regs[rno] >> 8) & 0xff;
		stno = T_BYTE + 1;
	} else if (arg < 192) { // rXc
		sval = (regs[rno] >> 16) & 0xff;
		stno = T_BYTE + 2;
	} else if (arg < 224) { // rXd
		sval = (regs[rno] >> 24) & 0xff;
		stno = T_BYTE + 3;
	}
	#define arg (val&0xff)
	if (arg < 32 || arg >= 224) { // rX || rXf
		sval2 = regs[rno2];
		stno2 = T_LONG;
	} else if (arg < 64) { // rXl
		sval2 = regs[rno2] & 0xffff;
		stno2 = T_WORD;
	} else if (arg < 96) { // rXh
		sval2 = regs[rno2] >> 16;
		stno2 = T_WORD + 1;
	} else if (arg < 128) { // rXa
		sval2 = (regs[rno2] >> 0) & 0xff;
		stno2 = T_BYTE + 0;
	} else if (arg < 160) { // rXb
		sval2 = (regs[rno2] >> 8) & 0xff;
		stno2 = T_BYTE + 1;
	} else if (arg < 192) { // rXc
		sval2 = (regs[rno2] >> 16) & 0xff;
		stno2 = T_BYTE + 2;
	} else if (arg < 224) { // rXd
		sval2 = (regs[rno2] >> 24) & 0xff;
		stno2 = T_BYTE + 3;
	}
	#undef arg
	#define arg (val>>8)
	if (arg < 32 || arg >= 224) { // rX || rXf
		sval3 = regs[rno3];
		stno3 = T_LONG;
	} else if (arg < 64) { // rXl
		sval3 = regs[rno3] & 0xffff;
		stno3 = T_WORD;
	} else if (arg < 96) { // rXh
		sval3 = regs[rno3] >> 16;
		stno3 = T_WORD + 1;
	} else if (arg < 128) { // rXa
		sval3 = (regs[rno3] >> 0) & 0xff;
		stno3 = T_BYTE + 0;
	} else if (arg < 160) { // rXb
		sval3 = (regs[rno3] >> 8) & 0xff;
		stno3 = T_BYTE + 1;
	} else if (arg < 192) { // rXc
		sval3 = (regs[rno3] >> 16) & 0xff;
		stno3 = T_BYTE + 2;
	} else if (arg < 224) { // rXd
		sval3 = (regs[rno3] >> 24) & 0xff;
		stno3 = T_BYTE + 3;
	}
	#undef arg
	if (opcode >= 0xC8 && opcode < 0xF8) { // ret, call and jump opcodes
		opcode &= 0xF8;
	}
	if (opcode >= 0x3E && opcode < 0x70) { // arithmetic opcodes
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
	} else { // non-arithmetic opcodes
		sval2 += ddoffset(val >> 8);
	}
	
	// printf("opcode=0x%X arg=0x%X\nsval=0x%X sval2=0x%X sval3=0x%X\n", opcode, arg, sval, sval2, sval3);
	
	switch (opcode) {
		case 0x00: // nop
			break;
		case 0x01: // ld
			regs[0]++;
			if (stno == T_LONG) {
				regs[rno] = sval2;
			} else if (stno < T_BYTE) {
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | (sval2 << stshift16);
			} else {
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | (sval2 << stshift8);
			}
			break;
		case 0x02: // ldz
			if (stno == T_LONG) {
				regs[rno] = 0;
			} else if (stno < T_BYTE) {
				regs[rno] = (regs[rno] & ~(0xffff << stshift16));
			} else {
				regs[rno] = (regs[rno] & ~(0xff << stshift8));
			}
			break;
		case 0x03: // ldi
			regs[0]++;
			if (stno == T_LONG) {
				emu_read(regs[0], val2);
				regs[0]++;
				regs[rno] = val | (val2 << 16);
			} else if (stno < T_BYTE) {
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | (val << stshift16);
			} else {
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | ((val & 0xff) << stshift8);
			}
			break;
		case 0x04: // ex
			regs[0]++;
			if (stno == T_LONG) {
				regs[rno] = sval2;
				regs[rno2] = sval;
			} else if (stno < T_BYTE) {
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | ((sval2 & 0xffff) << stshift16);
				regs[rno2] = (regs[rno2] & ~(0xffff << stshift16b)) | ((sval & 0xffff) << stshift16b);
			} else {
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | ((sval2 & 0xff) << stshift8);
				regs[rno2] = (regs[rno2] & ~(0xff << stshift8b)) | ((sval & 0xff) << stshift8b);
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
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | (val2 << stshift16);
			} else {
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | ((val2 & 0xff) << stshift8);
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
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | (val3 << stshift16);
			} else {
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | ((val3 & 0xff) << stshift8);
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
			// printf("Writing long 0x%X to 0x%X\n", sval, val2);
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
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | ((sval & 0xffff) << stshift16);
			} else {
				sval &= 0xff;
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | (sval << stshift8);
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
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | ((sval & 0xffff) << stshift16);
			} else {
				sval &= 0xff;
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | (sval << stshift8);
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
			// printf("strr 0x%X -> 0x%X + 0x%X\n", sval, sval2, sval3);
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
			// printf("Comparing 0x%X < 0x%X\n", sval, sval2);
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
			sval = (signed)sval + (signed)sval2;
			break;
		case 0x62: // adcs
			regs[1] |= (overflowAdds(sval, sval2 + (regs[1] & F_CARRY)))?F_CARRYSAVE:0;
			sval = (signed)sval + (signed)sval2 + (regs[1] & F_CARRY);
			break;
		case 0x64: // subs
			regs[1] |= (overflowSubs(sval, sval2))?F_CARRYSAVE:0;
			sval = (signed)sval - (signed)sval2;
			break;
		case 0x66: // sbcs
			regs[1] |= (overflowSubs(sval, sval2 + (regs[1] & F_CARRY)))?F_CARRYSAVE:0;
			sval = (signed)sval - (signed)sval2 + (regs[1] & F_CARRY);
			break;
		case 0x68: // muls
			sval = (signed)sval * (signed)sval2;
			break;
		case 0x6A: // divs
			if (sval2 == 0) {
				regs[1] |= F_CARRYSAVE;
				sval = 0xffffffff;
			} else {
				sval = (signed)sval / (signed)sval2;
			}
			break;
		case 0x6C: // mods
			if (sval2 == 0) {
				regs[1] |= F_CARRYSAVE;
				sval = 0xffffffff;
			} else {
				sval = (signed)sval % (signed)sval2;;
			}
			break;
		case 0x6E: // cmps
			regs[1] |= (((signed)sval < (signed)sval2)?F_CARRYSAVE:0);
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
				regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | (val << stshift16);
			} else {
				emu_read(regs[2], val);
				regs[rno] = (regs[rno] & ~(0xff << stshift8)) | ((val & 0xff) << stshift8);
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
					regs[rno] = (regs[rno] & ~(0xffff << stshift16)) | (sval << stshift16);
				} else {
					regs[rno] = (regs[rno] & ~(0xff << stshift8)) | (sval << stshift8);
				}
			}
			break;
		case 0xFF: // testhalt rX, value
			if (sval != sval2) {
				regs[1] |= F_HALT;
			}
			break;
		default:
			regs[5] = opcode;
			regs[1] |= F_HALT;
			break;
	}
	if (opcode >= 0x3E && opcode < 0x70) { // lor, land, arithmetic opcodes
		regs[1] = (regs[1] & ~(F_CARRY|F_CARRYSAVE|F_ZERO)) | ((regs[1] & F_CARRYSAVE)?F_CARRY:0) | (sval==0?F_ZERO:0);
		if (opcode != 0x4E && opcode != 0x6E) { // don't store registers for cmp opcodes
			if (stno3 == T_LONG) {
				regs[rno3] = sval;
			} else if (stno3 < T_BYTE) {
				regs[rno3] = (regs[rno3] & ~(0xffff << stshift16c)) | (sval << stshift16c);
			} else {
				regs[rno3] = (regs[rno3] & ~(0xff << stshift8c)) | (sval << stshift8c);
			}
		}
	}
	#undef regs
	#undef gram
	#undef T_BYTE
	#undef T_WORD
	#undef T_LONG
	#undef T_FLOAT
}
