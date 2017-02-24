#include "conio.h"

uint16_t * const pConsole = (uint16_t *) 0xb8000;

volatile uint16_t cur_pos = 0;

void putc(unsigned char ch){

	if (ch == '\r'){
		cur_pos = 80*(short)(cur_pos/80);
		return;
	}
	
	if (ch == '\n'){
		cur_pos += 80;
		return;
	}

	pConsole[cur_pos] &= 0xFF00;
	pConsole[cur_pos] |= ((unsigned short) ch) << 0;

	++cur_pos;

	return;
}

void puts(char * str){

	while (*str){
		putc(*str);
		str++;
	}

}

void clrscr(void){

	for (short i = 0; i < 80*25; ++i){
		pConsole[i] = (short) 0x0720;
	}

	cur_pos = 0;

	return;
}

void clrscr_color(uint8_t fore, uint8_t back){

	uint16_t clear_value = (fore << 12) | ((back&0x0F)<<8) | 0x20;

	for (short i = 0; i < 80*25; ++i){
		pConsole[i] = clear_value;
	}

	cur_pos = 0;

	return;
}


char conv_nibble(uint8_t val){

	val &= 0x0F;
	val += '0';

	if (val>'9')
		val+=39;
		
	return val;
}

// Converts a number into a hexidecimal string, null terminated.
void int32_to_hex(char buf[], uint32_t val){

	int num_digits = 0;

	int i = 0;
	
	//Handle 0 explicitly
	if (!val)
	{
		buf[0] = '0';
		buf[1] = '\0';
		return;
	}
	
	//val = rev_nibbles(val);
	{
		uint32_t y = 0;
		while (val)
		{
			y <<= 4;
			y |= val & 0xF;
			val >>= 4;
			++num_digits;
		}
		val = y;
	}

	for(i = 0; i < num_digits; ++i)
		
		//val>>(i<<2) = val >> (4i) = val / 2^(4i)
		buf[i] = conv_nibble( (val>>(i<<2))&0x0f );
		
	buf[num_digits] = 0;		//Terminate it with a zero


	
	
	return;
}

void int32_to_oct(char buf[], uint32_t val){

	int num_digits = 0;	//How many digits have we processed?

	int i;
	
	//Reverse and convert
	while (val){
	
		buf[num_digits] = conv_nibble( val % 8 );
		val /= 8;
	
		++num_digits;
	}
	
	reverse(buf,num_digits);
	
/*	//Correct the order
	for(i=0; i<(num_digits/2); ++i){	//Only need to do half of them.
		//This has an extra benefit of always skipping a center-odd.

		buf[i]^=buf[num_digits-1-i];
		buf[num_digits-1-i]^=buf[i];
		buf[i]^=buf[num_digits-1-i];
	}
*/
	buf[num_digits] = 0;		//Terminate it with a zero
	
	return;
}


// Implementation of itoa()
char* itoa(int num, char* str, uint32_t base)
{
    int i = 0;
    int isNegative = 0;

    // Handle 0 explicitely, otherwise empty string is printed for 0
    if (num == 0)
    {
        str[i++] = '0';
        str[i] = '\0';
        return str;
    }

    // In standard itoa(), negative numbers are handled only with 
    // base 10. Otherwise numbers are considered unsigned.
    if (num < 0 && base == 10)
    {
        isNegative = -1;
        num = -num;
    }

    // Process individual digits
    while (num != 0)
    {
        int rem = num % base;
        str[i++] = rem > 9? rem-10 + 'a' : rem + '0';
        num = num/base;
    }

    // If number is negative, append '-'
    if (isNegative)
        str[i++] = '-';

    str[i] = '\0'; // Append string terminator

    // Reverse the string
    reverse(str, i);

    return str;
}

// A utility function to reverse a string 
void reverse(char str[], int length)
{
    int start = 0;
    int end = length -1;
    while (start < end)
    {
		*(str+start)^=*(str+end);
		*(str+end)	^=*(str+start);
		*(str+start)^=*(str+end);

        //swap(*(str+start), *(str+end));
        start++;
        end--;
    }
}
