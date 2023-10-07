
all:
	$(call MKDIR,obj)
	$(call MKDIR,ir)
	bcc src/fibonacci.c -a ir/fibonacci.asm -o obj/fibonacci.asm -f BxS2320
	bcc src/boxman.c -a ir/boxman.asm -o obj/boxman.asm -f BxS2320

clean:
	$(call RMDIR,obj)
	$(call RMDIR,ir)

