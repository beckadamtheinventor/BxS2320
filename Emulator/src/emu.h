#ifndef __EMU_H__
#define __EMU_H__

#include <stdint.h>
#include <stdbool.h>

#include "font.h"

#define CACHE_SIZE_ADDR 0xff00
#define CACHE_ADDR 0xff01
#define _CACHE_SIZE 0xffffffff
#define R0_ADDR 0xff00
#define NUM_REGS 32
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

#define emu_read(address, res) { res = emuRead(emu, address); }
#define emu_read_long(address, res) { res = (emuRead(emu, address)) | (emuRead(emu, (address)+1) << 16); }
#define overflowAdd(a, b) (((a)&0x80000000)&&((b)&0x80000000))
#define overflowAdds(a, b) ((((a)&0x80000000)^((b)&0x80000000))?0:((((a)&0x40000000)&&((b)&0x40000000))^((a+b)&0x80000000)))
#define overflowSub(a, b) ((a)<(b))
#define overflowSubs(a, b) ((signed)(a)<(signed)(b))
// #define ddoffset(v) ((((v)&0x80)?(v)-0x100:(v)) & 0xff)
#define ddoffset(v) ((int8_t)(v))
#define ddoffset16(v) ((int16_t)(v))
#define emu_write(address, value) emuWrite(emu, address, value)
#define emu_write_long(address, value) { emuWrite(emu, address, value); emuWrite(emu, (address)+1, (value)>>16); }
#define TRUE 1
#define FALSE 0
#define intasfloat(value) (float)(*(uint32_t*)&(value));
#define floatasint(value) (int32_t)(*(float*)&(value));

#define CACHE_SIZE 64
#define MAX_WRITE_CACHE 1024
typedef struct _Emu {
	unsigned int ipf, wpf, memWrites, breakpoint;
	bool breakpointenabled;
	uint16_t *rom, *ram, *gram, *fram, *stack;
	uint32_t regs[NUM_REGS + GRAM_SIZE/2 + STACK_SIZE/2 + FRAM_SIZE/2 + CACHE_SIZE + 2];
	uint32_t writelogindex;
	uint32_t writelogaddrs[MAX_WRITE_CACHE];
	uint16_t writelogvalues[MAX_WRITE_CACHE];
} Emu;

Emu *emuInit(const char *romfile);
void emuDeinit(Emu *emu);
void emuReset(Emu *emu);
void emuSetBreakpoint(Emu *emu, unsigned int addr);
void emuUnsetBreakpoint(Emu *emu);
unsigned int emuRun(Emu *emu, unsigned int cycles);
void emuInputChar(Emu *emu, int c);
void emuSetWriteLimit(Emu *emu, unsigned int limit);
uint16_t emuRead(Emu *emu, uint32_t addr);
void emuWrite(Emu *emu, uint32_t addr, uint16_t val);
void emuTick(Emu *emu);
#endif