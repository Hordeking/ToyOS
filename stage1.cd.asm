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
  bi_PrimaryVolumeDescriptor  dd  0    ; LBA of the Primary Volume Descriptor
  bi_BootFileLocation         dd  0    ; LBA of the Boot File
  bi_BootFileLength           dd  0    ; Length of the boot file in bytes
  bi_Checksum                 dd  0    ; 32 bit checksum
  bi_Reserved                 times 40 db  0   ; Reserved 'for future standardization'
 
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
mov    eax, cr0
or     eax, 1
mov    cr0, eax
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

	;Then, we'll assign a handler to int 49 (0x31)
    mov eax,int_49_handler
    mov word [IDT+49*8+0],ax
    mov word [IDT+49*8+2],0x08
    mov word [IDT+49*8+4],0x8E00
    shr eax,16
    mov word [IDT+49*8+6],ax

	;sti
	int 0x31

.end:
	cli
	hlt
	jmp .end


int_49_handler:
    mov ax, 0x10
    mov gs, ax
    mov dword [gs:0xB8000],') : '
    iret

int_stub:
	iret

	
; Global Descriptor Table
gdt:
.Null:      dq   0x0000000000000000     ;   Null
.Code:      dq   0x00CF9A000000FFFF     ;   Kernel Code
.Data:      dq   0x00CF92000000FFFF     ;   Kernel Data

ALIGN 4
	dw 0         ; Padding to make the "address of the GDT" field aligned on a 4-byte boundary
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
