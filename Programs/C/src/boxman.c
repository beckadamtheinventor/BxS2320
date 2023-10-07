
char mapw;
char maph;
short numBoxes;
char *level;
short BOXMAN_NUM_LEVELS;

void LoadLevel(short lno) {
	if (lno == 0)
		strcpy(level, "\x55 ##A#b a            B#   ");
	else if (lno == 1)
		strcpy(level, "\x55  #AB b#        a     ## ");
}

void BoxManDrawC(char c) {
	if (c == 'A') {
		printchar('#', 0x7c00);
	} else if (c == 'B') {
		printchar('#', 0x03e0);
	} else if (c == 'C') {
		printchar('#', 0x001f);
	} else if (c == 'D') {
		printchar('#', 0x7fe0);
	} else if (c == 'E') {
		printchar('#', 0x03ff);
	} else if (c == 'a') {
		printchar('O', 0x7c00);
	} else if (c == 'b') {
		printchar('O', 0x03e0);
	} else if (c == 'c') {
		printchar('O', 0x001f);
	} else if (c == 'd') {
		printchar('O', 0x7fe0);
	} else if (c == 'e') {
		printchar('O', 0x03ff);
	} else {
		printchar(c, 0x7fff);
	}
}

void BoxManDrawScreen(void) {
	char *lptr, x, y;
	cleartty();
	maph = *level;
	lptr = level+1;
	mapw = maph & 0xF;
	maph = maph >> 4;
	settextxy(((16 - mapw) >> 1) - 1, ((16 - maph) >> 1) - 1);
	x = 0;
	while (x < mapw + 2) {
		printchar('#', 0x7fff);
		x++;
	}
	settextxy(((16 - mapw) >> 1) - 1, ((16 - maph) >> 1) + maph);
	x = 0;
	while (x < mapw + 2) {
		printchar('#', 0x7fff);
		x++;
	}
	y = 0;
	while (y < maph) {
		settextxy(((16 - mapw) >> 1) - 1, ((16 - maph) >> 1) + y);
		printchar('#', 0x7fff);
		x = 0;
		while (x < mapw) {
			BoxManDrawC(*lptr); lptr++;
			x++;
		}
		printchar('#', 0x7fff);
		y++;
	}
}

uint8_t BoxmanMain(void) {
	char basex, basey, mapchar;
	char c, c2;
	short mapx, mapy, dx, dy, i, levelno = 0;
	char keycode, redraw = 2;

	while (1) {
		if (redraw > 1) {
			if (levelno >= BOXMAN_NUM_LEVELS) {
				print("You Win!", 0x7fff);
				keycode = waitkeycycle();
				if (keycode == sk_y) {
					return 1;
				}
			}
			LoadLevel(levelno);
			mapx = mapy = 0;
			numBoxes = 0;
			i = 0;
			while (c = level[i]) {
				if (c>='A' && c<='E')
					numBoxes++;
				i++;
			}
		}
		if (redraw > 0) {
			BoxManDrawScreen();
			basex = ((16 - mapw) >> 1);
			basey = ((16 - maph) >> 1);
		}
		
		if (numBoxes == 0) {
			settextxy(0, 0);
			print("You win!", 0x7fff);
			waitkeycycle();
			cleartty();
			levelno++;
			redraw = 2;
		} else {
			mapchar = level[mapx + mapy * mapw + 1];
			printcharat('O', basex + mapx, basey + mapy);

			keycode = waitkeycycle();

			dx = dy = 0;
			if (keycode == sk_right) {
				dx = 1;
			} else if (keycode == sk_left) {
				dx = -1;
			} else if (keycode == sk_down) {
				dy = 1;
			} else if (keycode == sk_up) {
				dy = -1;
			} else if (keycode == sk_x) {
				return 0;
			} else if (keycode == sk_y) {
				return 1;
			} else {
				return 2;
			}
			// setCursorCol(0);
			// setCursorRow(16-1);
			// printf("%d, %d: %d ", dx, dy, level[mapx + (mapy + dy) * mapw + dx + 1]);
			if (mapx + dx < mapw && mapy + dy < maph) {
				// check if moving onto a space
				if ((c = level[mapx + (mapy + dy) * mapw + dx + 1]) == ' ') {
					mapx = mapx + dx;
					mapy = mapy + dy;
					redraw = 1;
				// check if moving onto a box and we're within the map
				} else if (c >= 'a' && c <= 'e') {
					if (mapx + dx + dx < mapw && mapy + dy + dy < maph) {
						// if moving onto a space or box finish of the same color
						if ((c2 = level[mapx + (mapy + dy + dy) * mapw + dx + dx + 1]) == ' ' || ((c - c2) == 0x20)) {
							// move the box to the new position
							level[mapx + (mapy + dy + dy) * mapw + dx + dx + 1] = (c2 == ' ' ? c : c2);
							// reset the old box position to ' '
							level[mapx + (mapy + dy) * mapw + dx + 1] = ' ';
							if (c2 != ' ')
								numBoxes--;
							mapx = mapx + dx;
							mapy = mapy + dy;
							redraw = 1;
						}
					}
				}
			}
		}
	}
}

void main(void) {
	level = 0xF2000001;
	BOXMAN_NUM_LEVELS = 2;
	waitkeycycle();
	while (BoxmanMain() != 1);
}
