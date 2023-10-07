
void u64add(long *a, uint8_t *b) {
	uint8_t i = 0;
	short acc = 0;
	do {
		acc = acc + *a;
		acc = acc + *b;
		*a = acc;
		acc = acc >> 8;
		a++;
		b++;
	} while (i++ < 8);
}

void u64copy(void *a, void *b) {
	memcpy(a, b, 8);
}

void u64set(long *a, long b) {
	*a = b;
	memset(a+4, 0, 4);
}

long *fib(uint8_t iterations, long *a) {
	uint8_t b[8], c[8];
	u64set(a, 1);
	u64set(&b, 1);
	if (iterations >= 2) {
		while (iterations--) {
			u64copy(&c, a);
			u64add(a, &b);
			u64copy(&b, &c);
		}
	}
	return a;
}

void printuint64(uint8_t *num) {
	int i = 0;
	do {
		uint8_t a;
		uint8_t c;
		c = num[i];
		a = c >> 4;
		printchar(a>9?(a+'A'-10):(a+'0'), 0x7fff);
		a = c & 15;
		printchar(a>9?(a+'A'-10):(a+'0'), 0x7fff);
	} while (i++ < 8);
}

void main() {
	uint8_t fibnum[8];
	char key = 0;
	uint8_t num = 1;
	while (1) {
		print("fib(", 0x7fff);
		printuint(num);
		printline(")=");
		fib(num, &fibnum);
		printuint64(&fibnum);
		settextxy(0, 0);
		key = waitkeycycle();
		if (key == sk_y) {
			return ;
		} else if (key == sk_b) {
			return ;
		} else if (key == sk_up) {
			num++;
		} else if (key == sk_down) {
			num--;
		} else if (key == sk_right) {
			num = num + 16;
		} else if (key == sk_left) {
			num = num - 16;
		}
	}
	return;
}
