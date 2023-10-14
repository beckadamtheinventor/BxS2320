
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <raylib.h>
#include <sys/stat.h>
#include "gfx.h"
#include "emu.h"
// #include "opcodes.h"

#define DEBUG_IMAGE_WIDTH 768
#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))

void drawChar(uint32_t *ptr, unsigned int x, unsigned int y, unsigned int w, char c) {
	for (uint8_t cy=0; cy<8; cy++) {
		unsigned int p = (y*8+cy)*w + x*8;
		uint8_t chr = font_data[c * 8 + cy];
		for (uint8_t cx=0; cx<8; cx++) {
			if (chr & 0x80) {
				ptr[p++] = 0xffffffff;
			} else {
				ptr[p++] = 0xff000000;
			}
			chr <<= 1;
		}
	}
}

void drawHex8(uint32_t *ptr, unsigned int x, unsigned int y, unsigned int w, uint8_t val) {
	const char hex[] = "0123456789ABCDEF";
	drawChar(ptr, x+0, y+0, w, hex[(val/16)&15]);
	drawChar(ptr, x+1, y+0, w, hex[val&15]);
}

void drawHex16(uint32_t *ptr, unsigned int x, unsigned int y, unsigned int w, uint16_t val) {
	drawHex8(ptr, x+0, y+0, w, val >> 8);
	drawHex8(ptr, x+2, y+0, w, val);
}

void drawHex32(uint32_t *ptr, unsigned int x, unsigned int y, unsigned int w, uint32_t val) {
	drawHex8(ptr, x+0, y+0, w, val >> 24);
	drawHex8(ptr, x+2, y+0, w, val >> 16);
	drawHex8(ptr, x+4, y+0, w, val >> 8);
	drawHex8(ptr, x+6, y+0, w, val);
}

void drawStr(uint32_t *ptr, unsigned int x, unsigned int y, unsigned int w, const char *str) {
	for (unsigned int i=0; str[i]; i++) {
		drawChar(ptr, x+i, y, w, str[i]);
	}
}

void drawDebugImage(Emu *emu, Image img) {
	#define DEBUG_W DEBUG_IMAGE_WIDTH
	uint32_t *data = img.data;
	// bool on_second_opcode_half = false;
	for (unsigned int i=0; i<32; i++) {
		unsigned int x = (i / 16) * 13;
		unsigned int y = i & 15;
		drawChar(data, x+0, y+0, DEBUG_W, 'r');
		drawHex8(data, x+1, y+0, DEBUG_W, i);
		drawChar(data, x+3, y+0, DEBUG_W, '=');
		drawHex32(data, x+4, y+0, DEBUG_W, emu->regs[i]);
		drawChar(data, x+12, y+0, DEBUG_W, ' ');
	}
	for (int i=-8; i<16; i++) {
		uint32_t pc = emu->regs[0] + i;
		uint16_t val = emuRead(emu, pc);
		unsigned int y = i+40;
		drawHex32(data, 0, y, DEBUG_W, pc);
		if (i == 0) {
			drawChar(data, 9, y, DEBUG_W, '-');
			drawChar(data,10, y, DEBUG_W, '>');
		} else {
			drawChar(data, 9, y, DEBUG_W, ' ');
			drawChar(data,10, y, DEBUG_W, ' ');
		}
		drawHex8(data, 12, y, DEBUG_W, val);
		drawHex8(data, 14, y, DEBUG_W, val>>8);
		
		// if (on_second_opcode_half) {
			// on_second_opcode_half = false;
		// } else {
			// debug_opcode_t opc = debug_opcodes[val & 0xff];
			// drawStr(data, 16, y, DEBUG_W, "        ");
			// drawStr(data, 14, y, DEBUG_W, opc.str);
			// if (opc.length == 4) {
				// on_second_opcode_half = true;
			// }
		// }
	}
	for (int y=0; y<TTY_HEIGHT; y++) {
		for (int x=0; x<TTY_WIDTH; x++) {
			uint32_t v = emu->gram[y*TTY_WIDTH + x];
			unsigned int p = (y*2+256)*DEBUG_W + x*2+16*8;
			data[p+DEBUG_W+1] = data[p+DEBUG_W] = data[p+1] = data[p] = 0xFF000000 | (((v >> 16) & 0xff) * 0x010101);
			p += TTY_WIDTH*2;
			data[p+DEBUG_W+1] = data[p+DEBUG_W] = data[p+1] = data[p] = 0xFF070707 | (((v >> 10) & 31) << 3) | (((v >> 5) & 31) << 11) | ((v & 31) << 19);
		}
	}
	#define s "Keycode: "
	drawStr(data, 32, 33, DEBUG_W, s);
	drawHex8(data, 50, 33, DEBUG_W, emu->ram[0xfff0]);
	#undef s
	#undef DEBUG_W
}

