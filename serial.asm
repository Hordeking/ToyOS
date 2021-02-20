
; Setup functions
global serial_set_baudrate
global serial_set_databits
global serial_set_stopbits
global serial_set_parity

; Output functions
global serial_putc
global serial_puts

; Input functions
global serial_getc

; Control functions
global serial_wait_for_tx
global serial_wait_for_rx

serial_set_baudrate:

	; Returns:	eax = 0 on success
	;			eax = -1 on fail

	; Parameters:
	;	uint16_t baseport -> [ebp+8]
	;	uint32_t baudrate -> [ebp+12]

	; Locals:
	;	uint32_t clock_divider -> [ebp-4]


	; Save base pointer
	push ebp
	mov ebp, esp
	sub esp, 4		; Space for Local Variables

	mov eax, 115200
	xor edx, edx
	div dword [ebp+12]
	mov [ebp-4], eax		; Save the result of 115200/bdrate

	; Check that the clock divisor is not zero.
	; Only check the low half, since we can't use the upper half.
	test ax, ax
	jz .bad_baudrate

	; First, set DLAB bit of line control register (port+3)
	; We do this because the DLAB determines if writes to
	; 0x3f8 etc go to the FIFO or to the control register
	mov dx, [ebp+8]
	add dx, 3
	in al, dx
	or al, 0x80
	out dx, al

	; Actually write the clock divisor

	;Output lower byte to port base+0
	mov dx, [ebp+8]
	add dx, 0
	mov al, byte [ebp-4]
	out dx, al

	; Output upper byte to port base+1
	add dx, 1
	mov al, byte [ebp-3]
	out dx, al

	; Clock divisor written.

	; Clear the DLAB bit so we can tx/rx again
	mov dx, [ebp+8]
	add dx, 3
	in al, dx
	and al, 0x7f
	out dx, al

	;Success. Return 0.
	xor eax, eax
	jmp .end

	.bad_baudrate:
	mov eax, -1

	.end:
	mov esp, ebp
	pop ebp
	ret

serial_set_databits:

	; Returns:	eax = 0 on success
	; 			eax = -1 on bad nBits

	; Parameters:
	;	uint16_t baseport -> [ebp+8]
	;	uint8_t nBits -> [ebp+12]

	; Save base pointer
	push ebp
	mov ebp, esp
	sub esp, 0		; Space for Local Variables

	; Now lets set char length, stop bits, and parity!

	; Begin by reading in the LCR, don't want to tweak DLAB
	mov dx, [ebp+8]
	add dx, 3
	in al, dx

	; Set the number of data bits
	mov ah, byte [ebp+12]
	sub ah, 5
	test ah, 0xfc		; Check that result is {0,1,2,3}
	jnz .end_badnbits
	or al, ah

	; Write nBits back out.
	out dx, al

	; We were successful
	xor eax, eax
	jmp .end

	; Bad number of data bits
	.end_badnbits:
	mov eax, -1

	.end:
	mov esp, ebp
	pop ebp
	ret


serial_set_stopbits:

	; Returns:	eax = 0 on success
	;			eax = -1 on bad stop bits

	; Parameters:
	;	uint16_t baseport -> [ebp+8]
	;	uint8_t nStopBits -> [ebp+12]


	; Save base pointer
	push ebp
	mov ebp, esp

	; Now lets set stop bits

	; Begin by reading in the LCR, don't want to tweak DLAB
	mov dx, [ebp+8]
	add dx, 3
	in al, dx

	; Set the number of stop bits
	mov ah, byte [ebp+12]
	sub ah, 1
	test ah, 0xfe		; Check that result is {0,1}
	jnz .end_badnstopbits

	; Shift stop bits to the left, then combine it with our character length.
	shl ah, 2
	or al, ah

	; Write it out to [port+3],
	out dx, al

	; We were successful
	xor eax, eax
	jmp .end

	; Bad number of stop bits
	.end_badnstopbits:
	mov eax, -1

	.end:
	mov esp, ebp
	pop ebp
	ret


