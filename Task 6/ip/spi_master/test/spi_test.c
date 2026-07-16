#include <stdint.h>

#define LEDS      (*(volatile uint32_t *)0x400000)
#define UART_DATA (*(volatile uint32_t *)0x400008)
#define UART_CTRL (*(volatile uint32_t *)0x400010)

void delay(volatile unsigned int d)
{
    while(d--);
}

void uart_putchar(char c)
{
    while(UART_CTRL & (1<<9));
    UART_DATA = c;
}

void uart_print(char *s)
{
    while(*s)
        uart_putchar(*s++);
}

int main()
{
    uart_print("System Booted!\n");

    while(1)
    {
        LEDS = 0x1F;
        uart_print("LED ON\n");
        delay(500000);

        LEDS = 0x00;
        uart_print("LED OFF\n");
        delay(500000);
    }

    return 0;
}

