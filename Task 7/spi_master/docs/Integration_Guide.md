# SPI Master IP – Integration Guide

**Version:** 1.0  
**Target Platform:** VSDSquadron FPGA SoC  
**Date:** July 2026

---

# 1. Introduction

This document describes the integration procedure for the SPI Master IP into the VSDSquadron RISC-V SoC. It explains the RTL modifications, address mapping, software interface, FPGA pin assignments, hardware setup, and validation procedure.

The SPI Master is implemented as a memory-mapped peripheral that communicates with the RISC-V processor through the existing SoC bus interface. The design supports SPI Mode 0 (CPOL = 0, CPHA = 0) with configurable clock generation and full-duplex 8-bit transfers.

---

# 2. Integration Overview

The SPI Master IP connects directly to the SoC memory bus and is selected using address decoding logic.

The integration procedure consists of the following steps:

1. Add the SPI Master RTL module to the project.
2. Instantiate the SPI Master in the SoC top-level module.
3. Allocate a memory-mapped address range.
4. Connect the SPI read data to the processor bus.
5. Export SPI interface signals to the FPGA top level.
6. Assign FPGA pins through the constraint file.
7. Build and program the FPGA.
8. Execute the software demonstration.
9. Verify UART output and SPI loopback operation.

---

# 3. Required RTL Files

The SPI Master IP is implemented as a single RTL module.

```
spi_master.v
```

Additional project files used during integration include:

```
riscv.v
sim_main.cpp
spi_master_tb.v
spi_test.c
VSDSquadronFM.pcf
```

---

# 4. Memory Map

The SPI Master occupies a 16-byte memory window beginning at:

| Base Address | Description |
|--------------|-------------|
| **0x400040** | SPI Master IP |

The internal registers are mapped as follows.

| Address | Register | Access |
|----------|----------|--------|
| 0x400040 | CTRL | R/W |
| 0x400044 | TXDATA | W |
| 0x400048 | RXDATA | R |
| 0x40004C | STATUS | R/W |

The SoC address decoder generates the `spi_sel` signal whenever an access targets this address range.

---

# 5. Bus Interface Connections

The SPI Master interfaces directly with the processor bus.

| Signal | Direction | Description |
|---------|-----------|-------------|
| clk | Input | System clock |
| resetn | Input | Active-low reset |
| spi_sel | Input | Peripheral select |
| spi_addr[1:0] | Input | Register address |
| mem_wstrb | Input | Write enable |
| mem_wdata[31:0] | Input | CPU write data |
| spi_rdata[31:0] | Output | CPU read data |

---

# 6. External SPI Signals

The SPI Master exports the following SPI interface signals.

| Signal | Direction | Description |
|---------|-----------|-------------|
| sclk | Output | SPI Clock |
| mosi | Output | Master Out Slave In |
| miso | Input | Master In Slave Out |
| cs_n | Output | Active-Low Chip Select |

For hardware validation, the **MOSI** output was connected directly to the **MISO** input using a jumper wire to create a hardware loopback. This allows transmitted data to be received back without requiring an external SPI slave device.

The SPI interface can also be connected to external SPI peripherals such as EEPROMs, Flash memories, sensors, ADCs, and DACs.

---

# 7. FPGA Pin Assignment

The SPI interface is exported to the FPGA through the project constraint file (`VSDSquadronFM.pcf`).

```text
set_io spi_sclk_pin   9
set_io spi_mosi_pin  10
set_io spi_miso_pin  11
set_io spi_cs_n_pin  12
```

During hardware testing:

- MOSI was connected to MISO using a jumper wire.
- A CH340 USB-to-UART converter was connected to the UART interface for serial output.

This configuration enables complete hardware verification without requiring an external SPI slave.

---

# 8. Software Integration

The processor accesses the SPI Master using memory-mapped I/O.

```c
#define SPI_CTRL    (*(volatile uint32_t *)(0x400040))
#define SPI_TXDATA  (*(volatile uint32_t *)(0x400044))
#define SPI_RXDATA  (*(volatile uint32_t *)(0x400048))
#define SPI_STATUS  (*(volatile uint32_t *)(0x40004C))
```

Typical software sequence:

1. Configure CLKDIV.
2. Enable SPI.
3. Write TXDATA.
4. Set START.
5. Poll DONE.
6. Read RXDATA.
7. Clear DONE.
8. Repeat if additional transfers are required.

