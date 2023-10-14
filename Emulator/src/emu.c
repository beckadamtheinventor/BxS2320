
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
// the order here matters to the selection routines
	#define T_WORD 1
	#define T_LONG 3
	#define T_BYTE 4
// return a with 32, 16, or 8 bits updated with b, determined by load type s
#define UPDATE_NUMBER_SECTION(s,a,b) (((s)>=T_BYTE)?(((a) & ~(0xff << (8*((s)-T_BYTE)))) | (((b)&0xff) << (8*((s)-T_BYTE)))):\
									  (((s)<=T_WORD+1)?(((a) & ~(0xffff << (16*((s)-T_WORD)))) | (((b)&0xffff) << (16*((s)-T_WORD)))):(b)))
#define SELECT_STNO(s) (((s)<32||(s)>=224)?T_LONG:((s)<96?(T_WORD+((s)/32)-1):(T_BYTE+((s)/32)-3)))
#define SELECT_SVAL(s,a) ((s)>=T_BYTE?(((a) >> (8*((s)-T_BYTE)))&0xff):((s)==T_LONG?(a):(((a) >> (16*((s)-T_WORD)))&0xffff)))
#define GET_WADDR(a) (a)
	#define stshift8 (8*(stno-T_BYTE))
	#define stshift16 (16*(stno-T_WORD))
	#define stshift8b (8*(stno2-T_BYTE))
	#define stshift16b (16*(stno2-T_WORD))
	#define stshift8c (8*(stno3-T_BYTE))
	#define stshift16c (16*(stno3-T_WORD))
	#define rno2 (val&31)
	#define rno3 ((val>>8)&31)
	#define regs emu->regs
	uint32_t val, val2, val3, sval, sval2, sval3;
	uint16_t opcode;
	uint8_t stno, stno2, stno3, rno, wsize, arg, jump;
	uint32_t waddr, wval;

	if (regs[1] & F_HALT) {
		return;
	}

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
	rno = arg & 31;
	// printf("opcode=0x%X arg=0x%X\nsval=0x%X sval2=0x%X sval3=0x%X\n", opcode, arg, sval, sval2, sval3);
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
	regs[0] += ((opcode>=0x3E && opcode<0x56) || (opcode>0x00 && opcode<=0x08) ||\
				opcode==0xD0 || opcode==0xE0 || opcode==0xFF || (opcode>=0xC2 && opcode<=0xC6 && opcode!=0xC4))?1:0;
// load 3rd opcode word
	emu_read(regs[0], val3);
	sval2 = ((opcode>=0x40 && opcode<0x56) && (opcode & 1))?\
		((stno==T_LONG)?(val | (val3 << 16)):val):sval2;
	sval2 = (opcode==0x03 || opcode==0xFF)?((stno==T_LONG)?(val | (val3 << 16)):val):sval2;
	sval2 = (opcode==0x02 || opcode==0x06 || opcode==0xC6 || opcode==0xD0 || opcode==0xE0)?(val | (val3 << 16)):sval2;
