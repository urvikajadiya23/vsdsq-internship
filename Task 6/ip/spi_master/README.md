# Task-4: Real Peripheral IP Development - SPI Master IP (Minimal, Single-Byte, Mode 0)

## Overview

This IP implements a minimal SPI Master peripheral for the `basicRISCV`
(femtorv32-based) SoC running on the VSDSquadron FM board (iCE40UP5K FPGA).
It supports single-byte, Mode 0 (CPOL=0, CPHA=0) transfers, memory-mapped
into the SoC's IO address space.

- **RTL:** `spi_master.v`
- **Integration:** `riscv.v` (SOC module)
- **Firmware:** `spi_test.c`
- **Testbench:** `spi_master_test.v`

---

## Step 1: Planning — Register Map & Block Diagram

Working directory:

![Directory](screenshots/ss1_directory.png)

**SPI Base Address = `0x400030`**

| Offset | Register | Description            |
|--------|----------|-------------------------|
| 0x00   | CTRL     | Enable, Start, Clock Divider |
| 0x04   | TXDATA   | Transmit byte           |
| 0x08   | RXDATA   | Received byte           |
| 0x0C   | STATUS   | Busy and Done flags     |

![Register map](screenshots/ss2_add_plan.png)

Block-level structure — CPU connects through the memory bus and address
decoder into the SPI Master, which contains the register bank, shift
register, clock divider, and control FSM, driving the physical `CS`,
`SCLK`, `MOSI`, and `MISO` signals:

![Block diagram](screenshots/ss3_structure.png)

---

## Step 2: Create `spi_master.v`

![Create file](screenshots/ss4_file_created.png)

---

## Step 3: RTL Implementation

### Module declaration and register bank

`SPI_MASTER` exposes a standard memory-mapped bus interface
(`spi_sel`, `spi_addr`, `mem_wstrb`, `mem_wdata`, `spi_rdata`) plus the
four SPI pins (`sclk`, `mosi`, `miso`, `cs_n`).

![Module + registers](screenshots/ss5_cat.png)

### Register write logic and read mux

- `CTRL` (offset `2'b00`) and `TXDATA` (offset `2'b01`) are written
  directly from the bus.
- `STATUS` (offset `2'b11`) supports write-1-to-clear on the `DONE` bit
  (`mem_wdata[1]`).
- `RXDATA` (offset `2'b10`) is read-only — no write case exists for it.
- The `START` bit (`ctrl_reg[1]`) auto-clears once a transfer begins
  (`en && start && !busy`).
- The read mux returns the correct register for each offset, and `32'd0`
  for undefined offsets, per spec.

![Write logic + read mux](screenshots/ss5_cat_b.png)

Read mux default case (returns 0 when `spi_sel` is low):

![Read mux default](screenshots/ss5_cat_c.png)

### Transfer FSM (Mode 0)

On `en && start && !busy`:
- `cs_n` is pulled low, `busy` is set, `tx_shift` is loaded from
  `tx_reg[7:0]`, and the first MOSI bit (`tx_reg[7]`) is driven out.

While `busy`, on each clock-divider tick (`clk_count == clkdiv`):
- `sclk` toggles.
- **MISO is sampled** on the edge where `sclk` is about to go high
  (rising-edge sample), shifting into `rx_shift`.
- **MOSI is shifted out** on the falling edge (`tx_shift` advances).

![FSM start + sampling](screenshots/ss5_cat_d.png)

On `bit_count == 4'd7` (8th bit complete):
- `busy` clears, `done` and `STATUS.DONE` are set, `cs_n` returns high,
  `sclk` returns low, and the final received byte is latched into
  `rx_reg`.

![FSM completion + endmodule](screenshots/ss6.png)

---

## Step 4: SoC Integration (`riscv.v`)

### IO address decode

Added `IO_SPI_bit = 4` to the existing 1-hot IO address decode scheme
(alongside LEDS, UART, GPIO):

![IO_SPI_bit](screenshots/ss7_spi_addr.png)

### Instantiation

