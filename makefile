boot.iso: stage1.cd.bin
	mkisofs -no-emul-boot -b stage1.cd.bin -boot-load-size 8 -o boot.iso stage1.cd.bin

stage1.cd.bin: stage1.cd.o testA20.o
	ld -m elf_i386 -e start -Ttext 0x7c00 --oformat binary -o stage1.cd.bin stage1.cd.o testA20.o

conio.o: conio.c conio.h
	gcc -m32 -ffreestanding -std=c11 -c conio.c -o conio.o

stage1.cd.o: stage1.cd.asm
	nasm stage1.cd.asm -felf32 -o stage1.cd.o

testA20.o: testA20.asm
	nasm testA20.asm -felf32 -o testA20.o

clean:
	-@rm *.o *.bin 2>/dev/null || true
