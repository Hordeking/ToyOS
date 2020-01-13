section .text
bits 16

global A20_Check
global A20_Enable

A20_Check:

	; Save registers that we are going to overwrite.
	pushf
	push ds
	push es
	push di
	push si

	cli					; No interrupts for this one

	xor ax, ax			; Set es:di = 0000:0500
	mov es, ax
	mov di, 0x0500

	mov ax, 0xffff		; Set ds:si = ffff:0510
	mov ds, ax
	mov si, 0x0510

	mov al, [es:di]		; Save byte at es:di on stack.
	push ax				; (we want to restore it later)

	mov al, [ds:si]		; Save byte at ds:si on stack.
	push ax				; (we want to restore it later)

	mov byte [es:di], 0x00		; [es:di] = 0x00
	mov byte [ds:si], 0xFF		; [ds:si] = 0xff

	cmp byte [es:di], 0xFF		; Did memory wrap around?
	
	pop ax
	mov [ds:si], al		; Restore byte at ds:si

	pop ax
	mov [es:di], al		; Restore byte at es:di
    
;	mov ax, 0
	je .a20_isDisabled	; If memory wrapped around, return false.

.a20_isEnabled:
	pop si			; Restore saved registers.
	pop di
	pop es
	pop ds
	popf
	mov ax, 0	; Return 0 for no error
	stc			; Set carry to return true
	ret

.a20_isDisabled:
	pop si			; Restore saved registers.
	pop di
	pop es
	pop ds
	popf
	mov ax, 0xffff	; Return -1 for error.
	clc			; Clear carry bit to return false
	ret
.End_A20_Check:


A20_Enable:
	; Attempt to enable the A20 line.
	in al, 0x92
	or al, 2
	out 0x92, al
	; A20 should be enabled now.
	ret
.End_A20_Enable:

;Read a memory location
;Save this onto the stack
;Read a memory location+1MiB
;Compare. If they are different, we're done. Pop value back, set carry flag, and return.

;If they're not the same,
;Write a test byte to the memory location that isn't what was there
;Loop to location+1MiB
