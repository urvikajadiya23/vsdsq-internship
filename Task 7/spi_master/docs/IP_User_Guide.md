# SPI Master IP – User Guide

**Version:** 1.0  
**Target Platform:** VSDSquadron FPGA SoC  
**Author:** Urvika Jadiya  
**Date:** July 2026

---

# Table of Contents

1. Introduction
2. Features
3. System Overview
4. Architecture
5. Register Map
6. Register Description
7. Operating Principle
8. SPI Timing
9. Hardware Interface
10. Software Flow
11. Validation
12. Hardware Demonstration
13. Performance
14. Limitations
15. Applications
16. Future Improvements

---

# 1. Introduction

The SPI Master IP is a lightweight, memory-mapped peripheral designed for integration with the VSDSquadron RISC-V System-on-Chip. It provides an efficient interface for transmitting and receiving 8-bit data using the Serial Peripheral Interface (SPI) protocol operating in **Mode 0 (CPOL = 0, CPHA = 0)**.

The peripheral is fully controlled through memory-mapped registers, allowing software executing on the RISC-V processor to configure the SPI clock, initiate transfers, monitor status, and retrieve received data.

The design focuses on simplicity, making it ideal for educational FPGA platforms, embedded applications, and custom SoC development.

---

# 2. Features

- Memory-mapped 32-bit register interface
- SPI Mode 0 (CPOL = 0, CPHA = 0)
- Full-duplex 8-bit communication
- Programmable SPI clock divider
- Automatic Chip Select (CS_N) generation
- Hardware-managed BUSY and DONE flags
- Auto-clearing START bit
- One transaction at a time
- Easy integration with the VSDSquadron RISC-V SoC

---

# 3. System Overview

```
                +---------------------------+
                |      RISC-V Processor     |
                +-------------+-------------+
                              |
                     Memory-Mapped Bus
                              |
                +-------------v-------------+
                |       SPI Master IP       |
                +------+------+------+------+
                       |      |      |
                     MOSI   MISO    SCLK
                       |
                     CS_N
```

The processor communicates with the SPI Master entirely through memory-mapped registers.

Software writes data into the transmit register, starts a transfer, waits for completion, and reads back the received byte.

---

# 4. Architecture

The SPI Master IP consists of the following functional blocks:

- Register Interface
- Control FSM
- Clock Divider
- Transmit Shift Register
- Receive Shift Register
- Status Register Logic
- SPI Signal Generator

The clock divider generates the SPI serial clock while the control FSM manages the complete transfer sequence.

---

# 5. Register Map

| Offset | Register | Access | Description |
|---------|----------|--------|-------------|
| 0x00 | CTRL | R/W | Enable, Start, Clock Divider |
| 0x04 | TXDATA | W | Transmit Data |
| 0x08 | RXDATA | R | Received Data |
| 0x0C | STATUS | R/W | Busy and Done Flags |

---

# 6. Register Description

## CTRL Register (0x00)

| Bit | Name | Description |
|-----|------|-------------|
|0|EN|Enable SPI Master|
|1|START|Start Transfer (Auto-clears internally)|
|15:8|CLKDIV|SPI Clock Divider|

---

## TXDATA Register (0x04)

| Bits | Description |
|------|-------------|
|7:0|Transmit Byte|

Writing to this register loads the transmit shift register.

---

## RXDATA Register (0x08)

| Bits | Description |
|------|-------------|
|7:0|Received Byte|

Contains the byte received during the most recent SPI transaction.

---

## STATUS Register (0x0C)

| Bit | Name | Description |
|-----|------|-------------|
|0|BUSY|SPI Transfer in Progress|
|1|DONE|Transfer Complete (Write 1 to Clear)|

---

# 7. Operating Principle

A complete SPI transaction proceeds as follows:

1. Software writes the transmit byte into TXDATA.
2. Software configures the desired SPI clock divider.
3. Software enables the SPI peripheral.
4. Software asserts the START bit.
5. The SPI Master automatically:
   - Drives CS_N low.
   - Generates the SPI clock.
   - Shifts data out on MOSI.
   - Samples data on MISO.
6. After eight bits:
   - CS_N returns high.
   - BUSY clears.
   - DONE is asserted.
   - RXDATA is updated.
7. Software reads RXDATA.
8. Software clears DONE by writing a 1 to STATUS[1].

The START bit is automatically cleared by hardware once the transfer begins.

If START is asserted while BUSY is high, the request is ignored until the current transfer completes.

---

# 8. SPI Timing

The SPI Master operates in **SPI Mode 0**.

| Parameter | Value |
|-----------|-------|
| CPOL | 0 |
| CPHA | 0 |
| Clock Idle State | Low |
| Data Sample | Rising Edge |
| Data Shift | Falling Edge |

SPI clock frequency:

