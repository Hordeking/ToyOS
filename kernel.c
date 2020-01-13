#include <stdint.h>
#include "conio.h"

void writeserialstring(uint16_t baseport, char * pbuffer);
int setup_serial(uint16_t baseport, uint8_t nBits, uint8_t parity, uint8_t nStopbits);
int serial_set_baudrate(uint16_t baseport, uint16_t baudrate);

void kernel_main(void) 
{
	char hellotext[] = "Hello, World.\0";
	/* Initialize terminal interface */
	//terminal_initialize();
 	//puts(hellotext);
 	
 	setup_serial(0x3f8, 8, 0, 1);
 	serial_set_baudrate(0x3f8, 5);
 	
 	writeserialstring(0x3f8, hellotext);
 	
 	char foo = keyboard_map[1];
	/* Newline support is left as an exercise. */
	//terminal_writestring("Hello, kernel World!\n");
}