serial_set_parity:

	; Returns:	eax = 0 on success
	;			eax = -1 on bad parity

	; Parameters:
	;	uint16_t baseport -> [ebp+8]
	;	uint8_t parity -> [ebp+12]

	; Save base pointer
	push ebp
	mov ebp, esp

	; Now lets set parity!

	; Begin by reading in the LCR, don't want to tweak DLAB
	mov dx, [ebp+8]
	add dx, 3
	in al, dx

	; Set the parity
	; Valid values
	; 0->N, 1->O, 3->E
	; 5->Mark, 7->Space
	; Values 2,4,6 are invalid.
	mov ah, [ebp+12]	; For now, user must validate their own value.
	shl ah, 3
	or al, ah

	; Write it out to [port+3], turning off DLAB in the process
	out dx, al

	; We were successful
	xor eax, eax
	jmp .end

	; Bad parity
	.end_badparity:
	mov eax, -1

	.end:
	mov esp, ebp
	pop ebp
	ret

serial_puts:

	; <doug16k> did you probe for fifo properly? Maybe it is behaving as an 8250 and there is no fifo
	; <MarchHare> doug16k: That might be likely. Is there a link to how to probe for a fifo?
	; <MarchHare> This? outb(PORT + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
	; <doug16k> yes but you have to read it back and see if the bits wrote, or got dropped to 0
	; <doug16k> kept value == have fifo. got zeroed == no fifo
	; <doug16k> you can also try setting bit 5, if that bit isn't stuck at 0, fifo is 64 bytes, not 16
	; <doug16k> in my code I only care if the top 2 bits are not zero to know it is at least 16550A with fifo
	; <doug16k> top two bits set the incoming fifo level to trigger IRQ. 0b11xxxxxx (from 0xC0) maxes it out

	; Returns:	void

	; Parameters:
	;	uint16_t baseport -> [ebp+8]
	;	uint32_t pBuffer -> [ebp+12]

	;Save base pointer
	push ebp
	mov ebp, esp

	
	mov esi, [ebp+12]	; Second parameter, pBuffer
	mov dx, [ebp+8]		; First parameter baseport

	.write_to_serial:

		mov dx, [ebp+8]
		add dx, 5
		.busywait_for_serial:
		in al, dx
		test al, 0x20
		jz .busywait_for_serial
		nop

		mov dx, [ebp+8]
		mov ecx, 16
		.grab_another_byte:
		lodsb
		or al, al
		jz .finished_write_to_serial
		out dx, al
		loop .grab_another_byte
		jmp .write_to_serial

	.finished_write_to_serial:

	mov esp, ebp
	pop ebp
	ret

serial_putc:
	; Returns:	void

	; Parameters:
	;	uint16_t baseport -> [ebp+8]
	;	uint8_t ch -> [ebp+12]

	;Save base pointer
	push ebp
	mov ebp, esp

	mov eax, [ebp+12]	; Second parameter, ch
	mov dx, [ebp+8]		; First parameter baseport

	out dx, al

	mov esp, ebp
	pop ebp
	ret

serial_getc:
	; Returns:	void

	; Parameters:
	;	uint16_t baseport -> [ebp+8]

	;Save base pointer
	push ebp
	mov ebp, esp

	mov eax, 0			; Clear the return value
	mov dx, [ebp+8]		; First parameter baseport

	in al, dx

	mov esp, ebp
	pop ebp
	ret

serial_wait_for_tx:

	; Returns:	void

	; Parameters:
	;	uint16_t baseport -> [ebp+8]

	;Save base pointer
	push ebp
	mov ebp, esp

	mov dx, [ebp+8]
	add dx, 5
	.busywait_for_serial:
	in al, dx
	test al, 0x20
	jz .busywait_for_serial
	nop

	mov esp, ebp
	pop ebp
	ret

serial_wait_for_rx:

	; Returns:	void

	; Parameters:
	;	uint16_t baseport -> [ebp+8]

	;Save base pointer
	push ebp
	mov ebp, esp

	mov dx, [ebp+8]
	add dx, 5
	.busywait_for_serial:
	in al, dx
	test al, 0x01
	jz .busywait_for_serial
	nop

	mov esp, ebp
	pop ebp
	ret
