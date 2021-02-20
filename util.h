#define pokeb(port, outval) \
{\
	__asm__ ("out  %%al, %%dx" : : "a" (outval), "d" (port));\
}

#define peekb(port, outvar) \
{\
	__asm__ ("in  %%dx, %%al" : "=a" (outvar): "d" (port));\
}

uint8_t inportb (uint16_t _port)
{
    unsigned char rv;
    __asm__ __volatile__ ("inb %1, %0" : "=a" (rv) : "dN" (_port));
    return rv;
}

void outportb (uint16_t _port, uint8_t _data)
{
    __asm__ __volatile__ ("outb %1, %0" : : "dN" (_port), "a" (_data));
}