`spi_sel` is derived the same way as the other peripherals
(`isIO & mem_wordaddr[IO_SPI_bit]`), and `SPI_MASTER` is instantiated as
`spi_ip`, wired to the CPU's memory bus signals:

![Instantiation](screenshots/ss8_instantiate_ip.png)

### Read-data mux

`spi_rdata_wire` is added as a new arm of the SoC-level `IO_rdata` mux,
alongside UART and GPIO:

![IO_rdata mux](screenshots/ss9_spi_to_cpu.png)

### Clockworks

Standard gearbox/reset instantiation:

![Clockworks](screenshots/ss11_clockwork.png)

### Simulation loopback for MISO

Under `BENCH`, `spi_miso` is tied directly to `spi_mosi` to emulate a
loopback connection during simulation, satisfying the spec's
"MISO loopback" validation requirement:

![MISO loopback](screenshots/ss12_.png)

---

## Step 5: Verilator Testbench Harness

Standard `sim_main.cpp` Verilator harness — drives `CLK`/`RESET`, then
runs the simulation for a fixed number of clock edges:

![sim_main.cpp](screenshots/ss12_clk_changes.png)

---

## Step 6: Firmware — `spi_test.c`

Full firmware source. Memory-mapped register addresses match the SoC's
`IO_BASE + offset` scheme:

- `SPI_CTRL` = `0x400040`
- `SPI_TXDATA` = `0x400044`
- `SPI_RXDATA` = `0x400048`
- `SPI_STATUS` = `0x40004C`

![spi_test.c full](screenshots/ss14_spi_test_c.png)

The test:
1. Prints `"SPI TEST START"` over UART.
2. Configures `SPI_CTRL` with `EN=1` and `CLKDIV=2`.
3. Writes `0xA5` to `SPI_TXDATA`.
4. Sets the `START` bit.
5. Polls `SPI_STATUS` bit 1 (`DONE`).
6. Reads back `SPI_RXDATA` and prints it in hex over UART.

![spi_test.c — poll/print tail](screenshots/ss14_b.png)

### Building the firmware

Compiled with the standard `riscv64-unknown-elf` toolchain into an ELF,
then linked against the board's `bram.ld`:

![Build spi_test firmware](screenshots/ss15_test.png)

Converted to a BRAM-loadable hex image with `firmware_words`:

```
RAM SIZE = 6144
LOAD ELF: spi_test.bram.elf   max address = 3001
Code size: 750 words (total RAM size: 1536 words)
Occupancy: 48%
SAVE HEX: spi_test.hex
```

![firmware_words hex generation](screenshots/ss16_hex.png)

`spi_test.hex` is copied into `RTL/firmware.hex` before synthesis/sim,
so the CPU's BRAM is initialized with this exact program.

---

## Step 7: Simulation Results

### 7a. Standalone IP-level testbench (`spi_master_test.v`)

A self-checking testbench instantiates `SPI_MASTER` directly (not the
full SoC), ties `miso = mosi` for loopback, and provides a `write_reg`
task to drive the bus:

![Testbench — module + write_reg task](screenshots/ss18_tb_a.png)

Sequence: write `CTRL = 0x201` (EN=1, CLKDIV=2) → write `TXDATA = 0xA5`
→ write `CTRL = 0x203` (START=1) → wait → read `STATUS` → read `RXDATA`
→ self-check `RXDATA == 0xA5`:

![Testbench — sequence + self-check](screenshots/ss18_tb_b.png)

### 7b. Icarus Verilog run

```
$ iverilog -o spi_sim spi_master_test.v spi_master.v
$ vvp spi_sim

=== SPI Master Testbench ===
Writing CTRL register...
Writing TXDATA = 0xA5...
Starting SPI transfer...
Waiting for transfer to complete...
Reading STATUS...
STATUS = 0x00000002
Reading RXDATA...
RXDATA = 0x000000a5
PASS: RXDATA == 0xA5
=== Simulation Done ===
```

![Icarus run — PASS](screenshots/ss19_iverilog.png)

