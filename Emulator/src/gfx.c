
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include <raylib.h>

#include "gfx.h"
#include "emu.h"

void initGfx(void) {
	InitWindow(TTY_WIDTH_PX, TTY_HEIGHT_PX, "BxS2321");
	SetTargetFPS(60);
	SetWindowState(FLAG_WINDOW_RESIZABLE);
	SetWindowMinSize(TTY_WIDTH_PX, TTY_HEIGHT_PX);
	SetExitKey(-1);
}

void endGfx(void) {
	CloseWindow();
}

void drawGfx(Emu *emu, Image image) {
	uint32_t *screen = (uint32_t*)image.data;
	uint16_t dflags = emu->ram[0xffff];
	// uint8_t tpcolor = emu->mem[0xfff8]&0x3;
	assert(image.width == TTY_WIDTH_PX);
	assert(image.height == TTY_HEIGHT_PX);
	assert(image.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
	if (dflags & DFLAG_GFX_ENABLED) {
		bool dinvert = dflags & DFLAG_TTY_INVERT;
		for (int ty=0; ty<TTY_HEIGHT; ty++) {
			for (int tx=0; tx<TTY_WIDTH; tx++) {
				uint8_t ch = emu->gram[ty*TTY_WIDTH_CHR+tx] & 0xff;
				uint16_t tint = emu->gram[0x100+ty*TTY_WIDTH_CHR+tx];
				uint16_t chrp = emu->ram[0xfffe] + ch * 8;
				bool invert = (tint & (1 << 15)) ? !dinvert : dinvert;
				uint8_t r = ((tint >> 10) & 31);
				uint8_t g = ((tint >> 5) & 31);
				uint8_t b = ((tint >> 0) & 31);
				uint32_t rgb = (((b << 16) | (g << 8) | (r)) << 3) | 0x070707;
				for (uint8_t cy=0; cy<FONT_HEIGHT; cy++) {
					uint8_t z = emu->ram[(chrp + cy)&0xffff];
					for (uint8_t cx=0; cx<FONT_WIDTH; cx++) {
						bool on = (z & 0x80) ? !invert : invert;
						z <<= 1;
						screen[(ty*FONT_HEIGHT + cy) * TTY_WIDTH_PX + (tx*FONT_WIDTH + cx)] = 0xff000000 | (on ? rgb : 0);
					}
				}
			}
		}
	} else {
		for (int y=0; y<TTY_HEIGHT_PX; y++) {
			for (int x=0; x<TTY_WIDTH_PX; x++) {
				screen[y*TTY_WIDTH_PX + x] = 0xff000000;
			}
		}
	}
	
}

