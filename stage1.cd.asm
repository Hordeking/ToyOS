section .text
bits 16
;ORG 0x7C00

extern A20_Check
extern A20_Enable
global start

start:
  jmp	0x0000:boot
  times 8-($-$$) db 0
 
  ;	Boot Information Table
  bi_PrimaryVolumeDescriptor  resd  1    ; LBA of the Primary Volume Descriptor
  bi_BootFileLocation         resd  1    ; LBA of the Boot File
  bi_BootFileLength           resd  1    ; Length of the boot file in bytes
  bi_Checksum                 resd  1    ; 32 bit checksum
  bi_Reserved                 resb  40   ; Reserved 'for future standardization'
 
boot:
  ;	Boot code here - set segment registers etc...
  
  	mov ax, cs
	mov ds, ax
	mov es, ax
	cli
	mov ss, ax
	mov sp, start
	sti
	
	mov si, welcome
	call putstr

end:
	hlt
	jmp end
	
welcome: db "Welcome to Toy OS CD Edition!", 0x0d, 0x0a,"Built on ", __DATE__," ",__TIME__, 0x0d, 0x0a, 0

putstr:
	lodsb
	or al, al
	jz .putstrd
	mov ah, 0x0e
	mov bx, 0x0007
	int 0x10
	jmp putstr
.putstrd:
	ret
  
;size	equ	$ - start
;%if size > 2048
;  %error "code is too large for boot sector"
;%endif
;	times	(2048 - size) db 0
