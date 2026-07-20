# SPI Master IP – Register Map

**Version:** 1.0  
**Target Platform:** VSDSquadron FPGA SoC  
**Date:** July 2026

---

# 1. Overview

The SPI Master IP is a lightweight memory-mapped peripheral integrated into the VSDSquadron RISC-V SoC. It implements a minimal **SPI Mode 0 (CPOL = 0, CPHA = 0)** master capable of performing single-byte (8-bit) full-duplex SPI transfers.

Software configures and controls the peripheral entirely through memory-mapped registers. The SPI Master generates the SPI clock, controls the chip-select signal, shifts transmit data on MOSI, samples receive data on MISO, and reports transfer status through hardware-generated status flags.

The register interface has been validated through both RTL simulation and FPGA hardware implementation.

---

# 2. Base Address

**SPI Base Address**

```
0x400040
```

All registers are 32-bit and word-aligned.

Register addresses are calculated as:

```
Register Address = SPI_BASE + Register Offset
```

---

# 3. Feature Summary

- Memory-mapped 32-bit register interface
- SPI Mode 0 (CPOL = 0, CPHA = 0)
- Full-duplex 8-bit transfers
- Programmable SPI clock divider
- Hardware-controlled BUSY and DONE flags
- Automatic chip-select (CS_N) control
- One SPI transfer at a time
- Compatible with the VSDSquadron RISC-V SoC

---

# 4. Register Summary

| Address | Offset | Register | Access | Description |
|----------|--------|----------|--------|-------------|
| **0x400040** | 0x00 | CTRL | R/W | Control register |
| **0x400044** | 0x04 | TXDATA | W | Transmit data register |
| **0x400048** | 0x08 | RXDATA | R | Receive data register |
| **0x40004C** | 0x0C | STATUS | R/W1C | Status register |

---

# 5. Register Access Types

| Access | Description |
|---------|-------------|
| R | Read Only |
| W | Write Only |
| R/W | Read / Write |
| R/W1C | Read / Write-One-to-Clear |

---

# 6. Register Reset Values

| Register | Reset Value |
|----------|-------------|
| CTRL | 0x00000000 |
| TXDATA | 0x00000000 |
| RXDATA | 0x00000000 |
| STATUS | 0x00000000 |

Reserved bits should always be written as zero and ignored when read.

---

# 7. SPI Transfer Characteristics

| Parameter | Value |
|-----------|-------|
| SPI Mode | Mode 0 |
| CPOL | 0 |
| CPHA | 0 |
| Transfer Width | 8 bits |
| Transfer Type | Full Duplex |
| Clock Source | System Clock |
| Clock Divider | Programmable |

The generated SPI clock frequency is

```
SCLK = System Clock / (2 × (CLKDIV + 1))
```

---

# 8. CTRL Register (Offset 0x00)

Reset Value:

```
0x00000000
```

| Bits | Name | Access | Description |
|------|------|--------|-------------|
| 0 | EN | R/W | Enables the SPI Master peripheral. |
| 1 | START | R/W | Writing 1 starts a transfer if BUSY = 0. Automatically cleared by hardware after the transfer begins. |
| 7:2 | Reserved | — | Reads as zero. |
| 15:8 | CLKDIV | R/W | SPI clock divider value. |
| 31:16 | Reserved | — | Reads as zero. |

---

# 9. TXDATA Register (Offset 0x04)

Reset Value

```
0x00000000
```

| Bits | Name | Access | Description |
|------|------|--------|-------------|
| 7:0 | DATA | W | Byte to be transmitted over MOSI. |
| 31:8 | Reserved | — | Ignored. |

Writing this register loads the transmit byte used during the next SPI transfer.

---

# 10. RXDATA Register (Offset 0x08)

Reset Value

```
0x00000000
```

| Bits | Name | Access | Description |
|------|------|--------|-------------|
| 7:0 | DATA | R | Most recently received byte from MISO. |
| 31:8 | Reserved | — | Always reads as zero. |

RXDATA is updated automatically when an SPI transfer completes successfully.

---

# 11. STATUS Register (Offset 0x0C)

Reset Value

```
0x00000000
```

| Bits | Name | Access | Description |
|------|------|--------|-------------|
| 0 | BUSY | R | Indicates an SPI transfer is currently in progress. |
| 1 | DONE | R/W1C | Indicates transfer completion. Cleared by writing 1. |
| 31:2 | Reserved | — | Reads as zero. |

BUSY and DONE are generated entirely by hardware.

---

# 12. Software Programming Sequence

A complete SPI transaction follows the sequence below.

1. Configure the SPI clock divider in CTRL.
2. Set EN = 1.
3. Write the transmit byte into TXDATA.
4. Set START = 1.
5. Poll STATUS.DONE until it becomes 1.
6. Read the received byte from RXDATA.
7. Clear DONE by writing a 1 to STATUS[1].
8. Repeat for the next transaction.

Example:

```c
SPI_CTRL = (2 << 8) | 0x01;

SPI_TXDATA = 0xA5;

SPI_CTRL = (2 << 8) | 0x03;

while(!(SPI_STATUS & (1 << 1)));

uint8_t rx = SPI_RXDATA & 0xFF;

SPI_STATUS = (1 << 1);
```

---

# 13. Register Behavior

- All registers are 32-bit and word-aligned.
- Undefined register reads return 0x00000000.
- Undefined register writes are ignored.
- START is automatically cleared after a transfer begins.
- BUSY is controlled entirely by hardware.
- DONE is asserted automatically when the transfer completes.
- DONE is cleared using a Write-One-to-Clear operation.
- START requests issued while BUSY = 1 are ignored.
- Only one SPI transfer may be active at any time.

---

# 14. Hardware Validation

The register interface was successfully verified during both RTL simulation and FPGA implementation.

Validation sequence:

1. Configure CTRL.
2. Write TXDATA = 0xA5.
3. Assert START.
4. Poll DONE.
5. Read RXDATA.
6. Verify RXDATA = 0xA5.

During FPGA validation, the MOSI and MISO pins were connected using a jumper wire to form a hardware loopback. UART messages were observed through a CP2102 USB-to-UART interface, confirming successful SPI transactions and correct register operation.

---

# 15. Known Limitations

- Supports SPI Mode 0 only.
- Supports only 8-bit transfers.
- One transfer can be active at a time.
- Software polling is required; interrupt support is not implemented.
- No transmit or receive FIFO.
- No burst transfer support.
- Chip-select is controlled automatically by hardware.

---

# 16. Summary

The SPI Master Register Map provides a simple memory-mapped programming interface for controlling SPI communication from the RISC-V processor. The four-register architecture enables software to configure the peripheral, transmit data, receive data, and monitor transfer status while maintaining a compact hardware implementation suitable for FPGA-based embedded systems.
