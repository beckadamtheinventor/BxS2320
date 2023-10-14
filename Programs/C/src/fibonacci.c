

long fib(uint8_t iterations) {
	long na, nb, nc;
	na = nb = 1;
	if (iterations < 2) {
		return na;
	}
	while (iterations--) {
		nc = na;
		na = na + nb;
		nb = nc;
	}
	return na;
}

void main() {
	char key = 0;
	uint8_t num = 1;
	while (1) {
		print("fib(", 0x7fff);
		printuint(num);
		printline(")=");
		printuint(fib(num));
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
