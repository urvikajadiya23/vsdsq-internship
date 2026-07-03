#include <stdint.h>

#define IO_BASE 0x400000 
#define UART_DATA  (*(volatile uint32_t *)(IO_BASE + 0x08))
#define UART_CTRL  (*(volatile uint32_t *)(IO_BASE + 0x10))
#define SPI_CTRL   (*(volatile uint32_t *)(0x400040))
#define SPI_TXDATA (*(volatile uint32_t *)(0x400044))
#define SPI_RXDATA (*(volatile uint32_t *)(0x400048))
#define SPI_STATUS (*(volatile uint32_t *)(0x40004C))

void uart_putchar(char c)
{
while(UART_CTRL & (1<<9));
UART_DATA =c;
}

void uart_print(char *s)
{
while(*s)
uart_putchar(*s++);
}

void uart_print_hex(uint32_t x)
{
char hex[]="0123456789ABCDEF";

uart_print("0x");

for(int i=28;i>=0;i-=4)
uart_putchar(hex[(x>>i)&0xF]);

uart_putchar('\n');
}

int main()
{
uart_print ("SPI TEST START  ");
SPI_CTRL = (1<<0)|(2<<8);
SPI_TXDATA = 0xA5;
SPI_CTRL|= (1<<1);

while(!(SPI_STATUS & (1<<1)));

uart_print("RX = ");
uart_print_hex(SPI_RXDATA);

uart_print("SPI TEST DONE  ");

while(1);

return 0;

}
