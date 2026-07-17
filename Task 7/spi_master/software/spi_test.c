#include <stdint.h>

#define LEDS        (*(volatile uint32_t *)0x400000)
#define UART_DATA   (*(volatile uint32_t *)0x400008)
#define UART_CTRL   (*(volatile uint32_t *)0x400010)

/* Change this if your SPI base address is different */
#define SPI_BASE    0x400040

#define SPI_CTRL    (*(volatile uint32_t *)(SPI_BASE + 0x00))
#define SPI_TXDATA  (*(volatile uint32_t *)(SPI_BASE + 0x04))
#define SPI_RXDATA  (*(volatile uint32_t *)(SPI_BASE + 0x08))
#define SPI_STATUS  (*(volatile uint32_t *)(SPI_BASE + 0x0C))

void delay(volatile uint32_t d)
{
    while(d--)
        asm volatile("nop");
}

void uart_putchar(char c)
{
    while(UART_CTRL & (1<<9));
    UART_DATA = c;
}

void uart_print(const char *s)
{
    while(*s)
        uart_putchar(*s++);
}

void uart_print_hex8(uint8_t value)
{
    const char hex[]="0123456789ABCDEF";

    uart_putchar('0');
    uart_putchar('x');
    uart_putchar(hex[(value>>4)&0xF]);
    uart_putchar(hex[value&0xF]);
}

int main()
{
    uint8_t rx;

    uart_print("\n===== SPI LOOPBACK TEST =====\n");

    /* CLKDIV = 2, EN = 1 */
    SPI_CTRL = (2<<8) | 0x01;

    uart_print("Writing TXDATA = ");
    uart_print_hex8(0xA5);
    uart_print("\n");

    SPI_TXDATA = 0xA5;

    uart_print("Starting transfer...\n");

    /* START = 1 */
    SPI_CTRL = (2<<8) | 0x03;

    /* wait DONE */
    while((SPI_STATUS & 0x2)==0);

    rx = SPI_RXDATA & 0xFF;

    uart_print("Received RXDATA = ");
    uart_print_hex8(rx);
    uart_print("\n");

    if(rx==0xA5)
        uart_print("PASS\n");
    else
        uart_print("FAIL\n");

    while(1)
    {
        LEDS = 0x1F;
        delay(500000);

        LEDS = 0x00;
        delay(500000);
    }

    return 0;
}