```
SCLK = System Clock / (2 × (CLKDIV + 1))
```

Example:

System Clock = **12 MHz**

CLKDIV = **2**

```
SCLK = 12 MHz / (2 × (2 + 1))

SCLK = 2 MHz
```

---

# 9. Hardware Interface

| Signal | Direction | Description |
|---------|-----------|-------------|
| clk | Input | System Clock |
| resetn | Input | Active-Low Reset |
| spi_sel | Input | Peripheral Select |
| spi_addr | Input | Register Address |
| mem_wstrb | Input | Write Enable |
| mem_wdata | Input | Write Data |
| spi_rdata | Output | Read Data |
| sclk | Output | SPI Serial Clock |
| mosi | Output | Master Out Slave In |
| miso | Input | Master In Slave Out |
| cs_n | Output | Active-Low Chip Select |

---

# 10. Software Flow

```
Initialize SPI

↓

Configure CLKDIV

↓

Write TXDATA

↓

Set EN

↓

Set START

↓

Poll STATUS.DONE

↓

Read RXDATA

↓

Clear DONE

↓

Repeat
```

Typical software sequence:

```c
SPI_CTRL = (2<<8) | 0x01;

SPI_TXDATA = 0xA5;

SPI_CTRL = (2<<8) | 0x03;

while((SPI_STATUS & 0x2) == 0);

rx = SPI_RXDATA & 0xFF;

SPI_STATUS = 0x2;
```

---

# 11. Validation

## RTL Simulation

The SPI Master IP was verified using Verilator simulation.

A loopback connection was created inside the testbench by connecting:

```
MISO = MOSI
```

Simulation sequence:

- Write TXDATA = 0xA5
- Assert START
- Poll DONE
- Read RXDATA

Simulation Output:

```
===== SPI LOOPBACK TEST =====
Writing TXDATA = 0xA5
Starting transfer...
Received RXDATA = 0xA5
PASS
```

The received byte exactly matched the transmitted byte, confirming correct operation of the SPI transmit path, receive path, and register interface.

---

# 12. Hardware Demonstration

The SPI Master IP was successfully implemented on the VSDSquadron FPGA.

Hardware connections:

- MOSI connected to MISO using a jumper wire to create a physical loopback.
- UART TX and UART RX connected to a cp2102 USB-to-UART converter for serial communication with the host PC.

Demonstration sequence:

1. FPGA configured successfully.
2. Firmware initialized the SPI controller.
3. TXDATA loaded with **0xA5**.
4. START asserted.
5. CS_N driven low automatically.
6. SPI clock generated according to CLKDIV.
7. Data transmitted over MOSI.
8. Data looped back through the jumper into MISO.
9. DONE asserted after completion.
10. Firmware read RXDATA.
11. UART displayed:

```
===== SPI LOOPBACK TEST =====
Writing TXDATA = 0xA5
Starting transfer...
Received RXDATA = 0xA5
PASS
```

12. Onboard LEDs toggled after each successful SPI transaction, providing a visual indication of completed data transfers.

This demonstration verified:

- Memory-mapped register access
- SPI clock generation
- MOSI transmission
- MISO reception
- Loopback communication
- DONE flag generation
- UART communication
- Firmware integration
- Hardware operation on FPGA

---

# 13. Performance

| Parameter | Value |
|-----------|-------|
| Transfer Width | 8 bits |
| SPI Mode | Mode 0 |
| Register Width | 32 bits |
| Clock Divider | 8-bit Programmable |
| Concurrent Transfers | One |

---

# 14. Limitations

Current implementation supports:

- SPI Mode 0 only
- 8-bit transfers only
- Single transaction at a time
- Software polling
- No interrupt support
- No FIFO buffering
- Automatic Chip Select generation

---

# 15. Applications

This SPI Master IP can be used for:

- EEPROM communication
- SPI Flash memories
- ADC interfaces
- DAC interfaces
- Temperature sensors
- Accelerometers
- Embedded FPGA systems
- Educational RISC-V SoC platforms
- Custom FPGA peripherals

---

# 16. Future Improvements

Possible enhancements include:

- SPI Modes 1, 2, and 3
- Configurable transfer lengths
- Multi-byte burst transfers
- Interrupt support
- DMA interface
- TX/RX FIFOs
- Multiple chip-select outputs
- Configurable bit ordering (MSB/LSB first)
- Higher throughput support

---

## Conclusion

The SPI Master IP provides a compact, configurable, and reliable SPI controller for the VSDSquadron RISC-V SoC. Through memory-mapped control registers, programmable clock generation, automatic status management, and full-duplex communication, the design demonstrates a complete SPI solution suitable for FPGA-based embedded systems and educational SoC development. Validation through RTL simulation and FPGA hardware implementation confirms correct operation of both the hardware and software components.
