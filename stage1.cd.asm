section .text
bits 16
;ORG 0x7C00

extern A20_Check
extern A20_Enable
extern keyboard_map
;extern putc
global start

start:
  jmp	0x0000:boot
  times 8-($-$$) db 0
 
  ;	Boot Information Table
  bi_PrimaryVolumeDescriptor	dd  0	; LBA of the Primary Volume Descriptor
  bi_BootFileLocation			dd  0	; LBA of the Boot File
  bi_BootFileLength				dd  0	; Length of the boot file in bytes
  bi_Checksum					dd  0	; 32 bit checksum
  bi_Reserved					times 40 db  0	; Reserved 'for future standardization'
 
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
	
;Let's check and enable A20.
Check1_A20:
	; Check to see if Line A20 is enabled.
	call A20_Check
	jc Check2_A20.A20_Enabled

.A20_NotEnabled:
	mov si, a20off	; Display a message
	call putstr
	
	call A20_Enable
	
	jmp .A20_End

.A20_End:


Check2_A20:
	; Check to see if Line A20 is enabled.
	call A20_Check
	jc .A20_Enabled

.A20_NotEnabled:
	mov si, a20off	; Display a message
	call putstr
	
	jmp .A20_End

.A20_Enabled:
	mov si, a20on
	call putstr
.A20_End:

;Line A20 should be enabled now. Let's set up our initial GDT.

cli
lidt [IDT_null.pointer]

lgdt [gdt.Pointer]

; Actually switch on protected mode.
mov	eax, cr0
or	 eax, 1
mov	cr0, eax
mov ax, 0x10
mov ds, ax
mov es ,ax
mov fs, ax
mov gs, ax

jmp (gdt.Code-gdt.Null):begin32
nop
nop

end:
	hlt
	jmp end


bits 32

begin32:

	lidt [IDT.pointer]

	mov ax, 0x10
	mov ss, ax
	mov ds, ax
	mov es, ax
	
	;Now, let's remap the interrupts coming from the PICs
	;They conflict with the x86 processor exceptions.
	;We'll map IRQ0-7 to 0x20-0x27, IRQ8-F to 0x28-0x2F

	;Send Initialize Command 0x11 (0b00010001) to PIC0 and 1
	mov al, 0x11
	out 0x20, al
	out 0xa0, al
	
	;ICW1, this is the base interrupt vector for each PIC
	mov al, 0x20
	out 0x21, al
	mov al, 0x28
	out 0xa1, al
	
	;ICW2, Set PIC0 to master, PIC1 to slave
	mov al, 0x04
	out 0x21, al
	mov al, 0x02
	out 0xa1, al
	
	;ICW3, Enable 8086 mode for both 8259A's
	mov al, 0x01
	out 0x21, al
	out 0xa1, al
	
	;ICW4, the interrupt mask for each of them.
	mov al, 0b11111101
	out 0x21, al ;0xFC, unmask irq1	
	mov al, 0xff
	out 0xa1, al
	
	;8259A's should be initialized and ready now.

	;Now, let's set up a basic IDT for real
	;First, let's assign all other interrupts to the stub
	mov ecx, 49
zero_out_idt:
	mov ebx, ecx
	mov eax, int_stub
	mov word [IDT+ebx*8+0],ax
	mov word [IDT+ebx*8+2],0x08
	mov word [IDT+ebx*8+4],0x8E00
	shr eax,16
	mov word [IDT+ebx*8+6],ax
	loop zero_out_idt

	;Then, we'll assign a handler to int 33 (0x21)
	mov eax,int_keyb
	mov word [IDT+33*8+0],ax
	mov word [IDT+33*8+2],0x08
	mov word [IDT+33*8+4],0x8E00
	shr eax,16
	mov word [IDT+33*8+6],ax
	
	;Then, we'll assign a handler to int 49 (0x31)
	mov eax,int_49_handler
	mov word [IDT+49*8+0],ax
	mov word [IDT+49*8+2],0x08
	mov word [IDT+49*8+4],0x8E00
	shr eax,16
	mov word [IDT+49*8+6],ax

	sti
;	int 0x31

.end:
	;cli
	hlt
	jmp .end


int_49_handler:
	mov ax, 0x10
	mov gs, ax
	mov dword [gs:0xB8000],') : '
	iret

int_keyb:
	pushad
	mov ax, 0x10
	mov gs, ax

	in al, 0x64
	and al, 0x01
	jz .keyb_buffer_empty
	;The buffer isn't empty. Let's map the scancode to ascii
	xor ebx, ebx
	in al, 0x60
	mov bl, al
	test bl, bl
	jz .keyb_buffer_empty
	and al, 0x80
	jnz .keyb_buffer_empty
	mov al, byte [keyboard_map+ebx]

	;Moves the cursor from the base of video memory to the correct position
	mov esi, 0xb8000
	add esi, [curpos]

	mov byte [gs:esi], al
	
	;Increment and save the cursor
	add dword [curpos], 2

	
.keyb_buffer_empty:

	mov al, 0x20
	out 0x20, al
	
	popad
	iret
	
	curpos dd 0

int_stub:
	iret

	
; Global Descriptor Table
gdt:
.Null:	  dq	0x0000000000000000	 ;	Null
.Code:	  dq	0x00CF9A000000FFFF	 ;	Kernel Code
.Data:	  dq	0x00CF92000000FFFF	 ;	Kernel Data

ALIGN 4
	dw 0		 ; Padding to make the "address of the GDT" field aligned on a 4-byte boundary
.Pointer:
	dw $ - gdt - 1		; 16-bit Size (Limit) of GDT.
	dd gdt				; 32-bit Base Address of GDT. (CPU will zero extend to 64-bit)


ALIGN 4
IDT_null:

.pointer:
	.Length		dw 0
	.Base		dd 0

IDT:
	times 50*2 dd 0

.pointer:
	.Length		dw (50*8)-1
	.Base		dd IDT
	
welcome db "Welcome to Toy OS CD Edition!", 0x0d, 0x0a,"Built on ", __DATE__," ",__TIME__, 0x0d, 0x0a, 0
a20on			db "Line A20 is on!", 0x0d, 0x0a, 0
a20off			db "Line A20 is off :(", 0x0d, 0x0a, 0
prot32modestart	db "Setting up 32b protected mode.", 0x0d, 0x0a, 0
prot32modegood	db "Now in 32b protected mode.", 0x0d, 0x0a, 0
prot64modestart	db "Setting up 64b protected mode.", 0x0d, 0x0a, 0
prot64modegood	db "Now in 64b protected mode.", 0x0d, 0x0a, 0

;unsigned char keyboard_map[128]
;keyboard_map	db 0x00, 0x1b, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x2d, 0x3d, 0x08, 0x09
;				db 0x71, 0x77, 0x65, 0x72, 0x74, 0x79, 0x75, 0x69, 0x6f, 0x70, 0x5b, 0x5d, 0x0a, 0x00, 0x61, 0x73
;				db 0x64, 0x66, 0x67, 0x68, 0x6a, 0x6b, 0x6c, 0x3b, 0x27, 0x60, 0x00, 0x5c, 0x7a, 0x78, 0x63, 0x76
;				db 0x62, 0x6e, 0x6d, 0x2c, 0x2e, 0x2f, 0x00, 0x2a, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
;				db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2d, 0x00, 0x00, 0x00, 0x2b, 0x00
;				db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
;				db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
;				db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

bits 16

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
