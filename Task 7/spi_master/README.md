# Task 7: Commercial-Grade SPI Master IP

A lightweight, memory-mapped **SPI Master IP** designed for the **VSDSquadron RISC-V SoC**. The IP implements **SPI Mode 0 (CPOL = 0, CPHA = 0)** and supports **8-bit full-duplex SPI communication** with a programmable serial clock.

---

## Features

- Memory-mapped 32-bit register interface
- SPI Mode 0 (CPOL = 0, CPHA = 0)
- 8-bit full-duplex transfers
- Programmable SPI clock divider
- Hardware-controlled BUSY and DONE flags
- Automatic Chip Select (CS_N) generation
- Integrated into the VSDSquadron RISC-V SoC

---

## Memory Map

**Base Address:** `0x400040`

| Register | Offset |
|----------|--------|
| CTRL | `0x00` |
| TXDATA | `0x04` |
| RXDATA | `0x08` |
| STATUS | `0x0C` |

---

## Integration

Integrating the SPI Master IP into the SoC requires only a few steps:

1. Add `rtl/spi_master.v` to the RTL project.
2. Instantiate the SPI Master inside the SoC.
3. Decode address **0x400040** to generate `spi_sel`.
4. Connect the processor bus signals:
   - `clk`
   - `resetn`
   - `spi_addr`
   - `mem_wstrb`
   - `mem_wdata`
   - `spi_rdata`
5. Connect the SPI interface:
   - `sclk`
   - `mosi`
   - `miso`
   - `cs_n`

Complete integration details are available in **docs/Integration_Guide.md**.

---

## Documentation

The complete documentation is located in the **docs/** directory.

| Document | Description |
|----------|-------------|
| **IP_User_Guide.md** | Architecture, functionality and operating principle |
| **Register_Map.md** | Register descriptions and programming model |
| **Integration_Guide.md** | RTL integration, address decoding and FPGA implementation |
| **Example_Usage.md** | Complete software example and validation procedure |

---

## Testing

### RTL Simulation

The supplied firmware performs an SPI loopback transfer by transmitting **0xA5** and verifying the received byte.

Expected console output:

```text
===== SPI LOOPBACK TEST =====
Writing TXDATA = 0xA5
Starting transfer...
Received RXDATA = 0xA5
PASS
```

---

### FPGA Validation

Program the FPGA using:

```bash
make build
make flash
```

After connecting the CH340 UART interface and SPI loopback wiring (MOSI ↔ MISO), the firmware performs the same SPI transfer on hardware and reports the received byte over UART.

Expected UART output:

```text
===== SPI LOOPBACK TEST =====
Writing TXDATA = 0xA5
Starting transfer...
Received RXDATA = 0xA5
PASS
```

---

## Project Structure

```text
spi_master/
├── rtl/
│   └── spi_master.v
├── software/
│   └── spi_test.c
├── docs/
│   ├── IP_User_Guide.md
│   ├── Register_Map.md
│   ├── Integration_Guide.md
│   └── Example_Usage.md
├── screenshots/
│   ├── step3_a.png
│   ├── step3_b.png
│   ├── step3_c.png
│   ├── step3_d.png
│   ├── ss20_gtkwave.png
│   ├── ss27_make_flash.png
│   └── board.png
└── README.md
```

---

## License

Developed as part of the **VSDSquadron FPGA IP Development Program**.