// opcodes with 3rd opcode word
	regs[0] += ((stno==T_LONG && (opcode==0x03 || opcode==0xFF ||\
				((opcode & 1) && (opcode>=0x40 && opcode<0x56)))) ||\
				opcode==0xD0 || opcode==0xE0 || opcode==0x02 || opcode==0x06)?1:0;

	stno3 = (opcode>=0x3E && opcode<0x56 && (opcode&1))?stno:stno3;
	val = (opcode>=0x40 && opcode<0x56 && (opcode&1))?(rno<<8):val;
	opcode = (opcode>=0x40 && opcode<0x56)?(opcode&0xFE):opcode;
	sval2 += (opcode!=0x02 && opcode!=0x03 && opcode!=0x06 && opcode<0x3E)?ddoffset(val>>8):0;

	waddr = wval = wsize = 0;
	switch (opcode) {
		case 0x00: // nop
			break;
		case 0x01: // ld
			regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], sval2);
			break;
		case 0x02: // sto rX, imm32
			waddr = GET_WADDR(sval2);
			wval = (stno>=T_BYTE)?(sval&0xff):sval;
			wsize = (stno==T_LONG)?2:1;
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
			waddr = GET_WADDR(sval2);
			wval = (stno>=T_BYTE)?(sval&0xff):sval;
			wsize = (stno==T_LONG)?2:1;
			break;
		case 0x08: // sti imm8, rX, offset
			waddr = GET_WADDR(sval2);
			wval = arg;
			wsize = 1;
			break;
		case 0x09: // ldz
			regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], 0);
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
			waddr = GET_WADDR(sval2+sval3);
			wval = sval;
			wsize = 1;
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
			sval = (sval2==0?0xffffffff:(sval/sval2));
			break;
		case 0x4C: // mod
			regs[1] |= (sval2==0)?F_CARRYSAVE:0;
			sval = (sval2==0?0xffffffff:(sval%sval2));
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
		case 0xC0: // push rX
			regs[2] -= (stno == T_LONG)?2:1;
			waddr = GET_WADDR(regs[2]);
			wval = sval;
			wsize = (stno == T_LONG)?2:1;
			break;
		case 0xC1: // pop rX
			emu_read(regs[2], val);
			emu_read(regs[2]+1, val2);
			regs[rno] = UPDATE_NUMBER_SECTION(stno, regs[rno], val | (val2 << 16));
			regs[2] += (stno == T_LONG)?2:1;
			break;
		case 0xC2: // pea rX, rY, offset
			regs[2] -= 2;
			waddr = GET_WADDR(regs[2]);
			wval = sval+sval2;
			wsize = 2;
			break;
		case 0xC3: // pea rX, offset16
			regs[2] -= 2;
			waddr = GET_WADDR(regs[2]);
			wval = sval+ddoffset16(val);
			wsize = 2;
			break;
		case 0xC4: // pushb
			regs[2]--;
			waddr = GET_WADDR(regs[2]);
			wval = arg;
			wsize = 1;
			break;
		case 0xC5: // pushw
			regs[2]--;
			waddr = GET_WADDR(regs[2]);
			wval = val;
			wsize = 1;
			break;
		case 0xC6: // pushl
			regs[2] -= 2;
			waddr = GET_WADDR(regs[2]);
			wval = sval2;
			wsize = 2;
			break;
		case 0xC8: // ret
			emu_read(regs[2], val);
			emu_read(regs[2]+1, val2);
			regs[2] += jump?2:0;
			regs[0] = jump?(val | (val2 << 16)):regs[0];
			break;
		case 0xD0: // call imm32
			regs[2] -= jump?2:0;
			waddr = jump?GET_WADDR(regs[2]):waddr;
			wval = regs[0];
			wsize = 2;
			regs[0] = jump?sval2:regs[0];
			break;
		case 0xD8: // call rX
			regs[2] -= jump?2:0;
			waddr = jump?GET_WADDR(regs[2]):waddr;
			wval = regs[0];
			wsize = 2;
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

	if (wsize > 0)
		emuWrite(emu, waddr, wval);
	if (wsize > 1)
		emuWrite(emu, waddr+1, wval>>16);

	regs[1] = (opcode>=0x3E&&opcode<0x56)?\
		((regs[1] & ~(F_CARRY|F_CARRYSAVE|F_ZERO)) | ((regs[1] & F_CARRYSAVE)?F_CARRY:0) | (sval==0?F_ZERO:0)):regs[1];
	regs[rno3] = (opcode>=0x3E && opcode<0x56 && opcode!=0x4E)?\
		UPDATE_NUMBER_SECTION(stno3, regs[rno3], sval):regs[rno3];

	#undef T_BYTE
	#undef T_WORD
	#undef T_LONG
	#undef T_FLOAT
}