`STATUS = 0x00000002` confirms `BUSY=0`, `DONE=1` — correct final state.
`RXDATA` exactly matches the transmitted byte under loopback, confirming
correct Mode 0 shift/sample timing.

### 7c. GTKWave waveform

`bit_count` advances 0→8 across the transfer; `tx_shift` shifts out
`A5 → 4A → 94 → 28 → 50 → A0 → 40 → 80` (MSB-first); `rx_shift`
accumulates up to the final value `A5`; `busy` is high for the full
transfer window, `cs_n` is low during the transfer:

![GTKWave waveform](screenshots/ss20_gtkwave.png)

![GTKWave reload / session log](screenshots/ss21_gtk.png)

### 7d. Full-SoC Verilator simulation

`make sim` builds the complete SoC (`riscv.v` + `spi_master.v` +
`sb_hfosc_stub.v` + `sim_main.cpp`), running the actual `spi_test.c`
firmware on the CPU end-to-end through the memory bus and address
decoder — not just the isolated IP:

```
Simulation started...
SPI TEST START  RX = 0x000000A5
SPI TEST DONE   Simulation complete.
```

![Full-SoC Verilator simulation](screenshots/ss17_make_sim.png)

This confirms the SPI Master works correctly through the full SoC
integration path: CPU → bus → address decode → `SPI_MASTER` → loopback
→ firmware read-back — matching the standalone IP-level result exactly.

---

## Step 8: Hardware Validation

End-to-end flow for getting the SPI Master IP onto the VSDSquadron FM board: SOC port wiring → pin constraints → loopback → simulation check → build → flash → UART validation.

---

##  Adding SPI Ports to the SOC Module

The top-level `SOC` module port list was extended with the three SPI hardware pins, alongside the existing UART and LED ports:

```verilog
module SOC (
`ifdef BENCH
  input             CLK,      // system clock
`endif
  input             RESET,    // reset button
  output reg [4:0]  LEDS,     // system LEDs
  input             RXD,      // UART receive
  output            TXD,      // UART transmit
  output            spi_sclk_pin,  // SPI clock (hardware pin)
  output            spi_mosi_pin,  // SPI MOSI
  output            spi_cs_n_pin   // SPI chip-select (hardware pin)
);
```

Note `spi_miso_pin` isn't in this list — MISO is handled internally via loopback rather than as an external pin (see Step 3).

![SOC module port list with SPI pins added](screenshots/s23_modify_SOC.png)

---

##  Adding SPI Pins to the PCF

The corresponding physical pin numbers were appended to `VSDSquadronFM.pcf`:

```bash
cat >> VSDSquadronFM.pcf << 'EOF'
set_io  spi_sclk_pin 9
set_io  spi_mosi_pin 10
set_io  spi_cs_n_pin 12
EOF
```

**Fixing a stray edit:** the append left `RXD 3` and `set_io spi_sclk_pin 9` glued onto one line (missing newline before the heredoc). Fixed with:

```bash
sed -i 's/RXD 3set_io/RXD 3\nset_io/' VSDSquadronFM.pcf
```

Final `VSDSquadronFM.pcf` correctly lists `RXD 3` on its own line, followed by the three SPI pin assignments each on their own line.

![PCF pin constraint edit](screenshots/ss22_modifying_pcf.png)

---

## Internal MISO Loopback (Top-Level Wiring)

No external jumper wire is available on this setup, so `spi_miso` is tied directly to `spi_mosi` **inside the FPGA fabric**, alongside the normal pin assignments:

```verilog
assign spi_sclk_pin  = spi_sclk;
assign spi_mosi_pin  = spi_mosi;
assign spi_cs_n_pin  = spi_cs_n;

// Internal loopback (no physical jumper wire available):
// MISO is tied to MOSI inside the FPGA fabric itself, so the
// hardware test exercises the real SPI_MASTER FSM/shift logic
// on silicon, without requiring an external MOSI->MISO jumper.
assign spi_miso = spi_mosi;
```

