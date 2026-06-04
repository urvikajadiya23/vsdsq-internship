# Task: GCC vs RISC-V Output Verification 

> **Objective:** Write a simple C program, compile and run it using standard GCC to verify correctness, then cross-compile the same program using the RISC-V toolchain and simulate it using Spike — confirming that both produce identical outputs. Additionally, analyze the compiled RISC-V binary using `objdump` to study the assembly instructions and count the number of instructions in `main` based on memory addresses.

---

##  Tools & Environment

| Tool | Purpose |
|------|---------|
| GCC (x86) | Native compilation & output verification |
| `riscv64-unknown-elf-gcc` | RISC-V cross-compilation |
| Spike (`spike pk`) | RISC-V ISA simulator |
| `riscv64-unknown-elf-objdump` | Disassembly of RISC-V ELF binary |
| Leafpad / Gedit / Nano | Text editors used for writing C source |
| Oracle VirtualBox | Host environment for initial development |
| GitHub Codespaces | Cloud environment for RISC-V toolchain execution |

---

##  Project Structure

```
vsd-riscv2/
└── samples/
    ├── sum1ton.c       # C source: sum from 1 to N
    ├── 1ton_custom.c   # Custom variant
    ├── load.S          # Assembly file
    └── Makefile
```

---

##  Step 1: Writing the C Program

A simple C program `sum1ton.c` was written to compute the sum of integers from `1` to `n`.

### Source Code (`sum1ton.c`)

```c
#include <stdio.h>

int main(){
    int i, sum=0, n=9;
    for(i=1;i<=n;i++)
        sum = sum + i;
    printf("Sum from 1 to %d is %d \n", n, sum);
    return 0;
}
```

The program was initially written and tested with `n=5` on VirtualBox, then updated to `n=9` and later `n=12` during the Codespaces phase to validate the pipeline across different inputs.

**Writing and debugging `sum1ton.c` on VirtualBox using Leafpad:**

![Writing sum1ton.c on VirtualBox](screenshots/1.png)

---

##  Step 2: Compile & Run with GCC (Output Verification)

The first step was to verify the program produces the correct output using standard GCC on the host machine.

```bash
gcc sum1ton.c
./a.out
```

### Output

```
Sum from 1 to 9 is 45
```

This established the **reference output** — the expected correct result that the RISC-V simulation must match.

> **Initial run on VirtualBox** with `n=5` produced: `The sum of 5 numbers is: 15` 
> **Codespaces run** with `n=9` produced: `Sum from 1 to 9 is 45` 

**GCC compile and run on VirtualBox (`n=5`):**

![GCC Output VirtualBox](screenshots/2.png)

**GCC compile and run on Codespaces (`n=9`):**

![GCC Output Codespaces](screenshots/ss1.png)

---

##  Step 3: Cross-Compile for RISC-V & Simulate with Spike

The same source file was then cross-compiled targeting the RISC-V 64-bit architecture and run on the Spike ISA simulator using the proxy kernel (`pk`).

```bash
riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
spike pk sum1ton.o
```

### Output

```
bbl loader
Sum from 1 to 9 is 45
```

The output **matches the GCC output exactly**, confirming that the RISC-V toolchain and simulator produce correct results consistent with the native x86 GCC compilation. 

> The test was repeated with `n=12`:
> - GCC output: `Sum from 1 to 12 is 78`
> - Spike output: `Sum from 1 to 12 is 78` 

**Full session — GCC + RISC-V cross-compile + Spike simulation (`n=9`):**

![Full Codespaces Session](screenshots/ss2.png)

**Gedit showing source with `n=9`, Spike confirming match:**

![Gedit and Spike n=9](screenshots/ss3.png)

**Updated to `n=12`, Spike output matches GCC:**

![Spike n=12](screenshots/ss4.png)

---

##  Step 4: Disassembly & Instruction Count Analysis

The compiled RISC-V ELF binary was disassembled using `objdump` to inspect the generated assembly instructions.

```bash
riscv64-unknown-elf-objdump -d sum1ton.o | less
```

### Disassembly of `main` (O1 Optimization)

```
0000000000010184 <main>:
   10184:   ff010113    addi    sp,sp,-16
   10188:   00113423    sd      ra,8(sp)
   1018c:   04e00613    li      a2,78
   10190:   00c00593    li      a1,12
   10194:   00021537    lui     a0,0x21
   10198:   18050513    addi    a0,a0,384 # 21180 <__clzdi2+0x48>
   1019c:   26c000ef    jal     ra,10408 <printf>
   101a0:   00000513    li      a0,0
   101a4:   00813083    ld      ra,8(sp)
   101a8:   01010113    addi    sp,sp,16
   101ac:   00008067    ret
```

