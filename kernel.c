#include <stdint.h>
#include "conio.h"
#include "printf/printf.h"

int32_t serial_set_baudrate(uint16_t baseport, uint16_t baudrate);
int32_t serial_set_databits(uint16_t baseport, uint8_t nBits);
int32_t serial_set_stopbits(uint16_t baseport, uint8_t nStopBits);
int32_t serial_set_parity(uint16_t baseport, uint8_t parity);

void serial_putc(uint16_t baseport, char ch);
void serial_puts(uint16_t baseport, char * pbuffer);
char serial_getc(uint16_t baseport);

void serial_wait_for_tx(uint16_t baseport);
void serial_wait_for_rx(uint16_t baseport);

int load_com_from_serial(uint8_t * address);

void _putchar(char character)
{
  // send char to console etc.
  //putc(character);
  serial_wait_for_tx(0x3f8);
  serial_putc(0x3f8, character);
}

void kernel_main(void)
{
	char hellotext[] = "Hello, World.\0";
	/* Initialize terminal interface */
	//terminal_initialize();
 	//puts(hellotext);

 	serial_set_baudrate(0x3f8, 57600);
 	serial_set_databits(0x3f8, 8);
 	serial_set_stopbits(0x3f8, 1);
 	serial_set_parity(0x3f8, 0);

// 	out(0x3f8, 0x42);

// 	serial_puts(0x3f8, hellotext);

 	char foo = keyboard_map[1];

 	clrscr();
/*
	for(;;){
		serial_wait_for_rx(0x3f8);
	 	putc(inportb(0x3f8));
	 	//putc(serial_getc(0x3f8));
	 }
*/

	printf("Hello World.");

	load_com_from_serial( (char *) (void *)0x100000);

	/* Newline support is left as an exercise. */
	//terminal_writestring("Hello, kernel World!\n");
}

int load_com_from_serial(uint8_t * address){

	for(;;){
		serial_wait_for_rx(0x3f8);
	 	//putc(inportb(0x3f8));
	 	putc(serial_getc(0x3f8));
	 }

	return 0;
}