This still exercises the real SPI Master FSM and shift-register logic on real hardware — it just avoids relying on a physical wire for the loopback path.

![Internal loopback wiring](screenshots/ss23_modification.png)

---

##  Simulation Sanity Check (Pre-Hardware)

Before flashing, `make sim` was re-run to confirm the RTL was still functionally correct after the port/pin/wiring changes:

```bash
make sim
```

Output confirmed the loopback test passes at the simulation level:

```
Simulation started...
SPI TEST START
RX = 0x000000A5
SPI TEST DONE. Simulation complete.
```

`RX = 0xA5` matches the byte written to `TXDATA`, confirming the shift logic and loopback path are correct before moving to the board.

![Simulation still passing after wiring changes](screenshots/ss24_sim_intact.png)

---

##  Adding the IP to the Build (Makefile)

`spi_master.v` was added alongside `riscv.v` in the Makefile's `VERILOG_FILE` list so every downstream target (`build`, `sim`) compiles them together:

```makefile
VERILOG_FILE= riscv.v spi_master.v
```

![Makefile edit](screenshots/ss25_adding_to_makefile.png)

---

##  Synthesis, Place & Route, and Timing Analysis

```bash
make build
```

This runs Yosys synthesis → nextpnr-ice40 place & route → icetime static timing analysis → icepack bitstream packing.

**Result:** timing closed comfortably — max clock frequency came out to **17.24 MHz**, well above the 12 MHz constraint (PASS). One harmless warning was reported for the HFOSC cell (expected — it's not a timing-analyzable path).

```
Info: Max frequency for clock 'clk': 17.24 MHz (PASS at 12.00 MHz)
...
1 warning, 0 errors
Info: Program finished normally.
```

![make build output — timing PASS at 17.24 MHz](screenshots/ss26_make_build.png)

---

##  Flashing the Bitstream

```bash
make flash
```

**First attempt failed** with a USB permissions error:

```
Can't find iCE FTDI USB device (vendor_id 0x0403, device_id 0x6010 or 0x6014).
ABORT.
```

**Fix:** re-ran with `sudo`:

```bash
sudo make flash
```

This succeeded cleanly:

```
flash ID: 0xEF 0x40 0x16 0x00
programming..
done.
reading..
VERIFY OK
cdone: high
Bye.
```

`cdone: high` at both start and end confirms the FPGA configured successfully from the newly written bitstream.

![sudo make flash — VERIFY OK](screenshots/ss27_make_flash.png)

---

##  UART Terminal Validation (Unresolved)

```bash
sudo make terminal
```

`picocom` connected cleanly to `/dev/ttyUSB0` at 9600 baud and reported "Terminal ready" — but **no UART output ever appeared**, even after the SPI test firmware should have printed its TX/RX comparison.

![picocom connected, port open, no output](screenshots/ss28.png)

### Debugging steps already tried

| Fix attempted | Result |
|---|---|
| RESET line pull-up | No change |
| DTR / `--noreset` picocom flag | No change |
| USB reattachment (detach/reattach in VirtualBox) | Device re-enumerates correctly, still silent |
| Clean re-flash before each terminal attempt | Flash is consistently `VERIFY OK` |
| Re-checking baud rate / device path | Confirmed correct (`9600`, `/dev/ttyUSB0`) |

Every flash cycle reports a clean `VERIFY OK`, and `cdone: high` confirms the FPGA is configured — so the SPI Master IP and bitstream aren't obviously at fault. The failure is isolated specifically to the UART data path.

**Current assessment:** likely a board-level or VM-passthrough issue rather than an RTL/software one — a cold solder joint, a genuine board defect on the UART/USB data path, or a VirtualBox USB serial quirk. Ruling this out needs the physical board on bare-metal hardware (or a different host/OS), ideally with a multimeter/scope on the TX pin to confirm whether the FPGA is driving it at all.

![VSDSquadron FM board — powered, PWR LED on](screenshots/ss29_board.jpeg)

---

## Brief description of the task


---