![Objdump O1 Disassembly](screenshots/ss5.png)

### Disassembly of `main` (Ofast Optimization)

```
00000000000100b0 <main>:
   100b0:   00021537    lui     a0,0x21
   100b4:   ff010113    addi    sp,sp,-16
   100b8:   04e00613    li      a2,78
   100bc:   00c00593    li      a1,12
   100c0:   18050513    addi    a0,a0,384 # 21180 <__clzdi2+0x48>
   100c4:   00113423    sd      ra,8(sp)
   100c8:   340000ef    jal     ra,10408 <printf>
   100cc:   00813083    ld      ra,8(sp)
   100d0:   00000513    li      a0,0
   100d4:   01010113    addi    sp,sp,16
   100d8:   00008067    ret
```

![Objdump Ofast Disassembly](screenshots/ss6.png)

---

##  Instruction Count Calculation

The number of instructions in `main` was determined by computing the difference between the **start address of `main`** and the **start address of the next function**, then dividing by the instruction width (4 bytes for standard RISC-V 32-bit instructions).

### For O1 Optimization

| Property | Value |
|----------|-------|
| Start address of `main` | `0x10184` |
| Start address of next function (`atexit`) | `0x101b0` |
| Byte difference | `0x101b0 - 0x10184 = 0x2C = 44 bytes` |
| Number of instructions | `44 / 4 = 11 instructions` |

### For Ofast Optimization

| Property | Value |
|----------|-------|
| Start address of `main` | `0x100b0` |
| Start address of next function (`register_fini`) | `0x100dc` |
| Byte difference | `0x100dc - 0x100b0 = 0x2C = 44 bytes` |
| Number of instructions | `44 / 4 = 11 instructions` |

> **Observation:** Both `-O1` and `-Ofast` produce the same instruction count (11) for `main` with `n=12` and `sum=78` pre-computed at compile time. The compiler statically evaluates the loop and directly loads the result — this is **constant folding** optimization. The difference between the two optimization levels is primarily in **instruction scheduling** (the order in which independent instructions are emitted), not in the instruction count itself.

---

##  Full Workflow Summary

```
Write C Program (sum1ton.c)
         │
         ▼
 GCC compile & run (x86)
  → Output: Sum = 45   (Reference)
         │
         ▼
 RISC-V Cross-compile
  riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
         │
         ▼
 Simulate with Spike
  spike pk sum1ton.o
  → Output: Sum = 45   (Matches GCC)
         │
         ▼
 Disassemble with objdump
  riscv64-unknown-elf-objdump -d sum1ton.o
         │
         ▼
 Analyze main function:
  - Identify start & end addresses
  - Compute byte range
  - Divide by 4 → Instruction count
  → 11 instructions (both O1 & Ofast)
```

---

##  Key Takeaways

- The GCC and RISC-V Spike simulation outputs **match exactly**, validating the correctness of the cross-compilation and simulation pipeline.
- The RISC-V compiler performs **constant folding** — the loop `sum = 1+2+...+n` is evaluated at compile time when `n` is a constant, so the loop body does not appear in the disassembly.
- Instruction count can be determined precisely by subtracting consecutive function start addresses in the `objdump` output and dividing by 4.
- `-O1` and `-Ofast` yield the same instruction count for this simple program, but differ in **instruction ordering** due to pipeline scheduling decisions made by the compiler.

---

##  Screenshots Reference

| # | Screenshot | Description |
|---|------------|-------------|
| ss1 | ![](screenshots/1.png) | Writing & debugging `sum1ton.c` on VirtualBox using Leafpad; initial GCC errors and fixes |
| ss2 | ![](screenshots/2.png) | Successful GCC compile and execution on VirtualBox — output: `The sum of 5 numbers is: 15` |
| ss3 | ![](screenshots/ss1.png) | Navigating to `vsd-riscv2/samples` in Codespaces; GCC compile and run — output: `Sum from 1 to 9 is 45` |
| ss4 | ![](screenshots/ss2.png) | Full Codespaces session: GCC run + RISC-V cross-compile + Spike simulation — both output `Sum from 1 to 9 is 45` |
| ss5 | ![](screenshots/ss3.png) | Gedit editor showing `sum1ton.c` with `n=9`; Spike simulation confirming match |
| ss6 | ![](screenshots/ss4.png) | Updated `n=12`; Spike output: `Sum from 1 to 12 is 78`; `cat` confirms final source |
| ss7 | ![](screenshots/ss5.png) | `objdump` disassembly — `main` section under O1 optimization with addresses |
| ss8 | ![](screenshots/ss6.png) | `objdump` disassembly — `main` section under Ofast optimization; address-based instruction count analysis |

---

