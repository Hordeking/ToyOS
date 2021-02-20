boot.iso: stage1.cd.bin
	mkisofs -input-charset utf-8 -no-emul-boot -b stage1.cd.bin -o boot.iso stage1.cd.bin

stage1.cd.bin: stage1.cd.o testA20.o conio.o serial.o kernel.o printf.o
	ld -m elf_i386 -e start -Ttext 0x7c00 --oformat binary -o stage1.cd.bin stage1.cd.o kernel.o printf.o conio.o testA20.o serial.o

printf.o: printf/printf.c
	gcc -m32 -fno-pic -ffreestanding -std=c17 -DPRINTF_DISABLE_SUPPORT_LONG_LONG -c printf/printf.c -o printf.o

kernel.o: kernel.c conio.h
	gcc -m32 -fno-pic -ffreestanding -std=c17 -c kernel.c -o kernel.o

conio.o: conio.c conio.h
	gcc -m32 -fno-pic -ffreestanding -std=c17 -c conio.c -o conio.o

stage1.cd.o: stage1.cd.asm
	nasm stage1.cd.asm -felf32 -o stage1.cd.o

testA20.o: testA20.asm
	nasm testA20.asm -felf32 -o testA20.o

serial.o: serial.asm
	nasm serial.asm -felf32 -o serial.o

clean:
	-@rm *.o *.bin 2>/dev/null || true
