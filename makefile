boot.iso: stage1.cd.bin
	mkisofs -no-emul-boot -b stage1.cd.bin -boot-load-size 4 -o boot.iso stage1.cd.bin

stage1.cd.bin: stage1.cd.o testA20.o
	ld -m elf_x86_64 -e start -Ttext 0x7c00 --oformat binary -o stage1.cd.bin stage1.cd.o testA20.o

stage1.cd.o: stage1.cd.asm
	nasm stage1.cd.asm -felf64 -o stage1.cd.o

testA20.o: testA20.asm
	nasm testA20.asm -felf64 -o testA20.o

clean:
	-@rm *.o *.bin 2>/dev/null || true
