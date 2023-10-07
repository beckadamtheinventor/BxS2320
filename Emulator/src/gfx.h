#ifndef __TTY_GFX_H__
#define __TTY_GFX_H__

#include "emu.h"

#define FONT_WIDTH 8
#define FONT_HEIGHT 8
#define TTY_WIDTH_PX 128
#define TTY_HEIGHT_PX 128
#define TTY_WIDTH_CHR ((int)TTY_WIDTH_PX/FONT_WIDTH)
#define TTY_WIDTH ((int)TTY_WIDTH_PX/FONT_WIDTH)
#define TTY_HEIGHT ((int)TTY_HEIGHT_PX/FONT_HEIGHT)
#define byteclamp(v) ((v)<0?0:((v)>255?255:0))

#define DFLAG_GFX_ENABLED  (1 << 15)
#define DFLAG_TTY_INVERT   (1 << 14)

void initGfx(void);
void drawGfx(Emu *emu, Image image);
void endGfx(void);

#endif