void dump(Emu *emu) {
	FILE *fd;
	struct stat sb;

#ifdef PLATFORM_WINDOWS
	if (stat("dump", &sb))
		mkdir("dump");
#else
	if (stat("dump", &sb))
		mkdir("dump", 0x777);
#endif
	
	if ((fd = fopen("dump/regdump.bin", "wb"))) {
		fwrite(&emu->regs, NUM_REGS, sizeof(uint32_t), fd);
		fclose(fd);
	}
	if ((fd = fopen("dump/gramdump.bin", "wb"))) {
		fwrite(emu->gram, GRAM_SIZE, sizeof(uint16_t), fd);
		fclose(fd);
	}
	if ((fd = fopen("dump/ramdump.bin", "wb"))) {
		fwrite(emu->ram, RAM_SIZE, sizeof(uint16_t), fd);
		fclose(fd);
	}
	if ((fd = fopen("dump/framdump.bin", "wb"))) {
		fwrite(emu->fram, FRAM_SIZE, sizeof(uint16_t), fd);
		fclose(fd);
	}
	if ((fd = fopen("dump/stackdump.bin", "wb"))) {
		fwrite(emu->stack, STACK_SIZE, sizeof(uint16_t), fd);
		fclose(fd);
	}
	if ((fd = fopen("dump/memwritesdump.bin", "wb"))) {
		fwrite(&emu->writelogindex, sizeof(uint32_t), 1, fd);
		fwrite(&emu->writelogaddrs, sizeof(uint32_t), MAX_WRITE_CACHE, fd);
		fwrite(&emu->writelogvalues, sizeof(uint16_t), MAX_WRITE_CACHE, fd);
		fclose(fd);
	}
}


