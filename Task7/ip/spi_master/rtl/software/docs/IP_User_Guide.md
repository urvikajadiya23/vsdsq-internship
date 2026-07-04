# SPI Master IP – User Guide

**Version:** 1.0  
**Target Platform:** VSDSquadron FPGA SoC  
**Date:** July 2026

---

# 1. Introduction

The SPI Master IP is a lightweight, memory-mapped peripheral designed for integration with the VSDSquadron RISC-V SoC. It provides a simple and configurable interface for transmitting and receiving 8-bit data over the Serial Peripheral Interface (SPI) using **SPI Mode 0 (CPOL = 0, CPHA = 0)**.

The peripheral is intended for educational, prototyping, and embedded applications where a minimal SPI controller is sufficient. Software running on the RISC-V processor controls the peripheral entirely through memory-mapped registers.

The SPI Master supports one transfer at a time and automatically manages the SPI clock (SCLK), chip-select (CS_N), and transfer status.

---

# 2. Features

- Memory-mapped 32-bit register interface
- SPI Mode 0 operation (CPOL = 0, CPHA = 0)
- Full-duplex 8-bit data transfers
- Programmable SPI clock divider
- Automatic chip-select (CS_N) control
- Hardware-generated BUSY and DONE status flags
- Software-controlled transfer initiation
- Internal loopback support for validation on VSDSquadron FPGA
- Simple integration into the VSDSquadron RISC-V SoC

---

# 3. Functional Overview

The SPI Master IP acts as a bridge between the RISC-V processor and SPI-compatible peripherals.

Software writes a transmit byte into the transmit register, configures the SPI clock divider, enables the peripheral, and starts the transfer. During the transfer, the SPI Master shifts data out through the **MOSI** line while simultaneously sampling data on the **MISO** line.

Once all eight bits have been transmitted and received, the hardware:

- Stores the received byte in the receive register
- Clears the BUSY flag
- Sets the DONE flag
- Releases the chip-select signal

The processor can then read the received byte and initiate another transfer.

---

# 4. Block Diagram

```
                 +-----------------------------+
                 |      RISC-V Processor       |
                 +-------------+---------------+
                               |
                     Memory-Mapped Bus
                               |
                 +-------------v---------------+
                 |        SPI Master IP        |
                 |                             |
                 |  Register Interface         |
                 |  Control Logic              |
                 |  Clock Divider              |
                 |  Shift Registers            |
                 |  Status Logic               |
                 +------+------+------+--------+
                        |      |      |
                     MOSI    MISO   SCLK
                        |
                      CS_N
```

---

# 5. Operating Principle

The SPI Master performs a complete SPI transaction using the following sequence:

1. Software writes the transmit byte into the TXDATA register.
2. Software configures the clock divider in the CTRL register.
3. Software enables the SPI Master by setting the EN bit.
4. Software starts the transfer by setting the START bit.
5. The SPI Master automatically:
   - Drives CS_N low
   - Generates the SPI clock
   - Shifts data through MOSI
   - Samples data from MISO
6. After eight clock cycles:
   - CS_N returns high
   - BUSY is cleared
   - DONE is asserted
   - Received data is stored in RXDATA

Software then reads RXDATA and clears the DONE flag before initiating another transfer.

---

# 6. SPI Timing

The SPI Master implements **SPI Mode 0**, which has the following characteristics:

| Parameter | Value |
|-----------|-------|
| CPOL | 0 |
| CPHA | 0 |
| Idle Clock State | Low |
| Data Sample | Rising edge |
| Data Shift | Falling edge |

The SPI clock frequency is determined by the programmable clock divider:

```
SCLK Frequency = System Clock / (2 × (CLKDIV + 1))
```

---

# 7. Software Operation

A complete SPI transaction consists of the following software sequence:

1. Write the transmit byte to **TXDATA**.
2. Configure **CTRL**:
   - Enable the peripheral (EN = 1)
   - Set the desired CLKDIV value
3. Set **START = 1**.
4. Poll **STATUS.DONE** until it becomes **1**.
5. Read **RXDATA**.
6. Clear **DONE** by writing **1** to STATUS[1].

The peripheral automatically clears the START bit once the transfer begins.

---

# 8. Hardware Signals

| Signal | Direction | Description |
|---------|-----------|-------------|
| clk | Input | System clock |
| resetn | Input | Active-low reset |
| spi_sel | Input | Peripheral select from address decoder |
| spi_addr | Input | Register address selector |
| mem_wstrb | Input | Write enable |
| mem_wdata | Input | Write data |
| spi_rdata | Output | Read data |
| sclk | Output | SPI serial clock |
| mosi | Output | Master Out Slave In |
| miso | Input | Master In Slave Out |
| cs_n | Output | Active-low chip select |

---

# 9. Validation

The SPI Master IP has been validated using:

- RTL simulation
- Memory-mapped software execution on the RISC-V processor
- Internal MOSI-to-MISO loopback on the VSDSquadron FPGA

The loopback configuration allows transmitted data to be received back without requiring an external SPI slave device.

Typical validation sequence:

- Write TXDATA = 0xA5
- Start transfer
- Wait until DONE = 1
- Read RXDATA
- Verify RXDATA = 0xA5

---

# 10. Performance

| Parameter | Value |
|-----------|-------|
| Transfer Width | 8 bits |
| SPI Mode | Mode 0 |
| Register Width | 32 bits |
| Clock Divider | 8-bit Programmable |
| Concurrent Transfers | One |

---

# 11. Limitations

The current implementation has the following limitations:

- Supports SPI Mode 0 only.
- Supports only 8-bit transfers.
- Only one SPI transaction can be active at a time.
- No interrupt support; software polling is required.
- No transmit or receive FIFO.
- No multi-byte burst transfers.
- Chip-select is automatically controlled by hardware.

---

# 12. Applications

The SPI Master IP is suitable for:

- Sensor interfacing
- EEPROM communication
- Flash memory access
- ADC and DAC communication
- Embedded system prototyping
- FPGA laboratory exercises
- Educational RISC-V SoC projects

---

# 13. Related Documentation

For additional information, refer to:

- **Register_Map.md** – Register definitions and bit fields
- **Integration_Guide.md** – SoC integration procedure
- **Example_Usage.md** – Software examples
- **README.md** – Project overview

---
