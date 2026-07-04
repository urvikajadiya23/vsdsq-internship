# SPI Master IP – Register Map

## Overview

The SPI Master IP is a memory-mapped peripheral integrated into the **VSDSquadron RISC-V SoC**. It implements a minimal **SPI Mode 0 (CPOL = 0, CPHA = 0)** master capable of performing single-byte (8-bit) full-duplex data transfers. The peripheral is controlled through a simple memory-mapped register interface, allowing software to configure the SPI clock, initiate transfers, and monitor transfer status.

**Base Address:** `0x400040`

All registers are **32-bit**, **word-aligned**, and accessed through the processor's memory-mapped bus interface. Register addresses are calculated as:

```
Register Address = Base Address + Register Offset
```

---

## Feature Summary

- SPI Mode 0 (CPOL = 0, CPHA = 0)
- Full-duplex 8-bit data transfer
- Programmable SPI clock divider
- Memory-mapped 32-bit register interface
- Hardware-controlled BUSY and DONE status flags
- Supports one transfer at a time
- Internal MOSI-to-MISO loopback for validation
- Compatible with the VSDSquadron RISC-V SoC

---

## Register Summary

| Address | Offset | Register | Access | Description |
|:--------:|:------:|:--------:|:------:|-------------|
| `0x400040` | `0x00` | CTRL | R/W | Control register (Enable, Start, Clock Divider) |
| `0x400044` | `0x04` | TXDATA | R/W | Transmit data register |
| `0x400048` | `0x08` | RXDATA | R | Receive data register |
| `0x40004C` | `0x0C` | STATUS | R/W1C | Transfer status register |

---

## Register Access Types

| Access | Description |
|---------|-------------|
| **R** | Read Only |
| **W** | Write Only |
| **R/W** | Read and Write |
| **R/W1C** | Read, Write-One-to-Clear |

---

## Register Reset Values

| Register | Reset Value |
|-----------|-------------|
| CTRL | `0x00000000` |
| TXDATA | `0x00000000` |
| RXDATA | `0x00000000` |
| STATUS | `0x00000000` |

Reserved bits should always be written as **0** and ignored on read.

---

## Transfer Characteristics

| Parameter | Value |
|-----------|-------|
| SPI Mode | Mode 0 (CPOL = 0, CPHA = 0) |
| Transfer Length | 8 bits |
| Transfer Type | Full Duplex |
| Clock Source | System Clock |
| Clock Divider | Programmable (`CLKDIV`) |

The SPI clock frequency is calculated as:

```
SCLK Frequency = System Clock Frequency / (2 × (CLKDIV + 1))
```

---

## CTRL Register (Offset: 0x00)

**Reset Value:** `0x00000000`

| Bits | Field | Access | Description |
|------|-------|--------|-------------|
| 0 | EN | R/W | Enables the SPI Master. This bit must be set before initiating a transfer. |
| 1 | START | R/W | Writing **1** initiates an SPI transfer when **EN = 1** and **BUSY = 0**. The START bit is automatically cleared by hardware after the transfer begins. |
| 7:2 | Reserved | - | Reserved. Reads return 0. |
| 15:8 | CLKDIV | R/W | SPI clock divider. Determines the generated SPI clock frequency. |
| 31:16 | Reserved | - | Reserved. Reads return 0. |

---

## TXDATA Register (Offset: 0x04)

**Reset Value:** `0x00000000`

| Bits | Field | Access | Description |
|------|-------|--------|-------------|
| 7:0 | DATA | R/W | Software writes the transmit byte before initiating an SPI transfer. |
| 31:8 | Reserved | - | Reserved. Reads return 0. |

---

## RXDATA Register (Offset: 0x08)

**Reset Value:** `0x00000000`

| Bits | Field | Access | Description |
|------|-------|--------|-------------|
| 7:0 | DATA | R | Holds the most recently received byte after completion of an SPI transfer. |
| 31:8 | Reserved | - | Always reads as 0. |

---

## STATUS Register (Offset: 0x0C)

**Reset Value:** `0x00000000`

| Bits | Field | Access | Description |
|------|-------|--------|-------------|
| 0 | BUSY | R | Asserted by hardware while an SPI transfer is in progress. Cleared automatically when the transfer completes. |
| 1 | DONE | R/W1C | Set by hardware when an SPI transfer completes successfully. Cleared by writing **1** to this bit. |
| 31:2 | Reserved | - | Reserved. Reads return 0. |

---

## Software Programming Sequence

A typical SPI transaction is performed as follows:

1. Write the transmit byte to **TXDATA**.
2. Configure the **CTRL** register:
   - Set **EN = 1**
   - Program the required **CLKDIV** value.
3. Set **START = 1** to begin the transfer.
4. Poll **STATUS.DONE** until it becomes **1**.
5. Read the received byte from **RXDATA**.
6. Clear **DONE** by writing **1** to `STATUS[1]`.

> **Note:** The SPI Master performs one 8-bit transfer for each START command. Software must wait until **DONE = 1** before initiating another transfer.

---

## Register Behavior

- All registers are **32-bit** and **word-aligned**.
- Reads from undefined register offsets return **0x00000000**.
- Writes to undefined register offsets are ignored.
- **BUSY** is controlled entirely by hardware and cannot be modified by software.
- **DONE** uses **Write-One-to-Clear (W1C)** semantics.
- **START** is automatically cleared by hardware after the transfer begins.
- START requests issued while **BUSY = 1** are ignored.

---

## Known Limitations

- Supports only **SPI Mode 0 (CPOL = 0, CPHA = 0)**.
- Supports **fixed 8-bit transfers** only.
- Only **one SPI transfer** can be active at any given time.
- No interrupt support; software must poll the **DONE** flag.
- Chip Select (**CS_N**) is automatically controlled by hardware.
- Current VSDSquadron integration uses **internal MOSI-to-MISO loopback** for validation.

---