int main(int argc, char **argv) {
	FILE *fd;
	char *filename;
	unsigned int breakpoint = 0xffffffff;
	unsigned int cyclesPerFrame = 10000, previousCyclesPerFrame = 1000, writesPerFrame = 0;
	bool cycleTestEnabled = true, debug_enabled = false;
	int window_width, window_height, draw_offset_x, draw_offset_y, keycode = 0;
	float draw_scale;
	Image screenImage, debugImage;
	Texture2D screenTexture, debugTexture;
	Emu *emu;
	
	if (argc < 2) {
		filename = "main.rom";
		printf("Usage: %s rom.bin\n", argv[0]);
	} else {
		filename = argv[1];
	}
	for (int i=1; i<argc; i++) {
		if (!strcmp(argv[i], "--ipf")) {
			if (i < argc) {
				cyclesPerFrame = atoi(argv[i+1]);
				printf("Setting IPF=%s\n", argv[i+1]);
				cycleTestEnabled = false;
			}
		} else if (!strcmp(argv[i], "--breakpoint")) {
			if (i < argc) {
				if (argv[i+1][0] == '$') {
					breakpoint = 0;
					for (unsigned int j=1; argv[i+1][j]; j++) {
						char c = argv[i+1][j];
						breakpoint *= 16;
						if (c >= 'A' && c <= 'F') {
							breakpoint += c + 10 - 'A';
						} else if (c >= 'a' && c <= 'f') {
							breakpoint += c + 10 - 'a';
						} else if (c >= '0' && c <= '9') {
							breakpoint += c - '0';
						} else {
							break;
						}
					}
				} else {
					breakpoint = atoi(argv[i+1]);
				}
				printf("Setting breakpoint at 0x%X\n", breakpoint);
			}
		} else if (!strcmp(argv[i], "--wpf")) {
			if (i < argc) {
				writesPerFrame = atoi(argv[i+1]);
				printf("Setting WPF=%s\n", argv[i+1]);
			}
		} else if (!strcmp(argv[i], "--debug")) {
			debug_enabled = true;
			cyclesPerFrame = 0;
			cycleTestEnabled = false;
		}
	}

	screenImage = GenImageColor(TTY_WIDTH_PX, TTY_HEIGHT_PX, BLACK);
	debugImage = GenImageColor(DEBUG_IMAGE_WIDTH, DEBUG_IMAGE_WIDTH, BLACK);
	ImageFormat(&screenImage, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
	ImageFormat(&debugImage, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
	
	SetTraceLogLevel(LOG_WARNING);
	initGfx();
	
	MaximizeWindow();
	window_width = GetScreenWidth();
	window_height = GetScreenHeight();
	draw_scale = min(window_width/TTY_WIDTH_PX, window_height/TTY_HEIGHT_PX);

	reloadRom:;
	if (!(emu = emuInit(filename))) {
		printf("Rom file \"%s\" not found\n", filename);
		return -1;
	}
	
	if (writesPerFrame > 0) {
		emuSetWriteLimit(emu, writesPerFrame);
	}
	
	if (breakpoint != 0xffffffff) {
		emuSetBreakpoint(emu, breakpoint);
	}
	// printf("Finished init\n");
	while (!WindowShouldClose()) {
		if (!debug_enabled) {
			if (emuRun(emu, cyclesPerFrame) == 0) {
				emuUnsetBreakpoint(emu);
				debug_enabled = true;
				goto resizedWindow;
			}
		}
		// for (int i=0; i<32; i++) {
			// printf("r%d = %X\n", i, emu->regs[i]);
		// }
		if (IsWindowResized()) {
			resizedWindow:;
			window_width = GetScreenWidth();
			window_height = GetScreenHeight();
			draw_scale = min(window_width/TTY_WIDTH_PX, window_height/TTY_HEIGHT_PX);
			if (debug_enabled) {
				draw_scale /= 2.0f;
				draw_offset_x = 0;
			} else {
				draw_offset_x = window_width/2 - TTY_WIDTH_PX*draw_scale/2;
			}
			draw_offset_y = window_height/2 - TTY_HEIGHT_PX*draw_scale/2;
		}
		drawGfx(emu, screenImage);
		if (debug_enabled) {
			drawDebugImage(emu, debugImage);
			debugTexture = LoadTextureFromImage(debugImage);
		}
		screenTexture = LoadTextureFromImage(screenImage);
		BeginDrawing();
		ClearBackground(BLACK);
		DrawTextureEx(screenTexture, (Vector2){draw_offset_x, draw_offset_y}, 0, draw_scale, WHITE);
		if (debug_enabled) {
			DrawTextureEx(debugTexture, (Vector2){draw_offset_x+draw_scale*TTY_WIDTH_PX, 0}, 0, 2.0f, WHITE);
		}
		EndDrawing();
		UnloadTexture(debugTexture);
		UnloadTexture(screenTexture);
		if (IsKeyPressed(KEY_F10)) {
			emuDeinit(emu);
			goto reloadRom;
		}
		if (IsKeyPressed(KEY_F3)) {
			debug_enabled = !debug_enabled;
			goto resizedWindow;
		}
		if (debug_enabled && IsKeyPressed(KEY_F5)) {
			emuRun(emu, 1);
		}
		if (debug_enabled && IsKeyPressed(KEY_F6)) {
			int ticks = 256*1024;
			uint32_t exitpcval = emuRead(emu, emu->regs[2]) | (emuRead(emu, emu->regs[2]+1) << 16);
			while (emu->regs[0] != exitpcval) { // loop until returned from subroutine
				emuRun(emu, 1);
				if (ticks-- <= 0) {
					break;
				}
			}
		}
		if (debug_enabled && IsKeyPressed(KEY_F7)) {
			int ticks = 256*1024;
			uint32_t exitpcval = emu->regs[0] + 1;
			while (emu->regs[0] < exitpcval) {
				emuRun(emu, 1);
				if (ticks-- <= 0) {
					break;
				}
			}
		}
		if (IsKeyPressed(KEY_F8)) {
			dump(emu);
		}
		if (IsMouseButtonDown(MOUSE_LEFT_BUTTON)) {
			emuUnsetBreakpoint(emu);
		}
		if (IsKeyPressed(KEY_F4)) {
			emuReset(emu);
		} else {
			if (IsKeyDown(KEY_DOWN)) {
				emuInputChar(emu, 1);
			} else if (IsKeyDown(KEY_LEFT)) {
				emuInputChar(emu, 2);
			} else if (IsKeyDown(KEY_RIGHT)) {
				emuInputChar(emu, 3);
			} else if (IsKeyDown(KEY_UP)) {
				emuInputChar(emu, 4);
			} else if (IsKeyDown(KEY_A) || IsKeyDown(KEY_ENTER)) {
				emuInputChar(emu, 8);
			} else if (IsKeyDown(KEY_B) || IsKeyDown(KEY_BACKSPACE)) {
				emuInputChar(emu, 9);
			} else if (IsKeyDown(KEY_X) || IsKeyDown(KEY_DELETE)) {
				emuInputChar(emu, 10);
			} else if (IsKeyDown(KEY_Y) || IsKeyDown(KEY_ESCAPE)) {
				emuInputChar(emu, 11);
			} else {
				emuInputChar(emu, 0);
			}
		}
		if (cycleTestEnabled && !debug_enabled) {
			if (GetFPS() < 50) {
				cyclesPerFrame = previousCyclesPerFrame / 2.0f;
				cycleTestEnabled = false;
				printf("Settling on %d cycles per frame.\n", cyclesPerFrame);
			} else {
				cyclesPerFrame *= 1.1f;
			}
			previousCyclesPerFrame = cyclesPerFrame;
		}
	}
	// dump(emu);
	emuDeinit(emu);
	endGfx();
	return 0;
}
