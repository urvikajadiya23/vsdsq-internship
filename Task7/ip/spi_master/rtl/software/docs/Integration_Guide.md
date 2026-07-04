# SPI Master IP – Integration Guide

**Version:** 1.0  
**Target Platform:** VSDSquadron FPGA SoC  
**Date:** July 2026

---

# 1. Introduction

This document describes the integration procedure for the SPI Master IP into the VSDSquadron RISC-V SoC. It explains the required RTL modifications, address mapping, software interface, FPGA pin assignments, and validation procedure.

The SPI Master is implemented as a memory-mapped peripheral and communicates with the processor through the existing SoC bus interface.

---

# 2. Integration Overview

The SPI Master IP connects directly to the SoC memory bus and is selected through address decoding.

The integration consists of the following steps:

1. Add the SPI Master RTL module to the project.
2. Instantiate the SPI Master inside the SoC top-level module.
3. Decode the assigned SPI address range.
4. Connect the SPI read data to the processor bus.
5. Export the SPI interface signals to the FPGA top level.
6. Assign FPGA pins through the constraint file.
7. Program the FPGA and execute the software demonstration.

---

# 3. Required RTL Files

The following RTL file is required:

```
spi_master.v
```

No additional RTL modules are required.

---

# 4. Memory Map

The SPI Master occupies a 16-byte memory window beginning at:

| Base Address | Description |
|--------------|-------------|
| **0x400040** | SPI Master IP |

The processor accesses the internal registers using the following offsets.

| Address | Register |
|----------|----------|
| 0x400040 | CTRL |
| 0x400044 | TXDATA |
| 0x400048 | RXDATA |
| 0x40004C | STATUS |

Address decoding inside the SoC generates the `spi_sel` signal whenever an access falls within this address range.

---

# 5. Bus Interface Connections

The SPI Master connects to the existing processor bus using the following signals.

| Signal | Direction | Description |
|---------|-----------|-------------|
| clk | Input | System clock |
| resetn | Input | Active-low system reset |
| spi_sel | Input | Address decoder select |
| spi_addr[1:0] | Input | Register offset |
| mem_wstrb | Input | Write enable |
| mem_wdata[31:0] | Input | Processor write data |
| spi_rdata[31:0] | Output | Read data returned to CPU |

---

# 6. External SPI Signals

The SPI Master exports the following signals to the FPGA top level.

| Signal | Direction | Description |
|---------|-----------|-------------|
| sclk | Output | SPI Serial Clock |
| mosi | Output | Master Out Slave In |
| miso | Input | Master In Slave Out |
| cs_n | Output | Active-Low Chip Select |

These signals may be connected to an external SPI peripheral or used for loopback testing.

---

# 7. FPGA Pin Assignment

The SPI interface is mapped to the VSDSquadron FPGA pins using the project constraint file (`VSDSquadronFM.pcf`).

```text
set_io spi_sclk_pin 9
set_io spi_mosi_pin 10
set_io spi_cs_n_pin 12
```

The current implementation performs validation using an internal MOSI-to-MISO loopback connection inside the RTL/test environment. Therefore, an external SPI slave device is not required for functional verification.

---

# 8. Software Integration

Software accesses the SPI Master using memory-mapped I/O.

```c
#define SPI_CTRL   (*(volatile uint32_t *)(0x400040))
#define SPI_TXDATA (*(volatile uint32_t *)(0x400044))
#define SPI_RXDATA (*(volatile uint32_t *)(0x400048))
#define SPI_STATUS (*(volatile uint32_t *)(0x40004C))
```

The basic software sequence is:

1. Configure the clock divider.
2. Enable the SPI Master.
3. Write the transmit byte.
4. Set the START bit.
5. Poll the DONE flag.
6. Read the received byte.
7. Clear the DONE flag before initiating another transfer.

---

# 9. Example Transaction

The following example transmits the byte `0xA5`.

```c
SPI_CTRL = (1 << 0) | (2 << 8);

SPI_TXDATA = 0xA5;

SPI_CTRL |= (1 << 1);

while (!(SPI_STATUS & (1 << 1)));

uint32_t data = SPI_RXDATA;
```

This software sequence is included in the project demonstration application.

---

# 10. Simulation Validation

RTL functionality was verified using the supplied Verilog testbench before hardware integration.

The simulation environment uses a loopback configuration by connecting the SPI Master's **MOSI** output directly to its **MISO** input:

```verilog
assign miso = mosi;
```

This configuration emulates a simple SPI slave, allowing transmitted data to be received back without requiring additional SPI devices.

The simulation procedure is as follows:

1. Apply system reset.
2. Configure the CTRL register with the desired clock divider.
3. Write `0xA5` to the TXDATA register.
4. Initiate an SPI transfer by setting the START bit.
5. Wait for the transfer to complete.
6. Read the STATUS register.
7. Read the RXDATA register.
8. Verify that the received byte matches the transmitted byte.

A successful simulation produces the following result:

```text
=== SPI Master Testbench ===
Writing CTRL register...
Writing TXDATA = 0xA5...
Starting SPI transfer...
Waiting for transfer to complete...
Reading STATUS...
Reading RXDATA...
PASS: RXDATA == 0xA5
=== Simulation Done ===
```

This confirms the correct operation of the register interface, SPI state machine, data shifting logic, and receive path.

---

# 11. Hardware Validation

The SPI Master IP was successfully integrated into the VSDSquadron RISC-V SoC and programmed onto the VSDSquadron FPGA using the standard build flow.

```bash
make build
make flash
```

For FPGA validation, the SPI Master was configured with an **internal MOSI-to-MISO loopback connection** within the SoC design. This allows transmitted SPI data to be internally routed back to the receive path, eliminating the need for an external SPI slave device or jumper wire during hardware testing.

Software running on the RISC-V processor accesses the SPI Master through its memory-mapped register interface located at base address **0x400040**. The demonstration application performs the following operations:

1. Enables the SPI Master.
2. Configures the SPI clock divider.
3. Writes the transmit byte (`0xA5`) to the TXDATA register.
4. Initiates an SPI transfer.
5. Polls the DONE status flag.
6. Reads the received byte from the RXDATA register.
7. Prints the received value over the UART interface.

The expected UART output is similar to:

```text
SPI TEST START
RX = 0x000000A5
SPI TEST DONE
```

Successful execution confirms:

- Correct memory-mapped register access
- Successful SPI transmission
- Correct SPI reception through the internal loopback path
- Proper operation of the BUSY and DONE status flags
- Successful end-to-end integration of the SPI Master IP within the VSDSquadron RISC-V SoC

# 12. Integration Notes

- The SPI Master supports only one active transfer at a time.
- START requests issued while BUSY is asserted are ignored.
- Undefined register accesses return zero.
- Undefined write operations are ignored.
- The START bit is automatically cleared by hardware after a transfer begins.
- BUSY and DONE are generated entirely by hardware.

---

# 13. Directory Structure

```
ip/
└── spi_master/
    ├── rtl/
    │   └── spi_master.v
    ├── software/
    │   └── spi_test.c
    ├── test/
    │   └── spi_master_tb.v
    ├── docs/
    │   ├── IP_User_Guide.md
    │   ├── Register_Map.md
    │   ├── Integration_Guide.md
    │   └── Example_Usage.md
    └── README.md
```
