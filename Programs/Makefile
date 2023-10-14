
all:
	make -C C
	fasmg main.asm bin/main.bin
	python assembler.py bin/main.bin img/main.png
	fasmg memtest.asm bin/memtest.bin
	python assembler.py bin/memtest.bin img/memtest.png
	fasmg test.asm bin/test.bin
	python assembler.py bin/test.bin img/test.png
