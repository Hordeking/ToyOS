
#include <stdint.h>

void putc(unsigned char ch);

void puts(char * str);

void clrscr(void);

void clrscr_color(uint8_t fore, uint8_t back);

char conv_nibble(uint8_t val);
void int32_to_hex(char buf[], uint32_t val);
void int32_to_oct(char buf[], uint32_t val);

void reverse(char str[], int length);
char* itoa(int num, char* str, uint32_t base);

unsigned char keyboard_map[128];