---

# 9. Example Transaction

Example software transaction:

```c
SPI_CTRL = (2 << 8) | 0x01;

SPI_TXDATA = 0xA5;

SPI_CTRL = (2 << 8) | 0x03;

while(!(SPI_STATUS & (1 << 1)));

uint32_t rx = SPI_RXDATA;

SPI_STATUS = (1 << 1);
```

This sequence performs one complete SPI transfer.

---

# 10. RTL Simulation Validation

The SPI Master was first verified using RTL simulation.

The simulation testbench creates a loopback by connecting MOSI directly to MISO.

```verilog
assign miso = mosi;
```

Simulation sequence:

1. Apply reset.
2. Configure CTRL register.
3. Write TXDATA = 0xA5.
4. Start SPI transfer.
5. Wait until DONE becomes 1.
6. Read RXDATA.
7. Verify RXDATA equals 0xA5.

Expected simulation output:

```text
===== SPI LOOPBACK TEST =====
Writing TXDATA = 0xA5
Starting transfer...
Received RXDATA = 0xA5
PASS
Simulation complete.
```

Successful simulation confirms:

- Correct register interface
- Proper SPI state machine operation
- Correct MOSI transmission
- Correct MISO sampling
- Proper BUSY/DONE flag operation
- Successful loopback communication

---

# 11. Hardware Validation

After RTL verification, the SPI Master IP was integrated into the VSDSquadron RISC-V SoC and programmed onto the FPGA.

Build commands:

```bash
make build
make flash
```

Hardware setup:

- VSDSquadron FPGA Board
- Cp2102 USB-to-UART module
- MOSI-to-MISO jumper wire

Hardware connection:

```
              VSDSquadron FPGA

       +----------------------------+

 MOSI ----------------------------+
                                   |
                                   |
 MISO <----------------------------+

 SCLK ----------------------------->

 CS_N ------------------------------>

 UART TX --------------------------> CH340 RX

 UART RX <-------------------------- CH340 TX

 GND ------------------------------ GND
```

The demonstration software performs the following operations:

1. Configures the SPI clock divider.
2. Enables the SPI Master.
3. Writes 0xA5 into TXDATA.
4. Starts the SPI transfer.
5. Polls the DONE flag.
6. Reads RXDATA.
7. Verifies the received byte.
8. Prints the received value through UART.
9. Toggles the onboard RGB LEDs continuously to indicate successful execution.

Expected UART output:

```text
===== SPI LOOPBACK TEST =====
Writing TXDATA = 0xA5
Starting transfer...
Received RXDATA = 0xA5
PASS
```

The LEDs continue blinking after the successful SPI transaction, confirming that the processor continues executing the application after the SPI transfer completes.

Successful hardware validation confirms:

- Correct processor-to-SPI communication
- Correct register read/write operations
- Successful SPI transmission
- Successful SPI reception through MOSI-to-MISO loopback
- Correct BUSY and DONE flag operation
- Successful UART communication through CH340
- Successful integration of the SPI Master IP into the VSDSquadron SoC

---

# 12. Integration Notes

- Supports SPI Mode 0 only.
- Supports only 8-bit transfers.
- Only one transfer can be active at a time.
- START requests while BUSY is asserted are ignored.
- START automatically clears after a transfer begins.
- BUSY and DONE are generated by hardware.
- DONE is cleared using a write-one-to-clear operation.
- Undefined register writes are ignored.
- Undefined register reads return zero.

---

# 13. Directory Structure

```
spi_master/
├── RTL/
│   └── spi_master.v
├── software/
│   └── spi_test.c
├── docs/
│   ├── IP_User_Guide.md
│   ├── Register_Map.md
│   ├── Integration_Guide.md
│   └── Example_Usage.md
├── screenshots 
└── README.md
```

---

# 14. Summary

The SPI Master IP was successfully integrated into the VSDSquadron RISC-V SoC as a memory-mapped peripheral supporting SPI Mode 0 communication. The design was validated through RTL simulation using a MOSI-to-MISO loopback and subsequently verified on FPGA hardware using a jumper-wire loopback and a CP2102 USB-to-UART interface. The successful transmission and reception of the test byte (0xA5), UART output, and continuous RGB LED activity confirm the correct functionality of the SPI Master IP and its integration with the RISC-V processor.
