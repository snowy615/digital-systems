# Digital Systems — Comprehensive Exam Study Guide

Oxford, Hilary + Trinity Term. Source priority: lecture slides (L1-15, L17, L18, L20, L21, L23), problem sheets (prob1-new, prob2-6), labs (lab0-lab4) + source tree `digisys-labs-src/`, then notes PDF only for gap-fills.

Conventions used throughout:
- Hex is `0x…`. Binary is `0b…`. Decimal has no prefix.
- Register names are lower case: `r0`, `sp`, `lr`, `pc`, `psr`.
- "Thumb" = the 16-bit ARMv6-M instruction set the Cortex-M0 executes.
- "Cortex-M0" is the CPU core; "nRF51822" is the Nordic chip that wraps it with peripherals.

---

## Table of Contents

1. [ARM Cortex-M0 Assembly & Architecture](#part-1-arm-cortex-m0-assembly--architecture)
   - 1.1 Registers and PSR flags
   - 1.2 Memory map, endianness, alignment
   - 1.3 Thumb instruction set (complete reference)
   - 1.4 Addressing modes
   - 1.5 Condition codes and branches
   - 1.6 AAPCS calling convention
   - 1.7 Stack frames, push/pop, leaf vs non-leaf
   - 1.8 Assembler directives and pseudo-ops
   - 1.9 Literal pool and `ldr =label`
   - 1.10 Startup code and vector table
   - 1.11 Toolchain (gcc/as/ld/objcopy/objdump/gdb)
   - 1.12 Exam traps
2. [C for Embedded Systems](#part-2-c-for-embedded-systems)
3. [micro:bit / nRF51 Peripherals](#part-3-microbit--nrf51-peripherals)
4. [Interrupts, Exceptions, and MicrobiΛn](#part-4-interrupts-exceptions-and-microbi%CE%BBn)
5. [Digital Logic](#part-5-digital-logic)
6. [CPU Architecture & Datapath](#part-6-cpu-architecture--datapath)
7. [Problem Sheet Patterns](#problem-sheet-patterns)
8. [Lab Takeaways](#lab-takeaways)
9. [Quick-reference cheat-sheets](#quick-reference-cheat-sheets)

---

# Part 1: ARM Cortex-M0 Assembly & Architecture

## 1.1 Registers and PSR flags

### Register file (all 32-bit)

| Reg  | Alt name | Role                                                                |
|------|----------|---------------------------------------------------------------------|
| r0   | a1       | Arg 1 / return value                                                |
| r1   | a2       | Arg 2 / return (high half for 64-bit)                               |
| r2   | a3       | Arg 3 / scratch                                                     |
| r3   | a4       | Arg 4 / scratch                                                     |
| r4   | v1       | Callee-saved variable                                               |
| r5   | v2       | Callee-saved variable                                               |
| r6   | v3       | Callee-saved variable                                               |
| r7   | v4       | Callee-saved variable                                               |
| r8   | v5       | Callee-saved, "high" register (fewer instructions reach it)         |
| r9   | v6       | Callee-saved                                                        |
| r10  | v7       | Callee-saved                                                        |
| r11  | v8       | Callee-saved frame pointer (by convention)                          |
| r12  | ip       | Intra-call scratch (caller-saved)                                   |
| r13  | sp       | Stack pointer. Full-descending, 8-byte aligned at public boundaries |
| r14  | lr       | Link register (holds return address after `bl`)                     |
| r15  | pc       | Program counter. Reads as **current instruction + 4**               |

Cortex-M0 = ARMv6-M. Only r0-r7 are "low" and accepted by most Thumb data-processing instructions. r8-r12 are "high" and only a handful of instructions (`mov`, `add`, `cmp`, `bx`, `blx`, `ldr`/`str` with sp, push/pop with lr/pc) can touch them.

### Program Status Register (APSR / PSR)

Only four flag bits are user-visible:

| Bit | Name | Meaning                                                                     |
|-----|------|-----------------------------------------------------------------------------|
| 31  | N    | Negative — bit 31 of result                                                 |
| 30  | Z    | Zero — result was 0                                                          |
| 29  | C    | Carry — unsigned carry-out for add, NOT-borrow for sub, shifted-out for shifts |
| 28  | V    | oVerflow — signed overflow for add/sub                                      |

Only the "flag-setting" forms of instructions (the `s` suffix: `adds`, `subs`, `movs`, `lsls`, `ands`, …) change NZCV. `cmp`/`cmn`/`tst` always set flags (there is no non-`s` form).

Carry vs overflow — the classic trap:

- **C** is for unsigned. `adds` sets C if the true sum ≥ 2³². `subs` sets C if the subtraction did NOT borrow (i.e. `a >= b`).
- **V** is for signed. `adds`/`subs` set V if the signed result cannot fit in 32 bits.

Example (`adds`):

| a           | b           | result      | N | Z | C | V |
|-------------|-------------|-------------|---|---|---|---|
| 0x7fffffff  | 0x1         | 0x80000000  | 1 | 0 | 0 | 1 |  signed overflow (+ + + → -)
| 0xffffffff  | 0x1         | 0x00000000  | 0 | 1 | 1 | 0 |  unsigned wrap
| 0x80000000  | 0x80000000  | 0x00000000  | 0 | 1 | 1 | 1 |  both overflows

Example (`subs` = `a − b`):

| a    | b    | result | C (NOT-borrow) | note                 |
|------|------|--------|----------------|----------------------|
| 5    | 3    | 2      | 1              | 5 ≥ 3                |
| 3    | 5    | -2     | 0              | borrow               |
| 5    | 5    | 0      | 1              | equal: NOT-borrow    |

So after `cmp r0, r1`:
- `a == b`  ⇔ Z=1
- `a < b` unsigned ⇔ C=0 (borrowed)
- `a >= b` unsigned ⇔ C=1
- `a < b` signed ⇔ N ≠ V
- `a >= b` signed ⇔ N = V

## 1.2 Memory map, endianness, alignment

### nRF51822 memory map (simplified)

```
0x00000000 ─┬─ Flash (256 KiB)          code, vector table, .rodata, .data (init image)
            │
0x20000000 ─┼─ RAM (16 KiB)            .bss, .data (at run-time), heap, stack
            │  stack top  = 0x20004000 for 16 KiB
            │
0x40000000 ─┼─ AHB peripherals         GPIO (0x50000000), UART (0x40002000),
            │                          TIMER0 (0x40008000), TEMP, RNG, ADC,
            │                          RADIO (0x40001000) …
            │
0xE0000000 ─┴─ Cortex-M0 private regs   NVIC, SCB, SysTick
```

The reset handler initialises `sp` from word 0 of the vector table. The vector table itself lives at address 0.

### Endianness

Cortex-M0 is **little-endian**. Storing `0x12345678` to `[r0]` puts:
- `byte[0] = 0x78`, `byte[1] = 0x56`, `byte[2] = 0x34`, `byte[3] = 0x12`.

`ldrh`/`ldrb` pull the low 16/8 bits with zero-extension; `ldrsh`/`ldrsb` sign-extend.

### Alignment

- `ldr`/`str` require 4-byte alignment of the address. Unaligned access **faults** on M0.
- `ldrh`/`strh` require 2-byte alignment.
- `ldrb`/`strb` are 1-byte and always aligned.
- Instructions are 2 bytes, 2-byte aligned. (Some 32-bit Thumb-2 encodings exist on bigger cores but not on M0.)

## 1.3 Thumb instruction set (complete reference)

Only the instructions available on Cortex-M0 / ARMv6-M are listed. Unless stated, the `s`-suffix form sets NZ always, and C (and V for add/sub).

### Data movement

| Syntax                 | Effect                                  | Flags           | Notes                            |
|------------------------|-----------------------------------------|-----------------|----------------------------------|
| `movs Rd, #imm8`       | `Rd = imm8` (0-255)                     | NZ, C=0, V unch | only 8-bit immediate             |
| `movs Rd, Rm`          | `Rd = Rm` (low regs)                    | NZ, C,V unch    |                                  |
| `mov  Rd, Rm`          | `Rd = Rm` (any reg)                     | none            | only form that writes to pc/sp   |
| `mvns Rd, Rm`          | `Rd = ~Rm`                              | NZ              |                                  |

**Trap:** `movs r0, #300` is illegal — immediate > 255. Use `ldr r0, =300` (literal pool).
**Trap:** `mov r8, r1` is legal, `movs r8, r1` is not. The `s` form works on low regs only.
**Trap:** `movs Rd, #imm` sets C according to the immediate's rotation — on M0, C is cleared for decimal constants in range. Best mental model: C becomes 0 for a plain `movs r0, #N`.

### Integer arithmetic (add / sub / mul)

| Syntax                      | Effect                               | Flags  |
|-----------------------------|--------------------------------------|--------|
| `adds Rd, Rn, Rm`           | `Rd = Rn + Rm`                       | NZCV   |
| `adds Rd, Rn, #imm3`        | `Rd = Rn + imm3` (0-7)               | NZCV   |
| `adds Rd, #imm8`            | `Rd = Rd + imm8`                     | NZCV   |
| `add  Rd, Rm`               | `Rd = Rd + Rm` (high regs ok)        | none   |
| `add  sp, #imm`             | `sp += imm*4`  (imm 0..127)          | none   |
| `add  Rd, sp, #imm`         | `Rd = sp + imm*4`                    | none   |
| `add  Rd, pc, #imm` / `adr` | `Rd = (pc & ~3) + imm*4`             | none   |
| `subs Rd, Rn, Rm`           | `Rd = Rn − Rm`                       | NZCV   |
| `subs Rd, Rn, #imm3`        | `Rd = Rn − imm3`                     | NZCV   |
| `subs Rd, #imm8`            | `Rd = Rd − imm8`                     | NZCV   |
| `sub  sp, #imm`             | `sp −= imm*4`                        | none   |
| `rsbs Rd, Rn, #0`           | `Rd = 0 − Rn` (negate)               | NZCV   |
| `adcs Rd, Rm`               | `Rd = Rd + Rm + C`                   | NZCV   |
| `sbcs Rd, Rm`               | `Rd = Rd − Rm − (1 − C)`             | NZCV   |
| `muls Rd, Rm, Rd`           | `Rd = Rd × Rm` (low 32 bits)         | NZ     |

On the nRF51 the multiplier is single-cycle. `muls` has a weird 3-operand form where the destination must be repeated — `muls r0, r1, r0` means `r0 = r0 × r1`.

### Bitwise logical

| Syntax              | Effect                    | Flags |
|---------------------|---------------------------|-------|
| `ands Rd, Rm`       | `Rd = Rd & Rm`            | NZ    |
| `orrs Rd, Rm`       | `Rd = Rd \| Rm`           | NZ    |
| `eors Rd, Rm`       | `Rd = Rd ^ Rm`            | NZ    |
| `bics Rd, Rm`       | `Rd = Rd & ~Rm`           | NZ    |
| `mvns Rd, Rm`       | `Rd = ~Rm`                | NZ    |
| `tst  Rn, Rm`       | set flags on `Rn & Rm`    | NZ    |

### Shifts and rotates (always flag-setting form on M0)

| Syntax                  | Effect                       | C flag becomes               |
|-------------------------|------------------------------|------------------------------|
| `lsls Rd, Rm, #imm5`    | `Rd = Rm << imm5` (0..31)    | last bit shifted out         |
| `lsls Rd, Rm` (=`Rd,Rd,Rm`)  | shift by `Rm[7:0]`      | last bit shifted out         |
| `lsrs Rd, Rm, #imm5`    | `Rd = Rm >> imm5` (logical)  | last bit shifted out         |
| `asrs Rd, Rm, #imm5`    | `Rd = Rm >>> imm5` (arith)   | last bit shifted out         |
| `rors Rd, Rm`           | `Rd = rotate_right(Rd, Rm)`  | bit rotated out              |

`lsls r0, r0, #2` = multiply by 4. `asrs r0, r0, #1` = signed divide by 2 (rounds toward −∞, *not* toward 0 like C's `/`).

Immediate range for shifts: `#1`..`#31` for lsls/lsrs/asrs. `lsls r0, r0, #0` is the same as `movs r0, r0`.

### Compare

| Syntax          | Effect                  |
|-----------------|-------------------------|
| `cmp Rn, Rm`    | flags from `Rn − Rm`    |
| `cmp Rn, #imm8` | flags from `Rn − imm8`  |
| `cmn Rn, Rm`    | flags from `Rn + Rm`    |

### Load / store

| Syntax                         | Effect                                       |
|--------------------------------|----------------------------------------------|
| `ldr  Rt, [Rn, #imm5*4]`       | 32-bit load                                  |
| `ldr  Rt, [Rn, Rm]`            | 32-bit load, register offset                 |
| `ldr  Rt, [sp, #imm8*4]`       | load from stack                              |
| `ldr  Rt, [pc, #imm8*4]` / `ldr Rt, =lit` | literal-pool load                  |
| `str  Rt, [Rn, #imm5*4]`       | 32-bit store                                 |
| `ldrh Rt, [Rn, #imm5*2]`       | 16-bit load, zero-extend                     |
| `ldrsh Rt, [Rn, Rm]`           | 16-bit load, sign-extend                     |
| `strh Rt, [Rn, #imm5*2]`       | 16-bit store                                 |
| `ldrb Rt, [Rn, #imm5]`         | 8-bit load, zero-extend                      |
| `ldrsb Rt, [Rn, Rm]`           | 8-bit load, sign-extend                      |
| `strb Rt, [Rn, #imm5]`         | 8-bit store                                  |

No post-/pre-increment ldr on M0. No `ldr reg, [reg, reg, lsl #n]`. Immediate offsets are unsigned and scaled.

### Block load/store

| Syntax                | Effect                                              |
|-----------------------|-----------------------------------------------------|
| `push {r4-r7, lr}`    | decrement sp by 4×count, store list (low-reg-first) |
| `pop  {r4-r7, pc}`    | load list, increment sp (popping into pc = return)  |
| `stmia Rn!, {r0-r3}`  | store multiple, increment after, writeback          |
| `ldmia Rn!, {r0-r3}`  | load multiple, increment after                      |

`push` only accepts r0-r7 and `lr`. `pop` only r0-r7 and `pc`. Registers in the list are always written/read in ascending-register / ascending-address order (lowest reg at lowest address).

### Branch

| Syntax         | Encoding                              | Effect                         |
|----------------|---------------------------------------|--------------------------------|
| `b label`      | 11-bit signed offset (±2 KiB)         | unconditional jump             |
| `b<cond> label`| 8-bit signed offset (±256 bytes)      | conditional jump               |
| `bl label`     | 24-bit signed offset (±16 MiB)        | `lr = pc; pc = label`          |
| `bx  Rm`       | —                                     | `pc = Rm` (bit 0 must be 1 for Thumb) |
| `blx Rm`       | —                                     | `lr = pc; pc = Rm`             |

Condition mnemonics (used as suffix, e.g. `beq`, `bhi`):

| Suffix | Meaning                  | Flags                |
|--------|--------------------------|----------------------|
| eq     | equal                    | Z=1                  |
| ne     | not equal                | Z=0                  |
| cs/hs  | unsigned ≥               | C=1                  |
| cc/lo  | unsigned <               | C=0                  |
| mi     | negative                 | N=1                  |
| pl     | non-negative             | N=0                  |
| vs     | overflow                 | V=1                  |
| vc     | no overflow              | V=0                  |
| hi     | unsigned >               | C=1 ∧ Z=0            |
| ls     | unsigned ≤               | C=0 ∨ Z=1            |
| ge     | signed ≥                 | N=V                  |
| lt     | signed <                 | N≠V                  |
| gt     | signed >                 | Z=0 ∧ N=V            |
| le     | signed ≤                 | Z=1 ∨ N≠V            |

**Trap:** `bhi` / `bls` / `bhs` / `blo` are *unsigned*. `bgt` / `ble` / `bge` / `blt` are *signed*. Swapping them is the single most common asm bug.

**Trap:** `bx lr` must return to a Thumb address; the low bit of lr must be 1. The `bl` instruction sets it automatically, but if you hand-craft a return address you must `orr rX, #1`.

### Misc

| Syntax        | Effect                                                     |
|---------------|------------------------------------------------------------|
| `nop`         | no operation (really `mov r8, r8`)                         |
| `svc #imm8`   | supervisor call → SVCall exception                         |
| `bkpt #imm8`  | breakpoint                                                 |
| `cpsid i`     | disable IRQ (set PRIMASK)                                  |
| `cpsie i`     | enable IRQ (clear PRIMASK)                                 |
| `wfe` / `wfi` | wait for event / interrupt (sleep until …)                 |
| `sev`         | signal event                                               |
| `dmb`/`dsb`/`isb` | memory / instruction barriers                          |
| `mrs Rd, special` | read PSR / MSP / PSP / PRIMASK / CONTROL                |
| `msr special, Rn` | write ditto                                             |
| `sxth`/`sxtb`/`uxth`/`uxtb` | sign/zero-extend 16/8 → 32                    |
| `rev`/`rev16`/`revsh` | byte-reverse helpers                               |

### Pipeline and `pc`

Cortex-M0 has a 3-stage pipeline (fetch / decode / execute). When an instruction *executes*, the fetch stage is already two instructions ahead, so `pc` reads as **address of current instruction + 4**.

Consequence for hand-assembled branches:
```
   .text
L0: nop                  @ at offset 0
L1: b   L0               @ at offset 2, pc = 6, target = 0, offset = -6/2 = -3
```
The assembler does this maths for you, but you should know it for exam questions.

## 1.4 Addressing modes (summary)

M0 is load-store; only `ldr`/`str` family touch memory. Modes:

| Mode                  | Form                       | Example                          |
|-----------------------|----------------------------|----------------------------------|
| register + immediate  | `[Rn, #imm]`               | `ldr r0, [r1, #4]`               |
| register + register   | `[Rn, Rm]`                 | `ldr r0, [r1, r2]`               |
| sp-relative           | `[sp, #imm]`               | `ldr r0, [sp, #8]`               |
| pc-relative           | `[pc, #imm]` / `=literal`  | `ldr r0, =0x12345678`            |
| adr (pc + imm)        | `adr Rd, label`            | `adr r0, table`                  |

No pre/post-increment except via `ldmia!`/`stmia!`.

## 1.5 Condition codes and branches — worked example

**C source**

```c
if (x > y) z = x - y;
else       z = y - x;
```

**Signed — `int x, y, z`** (registers `r0=x, r1=y, r2=z`):

```
    cmp   r0, r1
    ble   else_          @ signed ≤
    subs  r2, r0, r1
    b     end_
else_:
    subs  r2, r1, r0
end_:
```

**Unsigned — `unsigned x, y, z`**:

```
    cmp   r0, r1
    bls   else_          @ unsigned ≤
    subs  r2, r0, r1
    b     end_
else_:
    subs  r2, r1, r0
end_:
```

If you swap `ble` and `bls` you get silent miscompares for arguments ≥ 0x80000000. Classic exam and real-world trap.

## 1.6 AAPCS calling convention (subset used on M0)

- **r0-r3**: arguments and return value (r0, or r0:r1 for 64-bit). Caller-saved; callee may clobber.
- **r12**: caller-saved scratch (may be trashed by the linker for veneers).
- **r4-r11**: callee-saved; if you use them you must save/restore.
- **sp**: 8-byte aligned at public function boundaries (the `bl` site and function entry). You may transiently use 4-byte alignment inside a function.
- **lr**: caller-saved (a leaf function doesn't need to save it).
- Register arguments only; stack arguments only after r0-r3 are full (rare in this course).

### Why 8-byte align the stack?

On exception entry, the hardware pushes 8 words and re-aligns sp to 8. If your sp was only 4-aligned, the hardware inserts a pad word so the saved frame is 8-aligned. Your own `bl` calls require 8-alignment to stay predictable.

## 1.7 Stack frames — patterns

### Leaf function (no calls, ≤ 4 args, scratch fits in r0-r3)

```
.global  add_pair
.thumb_func
add_pair:
    adds r0, r0, r1
    bx   lr
```

### Non-leaf (uses `bl`, needs to preserve lr)

```
.global  sum_of_squares
.thumb_func
sum_of_squares:                @ int sum_of_squares(int x, int y)
    push    {r4, r5, lr}
    mov     r4, r0
    mov     r5, r1
    movs    r0, r4
    muls    r0, r4, r0         @ r0 = x*x
    movs    r1, r5
    muls    r1, r5, r1         @ r1 = y*y
    adds    r0, r0, r1
    pop     {r4, r5, pc}
```

Symmetry: every register pushed is popped. `pop {.., pc}` returns — avoids a separate `bx lr` and restores alignment.

### Local variables on stack

```
    sub   sp, #16              @ reserve 4 words
    str   r0, [sp, #0]
    ...
    add   sp, #16              @ (or combine with pop)
```

### "Banana" recursion — factorial

```
.global  fact
.thumb_func
fact:                          @ r0 = n
    push {r4, lr}
    cmp  r0, #1
    bls  base
    mov  r4, r0
    subs r0, r0, #1
    bl   fact                  @ fact(n-1)
    muls r0, r4, r0
    pop  {r4, pc}
base:
    movs r0, #1
    pop  {r4, pc}
```

Note we must use r4 (callee-saved) to keep `n` across the recursive call; r0-r3 would be clobbered by `bl`.

## 1.8 Assembler directives (GNU as, `.s` files)

| Directive        | Meaning                                                    |
|------------------|------------------------------------------------------------|
| `.text`          | switch to code section                                     |
| `.data`          | initialised data section                                   |
| `.bss`           | zero-initialised data                                      |
| `.rodata`        | read-only data (in Flash)                                  |
| `.align n`       | align to 2^n bytes                                         |
| `.p2align n`     | same, explicit power-of-2                                  |
| `.global name`   | export symbol                                              |
| `.extern name`   | declare external                                           |
| `.equ NAME,val`  | constant (`.set` is synonym)                                |
| `.byte`, `.hword`, `.word` | 1/2/4-byte literal                                |
| `.ascii "..."`, `.asciz "..."` | string (+NUL)                                |
| `.space n[,val]` | n bytes of filler                                          |
| `.thumb`         | following code is Thumb (on M0, always)                    |
| `.thumb_func`    | mark next label as a Thumb subroutine entry (bit-0 set)    |
| `.ltorg`         | emit pending literal pool here                             |
| `.syntax unified`| modern syntax (as in lab examples)                         |
| `.cpu cortex-m0` | target CPU                                                 |

**Trap:** omitting `.thumb_func` before a global subroutine name confuses `bl` through the linker — bit 0 may end up clear and you'll fault. Always mark subroutines.

## 1.9 Literal pool and `ldr Rd, =value`

Thumb immediates are tiny. To load a 32-bit constant or address:

```
    ldr  r0, =0x12345678     @ pseudo-op: loads from a literal pool
    ldr  r1, =account        @ loads address of 'account'
```

The assembler plants the 32-bit word into a small pool near the function and converts the pseudo-op into `ldr r0, [pc, #imm]`. Pools must be within ±1 KiB; the assembler emits a new one at the end of each function, but if a function is huge you can force it with `.ltorg`.

**Trap:** distinguish:

```
    ldr  r0, =label          @ r0 := address of label           (sort of like LEA)
    ldr  r0, [label]         @ r0 := *(uint32_t *) label        (load value at label)
    ldr  r0, label           @ r0 := *(uint32_t *) label        (same; address must be near pc)
    adr  r0, label           @ r0 := address of label (pc-rel, limited range)
```

## 1.10 Startup code and the vector table

Every program has a vector table at address 0 (or wherever `VTOR` points). On M0 `VTOR` is fixed at 0 for the nRF51. Words 0 and 1 are mandatory; the rest correspond to exceptions and IRQs.

```
.section ".vectors"
.word    __stack_top          @  0: initial MSP
.word    __reset + 1          @  1: reset handler (Thumb bit set)
.word    nmi_handler + 1      @  2: NMI
.word    hardfault_handler+1  @  3: HardFault
.word    0,0,0,0,0,0,0        @  4-10: reserved
.word    svc_handler + 1      @ 11: SVCall
.word    0,0                  @ 12-13: reserved
.word    pendsv_handler + 1   @ 14: PendSV
.word    systick_handler + 1  @ 15: SysTick
@ ... then device IRQs start at 16 ...
```

The `+1` is the Thumb bit — without it, `bx` to a handler address would try ARM mode and fault.

The reset handler (in `startup.c`) copies `.data` from Flash to RAM, zeroes `.bss`, then calls `main()`/`init()`. Linker script `nRF51822.ld` defines `__stack_top`, `__data_start`, etc.

### Exception vs IRQ numbering
- Exception numbers 0..15 are architectural (Reset=1, NMI=2, … SysTick=15).
- IRQ numbers 0..31 for M0 peripherals, offset by +16 in exception numbering.
- `hardware.h` uses the device-IRQ numbering: `UART_IRQ=2`, `TIMER0_IRQ=8`, `GPIOTE_IRQ=6`, `RADIO_IRQ=1`, `I2C_IRQ=3`, `SVC_IRQ=-5`, `PENDSV_IRQ=-2` (negatives are exceptions).

## 1.11 Toolchain cheat-sheet

```
arm-none-eabi-as   -mcpu=cortex-m0 -mthumb file.s -o file.o
arm-none-eabi-gcc  -mcpu=cortex-m0 -mthumb -mfloat-abi=soft -g -Os -c foo.c
arm-none-eabi-ld   -T nRF51822.ld  startup.o foo.o ... -o prog.elf
arm-none-eabi-objcopy -O ihex prog.elf prog.hex
arm-none-eabi-objdump -d prog.elf            @ disassemble .text
arm-none-eabi-objdump -s -j .rodata prog.elf @ raw dump of a section
arm-none-eabi-nm     prog.elf                @ symbols
arm-none-eabi-size   prog.elf                @ text/data/bss sizes
```

GDB (with openocd/blackmagic):

```
arm-none-eabi-gdb prog.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) load
(gdb) break *func                 @ break at function entry
(gdb) layout regs / layout asm
(gdb) stepi                       @ single machine instruction
(gdb) info registers
(gdb) x/4wx 0x20000000            @ examine 4 words in hex
(gdb) x/16i $pc                   @ disassemble next 16 insns
```

## 1.12 Assembly exam traps (in one list)

1. `movs r0, #300` — immediate only 8-bit. Use `ldr r0, =300`.
2. Forgetting `.thumb_func` → `bl` goes to an ARM address → UsageFault.
3. `ldr r0, =label` vs `ldr r0, [label]` — one loads the address, the other loads the value.
4. Unsigned vs signed branches (`bhi` vs `bgt`).
5. Flag-setting `s` suffix vs non-setting form. `adds` changes NZCV; `add` does not.
6. After `cmp`, `bls` means **unsigned ≤**, not "less than or equal signed".
7. `muls r0, r1, r0` — destination must be the repeated operand.
8. `push {r0, r1}` is legal but not idiomatic — push callee-saved regs, not args.
9. `bx lr` after a leaf function — no `pop` needed because nothing was pushed.
10. `pop {pc}` requires `push {lr}` earlier — the bits in lr include the Thumb bit.
11. Don't trash sp. Don't trash lr without saving it.
12. Reading `pc` inside an instruction yields *pc + 4*, not the address of the instruction itself.
13. `ldr r0, [r1, #imm]` — `imm` is scaled by 4 (for word loads), and unsigned.
14. `rsbs Rd, Rn, #0` is the canonical negate; there is no `negs` on M0.
15. `mvns Rd, Rn` is bitwise NOT, not arithmetic negate.
16. `ands Rd, Rn` only sets NZ — C is preserved, V undefined (cleared in practice).
17. `lsls r0, r0, #0` doesn't update C the way `lsls r0, r0, #1` does (because nothing was shifted out).
18. Stack must be 8-byte aligned at `bl` sites.
19. `svc #n` triggers an SVCall *exception*, not an IRQ. Handler reads the immediate from the instruction.

---

# Part 2: C for Embedded Systems

## 2.1 Integer sizes and two's complement

| C type        | 32-bit ARM EABI size | Range                                  |
|---------------|----------------------|----------------------------------------|
| `char`        | 1 byte (unsigned by default on ARM!) | 0..255                    |
| `short`       | 2 bytes              | −32768..32767                          |
| `int`         | 4 bytes              | −2³¹ .. 2³¹−1                          |
| `long`        | 4 bytes              | same as int                            |
| `long long`   | 8 bytes              | −2⁶³ .. 2⁶³−1                          |
| pointer       | 4 bytes              | —                                      |

**Trap:** on ARM EABI, `char` is *unsigned* by default. Compare with x86 where it's signed. If you want a signed 8-bit type use `signed char` or `int8_t` from `<stdint.h>`.

In practice, always use `<stdint.h>` types in hardware code: `uint8_t`, `int16_t`, `uint32_t`, `uint64_t`.

## 2.2 Pointers and addressing hardware

Memory-mapped register access pattern (used throughout `hardware.h`):

```c
#define  _REG(type, addr)     (*(volatile type *)(addr))
#define  _ARR(type, addr)     ((volatile type *)(addr))

#define  GPIO_OUT      _REG(unsigned, 0x50000504)
#define  GPIO_DIR      _REG(unsigned, 0x50000514)
#define  NVIC_ISER     _REG(unsigned, 0xE000E100)
```

- `*(volatile uint32_t *)0x50000504 = 0x10000` stores directly to the register.
- `volatile` tells the compiler **do not cache; do not elide; do not reorder** loads/stores to this address.
- Without `volatile`, a `while (!(UART_EVENT_TXDRDY)) ;` polling loop may be compiled as a read-once/loop-forever.

## 2.3 `volatile` — when it's required

Required whenever **some agent other than the current flow of C code** can change the memory:

- Memory-mapped I/O registers.
- Variables shared between an ISR and main line.
- Variables set by signal handlers / OS callbacks.

`volatile` does **not** provide atomicity. For multi-byte updates shared with an ISR you still need a critical section (`intr_disable()`/`intr_enable()`).

```c
volatile bool flag;       /* set by ISR */
while (!flag) { /* ... */ }
```

## 2.4 Bit manipulation idioms

```c
#define BIT(n)         (1U << (n))
#define MASK(n)        (BIT(n) - 1)       /* low n bits = 1 */
#define FIELD(pos,w,v) (((v) & MASK(w)) << (pos))
#define GET_FIELD(x, pos, w) (((x) >> (pos)) & MASK(w))

SET_BIT(reg, n)       reg |=  BIT(n)
CLR_BIT(reg, n)       reg &= ~BIT(n)
TOGGLE_BIT(reg, n)    reg ^=  BIT(n)
TEST_BIT(reg, n)      ((reg) &  BIT(n))
```

`hardware.h` defines these verbatim. Use them rather than hand-writing to avoid precedence bugs:

```c
/* WRONG precedence: */  if (reg & BIT(3) == 0)
/* fixes to:        */  if ((reg & BIT(3)) == 0)
/* prefer:          */  if (!TEST_BIT(reg, 3))
```

## 2.5 Structs for register blocks

Sometimes you see:

```c
typedef struct {
    volatile uint32_t TASKS_START;   /* 0x000 */
    volatile uint32_t TASKS_STOP;    /* 0x004 */
    /* ... */
    volatile uint32_t EVENTS_TXDRDY; /* 0x11C */
    /* ... */
    volatile uint32_t INTENSET;      /* 0x304 */
    volatile uint32_t INTENCLR;      /* 0x308 */
    /* ... */
} UART_Type;

#define UART ((UART_Type *)0x40002000)

UART->TASKS_STARTRX = 1;
```

`hardware.h` mostly uses the `_REG`/`_BASE` macro approach instead, but struct-typed peripherals are the CMSIS norm you'll see in datasheets.

## 2.6 `printf` and the standard library

The `lib.c` in the labs implements a small `printf` that ends up calling `serial_putc`. It supports `%d`, `%u`, `%x`, `%s`, `%c`. No floats. Every print call eventually writes bytes to UART TXD.

## 2.7 Embedded-C traps

1. Forgetting `volatile` on an I/O register or ISR-shared variable.
2. Not marking a function `static` and getting link-time collisions.
3. Assuming `char` is signed.
4. Shifting by ≥ 32 — undefined behaviour. Always use `uint32_t` and keep shifts in 0..31.
5. Integer promotion in mixed signed/unsigned comparisons: `-1 < 1U` is false.
6. Taking the address of a bit-field: illegal. Use a full-word load with masking.
7. Omitting `break` in a `switch` — falls through.
8. `sizeof(array)` vs `sizeof(pointer)` — works on the array at declaration scope only.
9. Mixing `==` and `=` in `if` — the compiler should warn, but …
10. Relying on evaluation order of function arguments.

---

# Part 3: micro:bit / nRF51 Peripherals

## 3.1 GPIO

Registers (single `GPIO0` block at `0x50000000`):

| Reg            | Offset  | Meaning                                              |
|----------------|---------|------------------------------------------------------|
| OUT            | 0x504   | pin output values                                    |
| OUTSET         | 0x508   | writes 1 set bits in OUT                             |
| OUTCLR         | 0x50C   | writes 1 clear bits in OUT                           |
| IN             | 0x510   | pin input values                                     |
| DIR            | 0x514   | 1 = output, 0 = input                                |
| DIRSET / DIRCLR| 0x518/C | set-only / clear-only versions                       |
| PIN_CNF[0..31] | 0x700+  | per-pin configuration (dir, input buffer, pull, drive, sense) |

Setting a pin as an output:
```c
GPIO_DIRSET = BIT(17);              /* pin 17 */
GPIO_OUTSET = BIT(17);              /* drive high */
GPIO_OUTCLR = BIT(17);              /* drive low */
```

Using SET/CLR registers avoids read-modify-write races with interrupts.

For button pin (17 or 26):
```c
GPIO_PIN_CNF[BUTTON_A] = 0;         /* input, no pull (board has external pull-up) */
if (!(GPIO_IN & BIT(BUTTON_A))) { /* pressed */ }
```

### LED matrix (V1 board)

- 3 rows × 9 columns wired chaotically to 5×5 LEDs (two entries unused in row 1).
- Pins: row1=13, row2=14, row3=15; cols 4..12.
- Configure rows as outputs with **high drive** (in PIN_CNF set DRIVE=S0H1 = 1 in the relevant field).
- To light LED in logical row `r`, col `c`: drive `ROW[r]` high, drive `COL[c]` **low** (columns are cathodes).
- Persistence of vision: refresh all three rows within ~20 ms. Typical design: 5 ms per row with soft PWM for brightness.
- The `IMAGE(...)` macro in `hardware.h` reduces a 25-bit human-readable layout to three 32-bit row words at compile time (`0x28f0, 0x5e00, 0x8060` for the canonical heart).

GPIO output bit layout on V1 (low 16 bits of OUT):
```
bit:   15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
name:  r3 r2 r1 c9 c8 c7 c6 c5 c4 c3 c2 c1  0  0  0  0
```

## 3.2 UART0

The nRF51 UART is at base `0x40002000` with key registers:

| Reg          | Purpose                                          |
|--------------|--------------------------------------------------|
| TASKS_STARTRX| start receiver                                   |
| TASKS_STARTTX| start transmitter                                |
| TASKS_STOP…  | stop RX/TX                                       |
| EVENTS_RXDRDY| a byte arrived                                    |
| EVENTS_TXDRDY| a byte was transmitted                            |
| PSELRXD      | which pin is RX (or 0xffffffff to disable)       |
| PSELTXD      | which pin is TX                                   |
| BAUDRATE     | e.g. 9600 → 0x00275000, 115200 → 0x01D7E000       |
| RXD          | received byte                                     |
| TXD          | byte to transmit                                  |
| INTENSET/INTENCLR| per-event interrupt enables                   |
| CONFIG       | parity, hardware flow control                     |

### Polling `serial_putc`

```c
void serial_putc(char ch) {
    UART_TXD = ch;
    while (!UART_EVENT_TXDRDY) ;
    UART_EVENT_TXDRDY = 0;
}
```

Simple but blocks. If you return *before* waiting for TXDRDY you can get `ch` lost when the caller immediately writes another byte.

### Interrupt-driven `serial_putc` with circular buffer

```c
#define NBUF 64
static volatile char txbuf[NBUF];
static volatile int  txhead = 0, txtail = 0, txcount = 0;
static volatile int  txidle = 1;

void serial_putc(char ch) {
    intr_disable(UART_IRQ);           /* critical section */
    if (txidle) {
        UART_TXD = ch;
        txidle = 0;
    } else {
        while (txcount == NBUF) {     /* buffer full: wait */
            intr_enable(UART_IRQ);
            /* nothing */             /* isr will eventually drain */
            intr_disable(UART_IRQ);
        }
        txbuf[txhead] = ch;
        txhead = (txhead + 1) % NBUF;
        txcount++;
    }
    intr_enable(UART_IRQ);
}

void uart_handler(void) {
    if (UART_EVENT_TXDRDY) {
        UART_EVENT_TXDRDY = 0;
        if (txcount > 0) {
            UART_TXD = txbuf[txtail];
            txtail = (txtail + 1) % NBUF;
            txcount--;
        } else {
            txidle = 1;
        }
    }
}
```

Per lab 3, the buffer can shrink to 1 byte and the program still works — but short buffers let the CPU waste time spinning in `serial_putc`; longer buffers (64, 256, …) absorb bursts. A test harness in lab 3 tracks max high-water mark.

### Critical section

The S+ task in lab 3 explores reducing the critical section to cover only the `else` branch — the ISR must not fire between "decide to append" and "index/update `txhead/txcount`", but the TXD-starting branch is fine because `txidle` transitions are a one-way flip the ISR handles safely.

## 3.3 Timer

Three 24/32-bit timers (`TIMER0/1/2`) at `0x40008000 + n*0x1000`. Model:

- Can tick at a prescaled rate (16 MHz / 2^PRESCALER).
- Four compare registers `CC[0..3]`.
- Tasks: `START`, `STOP`, `CLEAR`, `CAPTURE[n]`.
- Events: `COMPARE[n]` when counter hits `CC[n]`.
- `SHORTS` lets a compare auto-clear or stop the timer — common in millisecond-tick drivers.

Typical "1 ms tick":

```c
TIMER0_MODE        = 0;        /* timer (vs counter) */
TIMER0_BITMODE     = 0;        /* 16-bit */
TIMER0_PRESCALER   = 4;        /* 16 MHz / 16 = 1 MHz = 1 µs per tick */
TIMER0_CC[0]       = 1000;     /* 1000 µs */
TIMER0_SHORTS      = BIT(0);   /* COMPARE[0] -> CLEAR */
TIMER0_INTENSET    = BIT(16);  /* COMPARE[0] interrupt */
enable_irq(TIMER0_IRQ);
TIMER0_START       = 1;
```

`timer_handler` in `timer.c` typically increments a millisecond counter and wakes waiting processes.

## 3.4 I2C (TWI) — accelerometer

I2C peripheral `TWI0` sends 7-bit address + R/W + data bytes. Driver initialises SCL/SDA pins, configures the address of the MMA8652 accelerometer, issues reads of X/Y/Z acceleration every 5 ms, and posts messages to the level program.

## 3.5 Radio

2.4 GHz proprietary (Nordic `RADIO`). Configurable packet layout: 1-byte preamble, 3-byte address, payload length, payload (up to 254 bytes, labs use 32), 16-bit CRC. `radio_send(pkt, len)` / `radio_receive(buf)` are the driver API. Lab 4's `ex-remote.c` uses it for button-press broadcast among micro:bits.

## 3.6 Other peripherals (brief)

- **RNG**: true hardware random, one byte per interrupt (`EVENTS_VALRDY`). Lab 4 extra exercise: write a driver that posts bytes to a client process.
- **TEMP**: processor-die temperature, in quarters of °C. Asynchronous: `TASKS_START` → `EVENTS_DATARDY` → read `TEMP`.
- **ADC**: 10-bit SAR, up to 8 channels.

## 3.7 Datasheet reading

The Nordic nRF51 "Product Specification" has chapters per peripheral. Layout typical:
1. Overview diagram.
2. Register map (offsets + names).
3. Detailed register bit layout.
4. Task/Event tables.
5. Timing characteristics.

Practical reading strategy:
1. Find the peripheral base address in "Instantiation" chapter.
2. Read the event/task diagram first — it tells you which TASKS_* to fire and which EVENTS_* to wait on.
3. Only then read the bit-level register tables.
4. Configure PSEL (pin select) registers before enabling the peripheral.

---

# Part 4: Interrupts, Exceptions, and MicrobiΛn

## 4.1 Polling vs interrupts

Polling pseudo-code:
```c
while (1) {
    if (EVENT_READY) { handle(); EVENT_READY = 0; }
    do_other_work();
}
```
- Deterministic latency bounded by loop length.
- CPU is always busy — no sleep possible.
- Composes badly: each "other work" step lengthens worst-case latency.

Interrupts:
- Hardware signals the NVIC; the CPU finishes the current instruction, saves context, and jumps to the handler.
- Main code doesn't need to know the peripheral exists, beyond priority assignments.
- Latency is bounded by the number of higher-priority handlers.
- Allows `wfi`/`wfe` sleep.

Both lab 3 programs (polling/interrupt versions of primes) are timed with an LED. The interrupt version overlaps printing with prime hunting. Where the polling version prints and hunts sequentially, the interrupt version lets `TIMER`/`UART` ISRs run while main loops on `isprime`, so total running time is bounded by the slower of {print 500 primes, compute 500 primes}.

## 4.2 Exception model (Cortex-M0)

Exception number layout:
- 1 Reset
- 2 NMI
- 3 HardFault
- 11 SVCall (from the `svc` instruction)
- 14 PendSV (software-triggered; used for context switch)
- 15 SysTick
- 16.. external IRQs (0..31 on M0, numbered 16..47 in exception space)

### Exception entry (hardware)

On exception, the hardware automatically:
1. Pushes 8 words to the active stack (r0, r1, r2, r3, r12, lr, pc, xPSR).
2. Loads `lr` with a magic **EXC_RETURN** value:
   - `0xFFFFFFF1` — return to handler mode
   - `0xFFFFFFF9` — return to thread, use MSP
   - `0xFFFFFFFD` — return to thread, use PSP
3. Sets `pc` from the vector table.

The handler runs in *handler mode* using the MSP.

### Exception return

`bx lr` with an EXC_RETURN value tells the hardware to pop 8 words from the appropriate stack. That's how `mpx-m0.s` switches processes: PendSV alters which stack pointer the 8-word frame will be popped from.

### Prioritisation

- Reset / NMI / HardFault have fixed highest priority.
- Configurable exceptions have priorities from `NVIC_IPR[n]` (2 bits on M0 → four levels: 0, 1, 2, 3; higher number = lower priority).
- Tail-chaining: if another IRQ is pending at exit, hardware skips the pop/push and jumps straight to the next handler.
- Late-arriving: if a higher-priority IRQ comes in during entry, hardware services it first.

### NVIC registers (M0 subset)

| Addr        | Name     | Purpose                                      |
|-------------|----------|----------------------------------------------|
| 0xE000E100  | ISER     | write 1 to bit n → enable IRQ n              |
| 0xE000E180  | ICER     | write 1 to bit n → disable IRQ n             |
| 0xE000E200  | ISPR     | set pending                                  |
| 0xE000E280  | ICPR     | clear pending                                |
| 0xE000E400+ | IPR      | priority (8-bit fields, top 2 bits used)     |
| 0xE000ED04  | ICSR     | PendSV/SVC/NMI set-pending, VECTPENDING      |

`hardware.h` wraps these as `enable_irq`/`disable_irq`/`clear_pending`/`reschedule` macros, and also provides `active_irq` — reads `IPSR` (exception number).

### PRIMASK (global disable)

`cpsid i` sets PRIMASK — blocks every configurable-priority exception. `cpsie i` clears it. Used to implement a flat critical section.

## 4.3 Writing an ISR in C

```c
void timer0_handler(void) {
    if (TIMER0_EVENT_COMPARE[0]) {
        TIMER0_EVENT_COMPARE[0] = 0;   /* clear or interrupt re-fires */
        ticks++;
    }
}
```

Requirements:
1. **Name matches** the vector table entry (set in startup).
2. **Clear the event** in the peripheral, or the same ISR re-fires immediately.
3. **Keep it short**. Defer work via a flag/message to a thread.
4. **volatile** any variable touched by both ISR and main.
5. Don't `printf` from an ISR in a real program — printing blocks.

## 4.4 Race conditions and critical sections

Classic race: non-atomic read-modify-write of a shared counter.

```c
volatile int counter;

/* main: */
counter++;       /* ldr r0, =counter; ldr r1, [r0]; adds r1, #1; str r1, [r0] */
```

ISR that also does `counter++` between the ldr and str loses the main's increment.

Fixes:
- **Disable interrupts** across the RMW:
  ```c
  intr_disable(UART_IRQ); counter++; intr_enable(UART_IRQ);
  ```
- **Message passing** (MicrobiΛn) — turn every shared resource into a server.
- **Atomic primitives** — M0 has none (no LDREX/STREX).

## 4.5 MicrobiΛn kernel — the big picture

- Fixed set of processes created at boot by `init()`. After that, no `start`.
- Scheduling: strict priority with round-robin inside a level.
- Communication: synchronous message passing (16-byte fixed messages).
- No shared memory model exposed — each driver is a server.

### Process states

| State       | Meaning                                                        |
|-------------|----------------------------------------------------------------|
| DEAD        | slot is free / process terminated                              |
| ACTIVE      | ready to run, on a ready queue                                 |
| SENDING     | blocked in `send()` waiting for receiver                       |
| RECEIVING   | blocked in `receive()` waiting for a sender                    |
| SENDREC     | blocked in `sendrec()` (atomic send then receive reply)        |
| IDLING      | the IDLE process; runs only when nothing else is ready          |

### Priority levels

| Priority   | Value | Use                                                  |
|------------|-------|------------------------------------------------------|
| P_HANDLER  | 0     | interrupt-side of a driver                           |
| P_HIGH     | 1     | the rest of the driver; short, responsive processes  |
| P_LOW      | 2     | application processes, number crunchers              |
| P_IDLE     | 3     | the idle process (sleeps the CPU)                    |

A running process is preempted when a higher-priority process becomes ACTIVE. A process can lower its priority via `priority(newprio)`.

### Ready / send / receive queues

Each priority has its own ready queue. Each process has an in-queue of senders waiting for it; when it posts a `receive()` the kernel picks a sender off the queue.

### System calls (SVC)

```c
int  start(char *name, void (*body)(int), int arg, int stacksize);
void send(int dst, message *m);
void receive(int type, message *m);
void sendrec(int dst, message *m);
void priority(int p);
void connect(int irq);     /* I want to receive INTERRUPT messages from this IRQ */
int  getpid(void);
void yield(void);
```

Each is implemented by `svc #N` → SVCall handler reads the immediate and dispatches. The service function can mark the caller SENDING/RECEIVING, which schedules someone else.

### Message struct (16 bytes, 4 words)

```c
typedef struct {
    unsigned short type;      /* a tag like PUTC, GETC, INTERRUPT, REPLY */
    unsigned char  sender;    /* filled in by the kernel */
    unsigned char  padding;
    unsigned int   a, b, c;   /* payload */
} message;
```

A sender blocks until the receiver has `receive()`d, then both run. Because it's a copy, you can reuse your `m` variable across calls.

### Interrupts as messages

`connect(UART_IRQ)` in the UART driver tells the kernel "when UART_IRQ fires, unblock me with a message of type INTERRUPT". In practice the kernel services the interrupt very briefly, converts it to a message delivered to the driver process, which then does the real work (cooperating with other processes) at priority P_HIGH.

### `send` / `receive` / `sendrec` semantics

```
send(P, m)    : block until P does a matching receive; then both proceed.
receive(t, m) : block until some process sends us a message of type t (or ANY).
                 Also delivers INTERRUPT messages if the caller has connect()ed.
sendrec(P, m) : atomic send to P then receive reply (from P). One call = one
                 context-switch round trip; saves one scheduling pass vs
                 send + receive. Used by client stubs.
```

### Context switch plumbing (`mpx-m0.s`)

- Trap entry is through **SVC** for system calls and **PendSV** for scheduler points.
- The kernel picks the next process to run, then triggers PendSV.
- `pendsv_handler` saves the callee-saved regs (r4-r7, r8-r11 via low regs + sp) onto the outgoing process's stack, switches PSP to the incoming process's stack, and returns via the EXC_RETURN magic (0xFFFFFFFD = thread/PSP).

Threads run in Thread mode using PSP; kernel runs in Handler mode using MSP. Only the kernel has full privilege, but on M0 there's no privilege separation worth writing home about — the distinction is still useful for stack isolation.

### "Give the display higher priority than the primes" (lab 4 task 3)

If the primes process and the display process run at the same priority with round-robin timeslicing, bursts of prime-printing will starve the display refresh. Giving the display `P_HIGH` ensures it is scheduled whenever it has work — the primes job uses 100 % CPU at P_LOW and is preempted whenever the display's 5 ms timer tick wakes it. Remove the priority line and the display flickers or the heart deforms.

### "Swap the start() calls" (lab 4 race)

`ex-race.c` creates a ticker process and a printer process. If you reorder the `start()` calls, you change the initial order on the ready queue; the tick count printed therefore starts from a slightly different base. Because both processes run at the same priority with deterministic scheduler behaviour, runs are *reproducible* once the order is fixed — that's why the outputs are identical run-to-run, even though a naive view would expect non-determinism.

### "Today: the two politicians" (mutual exclusion)

Two politicians would each print a slogan letter-by-letter. Without an interviewer, their characters interleave to word salad. Introduce a third process (the "interviewer") that owns a token; each politician `sendrec`s "may I speak?" to the interviewer and only prints when granted. Two natural designs:
1. Politicians send slogans to the interviewer, who prints them one slogan at a time.
2. Interviewer hands out a "speak" token; politician holds it until finished.

## 4.6 SVC and PendSV — the dance

1. Thread calls a system call stub: `svc #4` (e.g. SEND).
2. CPU pushes frame, goes to SVC handler at MSP.
3. Handler reads the SVC immediate from the pushed pc (`pc[-1]` modulo Thumb bit).
4. Handler looks at r0-r3 (already in the pushed frame) for arguments.
5. Handler updates the process state. If the current thread can still run, return; if not, it sets PendSV pending (`ICSR`) and returns.
6. PendSV fires at low priority after SVC returns; runs scheduler; loads next thread's PSP; returns into that thread.

## 4.7 Interrupt & MicrobiΛn exam traps

1. "Can a higher-priority IRQ preempt an ISR?" Yes — configurable preemption.
2. "Does SVC preempt PendSV?" SVC has higher priority by default; in MicrobiΛn PendSV is configured to the lowest priority so system calls always finish before rescheduling.
3. **Clearing the event** is essential — forgetting it leaves the interrupt line asserted.
4. `volatile` on ISR-shared vars.
5. `printf` from an ISR can deadlock (UART is buffered).
6. Priority-inversion: a low-priority producer can be blocked by a high-priority consumer it is meant to feed — solve with queue depth or priority inheritance.
7. Message passing means one process at a time touches the hardware — mutual exclusion becomes "hold a message queue".
8. `sendrec` vs `send`+`receive`: one context switch vs two.

---

# Part 5: Digital Logic

## 5.1 Boolean algebra

Axioms (Huntington):
- Commutative: `a+b=b+a`, `a·b=b·a`
- Associative: `(a+b)+c=a+(b+c)`, `(a·b)·c=a·(b·c)`
- Distributive: `a·(b+c)=a·b+a·c`, `a+(b·c)=(a+b)·(a+c)`
- Identity: `a+0=a`, `a·1=a`
- Complement: `a+a'=1`, `a·a'=0`

Derived:
- Idempotence: `a+a=a`, `a·a=a`
- Absorption: `a+a·b=a`, `a·(a+b)=a`
- De Morgan: `(a·b)' = a'+b'`, `(a+b)' = a'·b'`
- Consensus: `ab + a'c + bc = ab + a'c`

## 5.2 Canonical forms and truth tables

For n variables there are 2ⁿ minterms. A **minterm** is a product of every variable (uncomplemented if 1, complemented if 0) that's true for exactly one row of the truth table. A Boolean function is the OR of its minterms — the **sum-of-products** (SOP) canonical form.

Example: majority(a, b, c)

| a b c | out |
|-------|-----|
| 000   | 0   |
| 001   | 0   |
| 010   | 0   |
| 011   | 1   |
| 100   | 0   |
| 101   | 1   |
| 110   | 1   |
| 111   | 1   |

SOP: `m3 + m5 + m6 + m7 = a'bc + ab'c + abc' + abc`

Simplify (pair adjacent terms that differ in one variable):
- `ab'c + abc = ac(b'+b) = ac`
- `abc' + abc = ab(c'+c) = ab`
- Remaining: `a'bc + ab + ac = ab + ac + bc` (consensus on the third).

Result: `ab + ac + bc`. Three 2-input ANDs and a 3-input OR.

## 5.3 Karnaugh maps

2D Gray-coded layout of a truth table. Adjacent cells differ in exactly one variable, so groups of 1, 2, 4, 8 covering adjacent cells correspond to simplifiable product terms.

3-variable K-map, variables a, bc:

```
     bc
      00 01 11 10
a=0   0  0  1  0
a=1   0  1  1  1
```

Groups:
- 1s at (a=1, bc=01) and (a=1, bc=11): share a=1, c=1 → `ac`
- 1s at (a=1, bc=11) and (a=1, bc=10): share a=1, b=1 → `ab`
- 1s at (a=0, bc=11) and (a=1, bc=11): share b=1, c=1 → `bc`
Coverage: `ab + ac + bc`. Matches the algebraic minimisation.

Wrap-around: leftmost and rightmost columns are adjacent. Corners in a 4-var map are mutually adjacent.

## 5.4 NAND / NOR universality

Every Boolean function can be expressed with only NAND (or only NOR). Constructions:
- `NOT a        = a NAND a`
- `a AND b      = NOT (a NAND b) = (a NAND b) NAND (a NAND b)`
- `a OR  b      = (a NAND a) NAND (b NAND b)` (De Morgan)

CMOS actually makes NAND and NOR "cheaper" than AND/OR because AND = NAND + INV.

## 5.5 Gates and CMOS

Each CMOS gate = a **pull-up network of p-type** transistors (conducts when gate is LOW) in series/parallel with a **pull-down network of n-type** transistors (conducts when gate is HIGH). The two networks are **duals**: series in one ↔ parallel in the other.

NAND gate: two n-MOS **in series** pull the output low only when both inputs are 1. Two p-MOS **in parallel** pull the output high if either input is 0. That's exactly the NAND function.

A CMOS inverter has one p-MOS (source to Vdd, drain to out) and one n-MOS (source to GND, drain to out), gates tied together. Draws static current only during transitions.

**Noise margin:** logic levels have guard bands. `VIH` = minimum voltage read as 1; `VOH` = minimum output voltage when driving 1. Gap = noise margin. Cascading works because gates output tighter voltages than they accept.

## 5.6 Combinational building blocks

### Multiplexer (2:1)
`y = s' · a + s · b`

n:1 mux has `⌈log n⌉` select bits. Implemented as tree of 2:1s.

### Decoder
n-to-2ⁿ: each output asserted for exactly one input combination. 3-to-8 is common for instruction decode.

### Encoder / priority encoder
Inverse: one-hot input → binary output. Priority encoder resolves simultaneous inputs.

### Half-adder
```
s = a ⊕ b
c = a · b
```

### Full adder
```
s    = a ⊕ b ⊕ cin
cout = a·b + cin·(a ⊕ b)
```

Two half-adders and an OR.

### Ripple-carry adder (RCA)
n full adders chained: carry_i+1 = f(a_i, b_i, carry_i). Worst-case delay O(n).

### Carry-lookahead adder (CLA)
Define per bit:
```
g_i = a_i · b_i         (generate — this position produces a carry)
p_i = a_i ⊕ b_i         (propagate — this position forwards a carry)
c_{i+1} = g_i + p_i · c_i
```
Unroll to expose parallelism:
```
c1 = g0 + p0·c0
c2 = g1 + p1·g0 + p1·p0·c0
c3 = g2 + p2·g1 + p2·p1·g0 + p2·p1·p0·c0
...
```
Each carry becomes a wide AND-OR — O(log n) delay if you build a tree of group-generate/group-propagate signals. Lab 6 (Haskell) makes you implement both ripple and CLA and compare.

### ROM / PROM
2ⁿ-word × m-bit ROM implements an arbitrary n-input m-output function by tabulation. Address decoder + OR plane.

### PLA
Programmable AND plane + programmable OR plane; encodes SOP directly.

## 5.7 Sequential logic

### D latch (level-sensitive)
```
Q⁺ = D   when enable = 1
Q⁺ = Q   when enable = 0
```
Two NAND feedback loops — transparent when clock high, opaque when low.

### D flip-flop (edge-triggered)
Master-slave: one latch clocked on one phase, another on the opposite. Value sampled on rising edge and held until next rising edge.

- **Setup time t_su**: D must be stable before the clock edge.
- **Hold time t_h**: D must stay stable after the clock edge.
- **Clock-to-Q t_cq**: delay from clock edge to Q updating.
- **Combinational delay t_p**: delay through logic between FFs.

Minimum clock period: `T ≥ t_cq + t_p + t_su`.

### Register (n-bit)
n D-FFs sharing a clock.

### Shift register
FFs in a chain: `Q_i⁺ = Q_{i-1}`. SIPO (serial-in parallel-out) and PISO (parallel-in serial-out) variants.

### Counter
T flip-flop: `Q⁺ = Q ⊕ T`. Chain with `T_i = Q_{i-1}` for an asynchronous ripple counter. Synchronous counters are preferred (all FFs share a clock, logic computes next state).

### Parity detector
Single D-FF with `D = parity ⊕ bit_in`. Output toggles on each 1 bit.

### Pulse shaper / debouncer
Sample a noisy switch at 1 kHz; latch only if the value has been stable for N samples. Done with a small shift register or an up/down counter.

### Bathroom-switch FSM
Two switches `a, b`, one lamp. Toggle on either. Implementation: `L⁺ = L ⊕ (a_rising ⊕ b_rising)` where `a_rising` is a one-clock pulse from a pulse-shaper. Or a 2-bit state encoding last values of a and b.

## 5.8 Finite state machines

### Moore
Output depends only on state. `out = g(state)`, `next_state = f(state, in)`.
More reliable; output glitches are absorbed by the output register.

### Mealy
Output depends on state *and* input. Faster (saves a cycle) but outputs can glitch if inputs glitch.

### Design recipe
1. List states with meaningful names.
2. State transition diagram (arrows labelled with input/output).
3. State assignment — give each state a binary code.
4. Build next-state table.
5. K-map each next-state bit.
6. K-map each output.
7. Map to FFs + combinational logic.

### Example — sequence detector "101"

States: S0 (nothing), S1 (saw 1), S2 (saw 10). Output asserted on the transition from S2 with input=1.

Transitions (Mealy):
```
S0 --0/0--> S0
S0 --1/0--> S1
S1 --0/0--> S2
S1 --1/0--> S1
S2 --0/0--> S0
S2 --1/1--> S1
```

Assign `S0=00, S1=01, S2=10`. Derive next-state logic, output.

## 5.9 Timing & metastability

- **Metastability**: if a FF's setup or hold is violated, Q may hover between 0 and 1 for arbitrary time, eventually resolving. Probability of resolving decays exponentially with settling time.
- **Synchroniser**: two back-to-back FFs to reduce MTBF of metastability to astronomical values.
- Asynchronous inputs (buttons, data from another clock domain) must be synchronised before use.

## 5.10 Digital-logic exam traps

1. Drawing XOR as two ANDs and an OR when asked for minimum gate count — use 1 XOR or 4 NAND.
2. Forgetting the don't-care cells in K-maps (can be 0 or 1 — pick whatever minimises).
3. Confusing setup (before edge) and hold (after edge) times.
4. Mealy output that glitches — assume combinational hazards unless registered.
5. Active-low vs active-high enable on a MUX or decoder.
6. Assuming all FFs in a design are edge-triggered; some questions use latches.
7. Forgetting that K-map groups are power-of-2 size.
8. Single-bit changes only between adjacent K-map cells — Gray code ordering.
9. CMOS pull-up is p-type (gate LOW → conducting). Swapping n and p gives a resistive divider.
10. Universal gate construction: prove that your NAND-only circuit actually gives NOT, AND, OR.

---

# Part 6: CPU Architecture & Datapath

## 6.1 Single-cycle vs pipelined vs multi-cycle

The course builds up a **single-cycle Thumb datapath** that executes one instruction per clock cycle. Clock period must accommodate the slowest instruction (a load: fetch + decode + reg read + compute addr + memory read + writeback).

Pipelining splits the work into stages. Cortex-M0 has 3 stages:
- Fetch (read next halfword from Flash).
- Decode (work out what it is; read registers).
- Execute (ALU + memory + writeback).

A branch "stall" costs 1 extra cycle on M0 because the fetched instruction after a taken branch is discarded.

## 6.2 Components of a datapath

- **Register file**: 16 × 32-bit, 2 read ports + 1 write port.
- **ALU**: 32-bit add / sub / and / or / xor / shift / compare. Output flags NZCV.
- **Barrel shifter**: combinational left/right/arith/rotate shift by `0..31`.
- **Memory**: Harvard-ish (separate I and D buses internally on M0, but architecturally one address space).
- **Extenders**: sign- and zero-extend halfword/byte loads; sign-extend immediates.
- **PC logic**: PC += 2 for fetch; PC := target on branch; PC := lr on return.
- **Control**: decode → signals.

## 6.3 Control signals (flat list)

Decoded from the instruction bits (possibly with a small ROM):

| Signal    | Width | Meaning                                                         |
|-----------|-------|-----------------------------------------------------------------|
| cRegA     | 4     | register file read port A (source 1)                            |
| cRegB     | 4     | register file read port B (source 2)                            |
| cRegC     | 4     | register file write port (destination)                          |
| cAluOp    | 3-4   | which ALU function                                              |
| cAluSrc   | 1     | ALU B comes from regfile or immediate                           |
| cMemRd    | 1     | perform memory read                                             |
| cMemWr    | 1     | perform memory write                                            |
| cMemSize  | 2     | byte / halfword / word                                          |
| cMemExt   | 1     | sign- vs zero-extend load                                       |
| cRegWrite | 1     | commit ALU / memory result to regfile                           |
| cWFlags   | 1     | update NZCV                                                     |
| cPcSrc    | 2     | PC+2, branch target, lr, exception vector                       |
| cBrCond   | 4     | condition code for B<cond>                                      |

**Derived** signals (computed from decoded ones): e.g. "write enable to reg file" = `cRegWrite ∧ ¬cExceptionTaken`.

**Dynamic** signals (depend on data): e.g. "branch taken" = `cBrCond satisfied by NZCV`.

## 6.4 Stage-by-stage walk-through (Thumb single-cycle)

### Fetch
```
pc_next  = taken ? branch_target : pc + 2
imem_addr = pc
instr     = imem[pc]
pc        <= pc_next
```

### Decode
Instruction pattern-matched against the Thumb opcode classes (format 1..19 in ARM's table). Produces cRegA, cRegB, cRegC, immediate, cAluOp, etc.

### Register read
```
a = regfile[cRegA]
b = regfile[cRegB]
```
Note: reads of `pc` (r15) yield `pc + 4` (to match the architectural visible PC).

### Immediate / shift
Thumb encodes an immediate in a variable-width field; extenders and the barrel shifter produce `imm_operand` or `shifted_b`.

### ALU
```
op2 = cAluSrc ? imm_operand : shifted_b
result = ALU(cAluOp, a, op2)
flags_out = compute_flags(cAluOp, a, op2, result)
```

### Memory
```
mem_addr = result             (for ldr/str) or a               (for ldm/stm)
if cMemRd:  mem_data = mem[mem_addr]
if cMemWr:  mem[mem_addr] <= b
load_value = extend(cMemExt, cMemSize, mem_data)
```

### Writeback
```
if cRegWrite: regfile[cRegC] <= cMemRd ? load_value : result
if cWFlags:   NZCV <= flags_out
```

### PC update & branches
```
if cond(cBrCond, NZCV):
    pc <= result    (for B, BL with target already computed)
else:
    pc <= pc + 2
```

### Subroutine calls
`bl target` in a single-cycle machine:
1. compute return address = pc + 2 (next instruction)
2. write to lr (cRegC = 14, cRegWrite = 1)
3. set pc := target

`bx Rm`:
1. pc := Rm
2. mode := Rm[0] (must be 1 for Thumb)

### Conditional branches
`b<cond> target`:
1. compute pc + sign-extended offset
2. evaluate cond on NZCV
3. if cond: pc := target, else pc := pc + 2

## 6.5 Pipelining insights

Hazards:
- **Structural**: two stages want the same resource (e.g. memory) — avoid by Harvard split or stalls.
- **Data**: an instruction reads a register just written by a prior instruction — solved by forwarding or stalls.
- **Control**: branch target not known until Execute — flush or predict.

Cortex-M0 takes the simple route: 3 stages, flush 1-2 instructions on a taken branch.

## 6.6 Datapath exam traps

1. When reading `pc` in the regfile, remember the `+4` architectural offset.
2. The write-back register destination for `bl` is `lr` (r14), not r0.
3. `bx lr` uses the register file's output directly into `pc`; the Thumb bit must be set.
4. Exceptions push eight words to stack before the handler runs — the datapath calls into microcode or an automatic hardware sequence.
5. Flag updates only happen on `s`-suffix instructions and `cmp`/`cmn`/`tst` — cWFlags is 0 otherwise.
6. PC-relative `ldr r0, [pc, #imm]` uses `pc & ~3` as the base (forces word alignment) — the actual `pc` bits [1:0] are masked.
7. For a single-cycle machine, the critical path is usually `ldr`: regfile → ALU (compute addr) → dmem → extender → regfile-write. That sets minimum cycle time.

---

# Problem Sheet Patterns

## Sheet 1 — Boolean algebra & gates

Typical exercises:
1. Simplify `f(a,b,c,d) = Σm(0,2,5,7,8,10,13,15)` using a K-map.
2. Prove an identity using only axioms.
3. Implement XOR from four NAND gates.
4. Design a 3-input majority in NAND only.

Approach:
- Draw the K-map first. Look for maximum-size groups. Take don't-cares.
- When asked "only NAND", map your SOP to NAND-NAND form: `f = OR( AND(a,b), AND(c,d) ) = NAND( NAND(a,b), NAND(c,d) )`.

Example: majority in NAND.

```
m    = ab + ac + bc
     = NAND( NAND(a,b), NAND(a,c), NAND(b,c) )        (3-input NAND)
     = NAND( NAND(NAND(a,b), NAND(a,c)), NAND(b,c) )  (2-input NANDs only)
```

## Sheet 2 — Sequential logic / FSM

Typical exercises:
1. Design a Mealy FSM that detects "0110".
2. Design a modulo-6 counter using D-FFs.
3. Compute setup/hold margins given `t_cq = 2, t_p = 5, t_su = 1, T = 10` ns.

Approach:
- Write the state diagram with one state per "progress point".
- Derive a state assignment (Gray coding sometimes minimises flip-flop flips).
- Next-state equations are K-maps of (current state, input).

"Sequence detector 0110" (Mealy) — state graph:

```
S0 --0/0--> S1 (saw 0)
S0 --1/0--> S0
S1 --0/0--> S1 (saw 00, still counts)
S1 --1/0--> S2 (saw 01)
S2 --0/0--> S1 (saw 010 → last 0 becomes new start)
S2 --1/0--> S3 (saw 011)
S3 --0/1--> S1 (saw 0110 → detect)
S3 --1/0--> S0 (saw 0111 → restart)
```

## Sheet 3 — Peripherals / interrupts

Typical exercises:
1. Write a UART driver to print a NUL-terminated string.
2. Write an RNG driver that collects N samples and prints a histogram.
3. Show how to trigger the TEMP sensor and wait for an interrupt.
4. Explain why an ISR-shared counter needs `volatile`.

RNG driver skeleton:
```c
static volatile uint8_t rng_value;
static volatile bool    rng_ready;

void rng_handler(void) {
    if (RNG_EVENT_VALRDY) {
        RNG_EVENT_VALRDY = 0;
        rng_value = RNG_VALUE;
        rng_ready = true;
        RNG_TASK_STOP = 1;
    }
}

uint8_t rng_sample(void) {
    rng_ready = false;
    RNG_TASK_START = 1;
    while (!rng_ready) wfi();
    return rng_value;
}
```

## Sheet 4 — Thumb assembly / calling convention

Typical exercises:
1. Translate a C loop to Thumb.
2. Given a Thumb sequence, compute NZCV at each step.
3. Explain what breaks if a non-leaf function doesn't push lr.

Worked example: strlen.

```c
int strlen(const char *s) {
    int n = 0;
    while (*s++ != '\0') n++;
    return n;
}
```

```
.global strlen
.thumb_func
strlen:
    movs    r1, #0
1:  ldrb    r2, [r0]
    cmp     r2, #0
    beq     2f
    adds    r0, r0, #1
    adds    r1, r1, #1
    b       1b
2:  movs    r0, r1
    bx      lr
```

Note: `ldrb` zero-extends; `cmp r2, #0` sets Z if NUL; `1:`/`2:` are local numeric labels, referred to with `1b` (backward) / `2f` (forward).

## Sheet 5 — MicrobiΛn / processes

Typical exercises:
1. Write a "printf server" process.
2. Explain priority inversion with a politician example.
3. Sketch what happens to the stack during an SVC call.
4. Compare `send+receive` vs `sendrec`.

Printf-server process:
```c
void printf_task(int arg) {
    message m;
    while (1) {
        receive(ANY, &m);
        switch (m.type) {
        case PUTC:
            /* write m.a low byte to UART */
            uart_putc(m.a);
            m.type = REPLY;
            send(m.sender, &m);
            break;
        }
    }
}
```

## Sheet 6 — Datapath / single-cycle CPU

Typical exercises:
1. Given a list of control signals, identify the instruction.
2. Add support for `ldm`/`stm` to a simple datapath.
3. Compute the minimum clock period.
4. Show the microarchitectural changes needed to support interrupts.

Approach:
- Build a signals table: rows = instructions, columns = cRegA, cAluOp, cMemRd, cMemWr, cRegWrite, cWFlags, cPcSrc, cBrCond. Fill in for each instruction class.
- For timing: sum the longest combinational path through fetch → decode → reg read → ALU / memory → writeback.

---

# Lab Takeaways

## Lab 0 — Echo

Goals: build environment, flash a hex, use `minicom`, understand UART config.

Key code:
```c
UART_ENABLE       = 4;                  /* enable the UART */
UART_BAUDRATE     = UART_BAUDRATE_9600; /* or 115200 */
UART_CONFIG       = 0;                  /* no parity, no flow */
UART_PSELTXD      = USB_TX;
UART_PSELRXD      = USB_RX;
UART_TASK_STARTTX = 1;
UART_TASK_STARTRX = 1;

for (;;) {
    while (!UART_EVENT_RXDRDY) ;
    UART_EVENT_RXDRDY = 0;
    char c = UART_RXD;
    UART_TXD = c;
    while (!UART_EVENT_TXDRDY) ;
    UART_EVENT_TXDRDY = 0;
}
```

Lesson: peripheral programming is `configure, start tasks, poll events`.

## Lab 1 — Assembly subroutine

Files:
- `func.s` — 1-instruction add (`adds r0, r0, r1; bx lr`).
- `mul1.s` — naive multiply loop (adds y to itself x times → O(x)).
- `fac.s` — factorial calling `mult`.
- `bank.s` — `account[x] += y`, uses static array.

From `mul1.s` we learn the slow-loop anti-pattern: pick the smaller of x/y as the loop count (software shortcut) or use `muls`. `10000000 * 2` runs fast, `2 * 10000000` runs slow — this is why.

Better multiply (shift-and-add, O(log x)):
```
    movs  r2, #0
1:  lsrs  r0, r0, #1
    bcc   2f
    adds  r2, r2, r1
2:  lsls  r1, r1, #1
    cmp   r0, #0
    bne   1b
    movs  r0, r2
    bx    lr
```
For each bit of x: if bit is 1 add y; always shift y left.

Unsigned division (bit-at-a-time):
```
@ r0 = dividend, r1 = divisor, returns r0 = quotient
    push  {r4, r5, lr}
    movs  r2, #0                 @ remainder
    movs  r3, #0                 @ quotient
    movs  r4, #32
1:  lsls  r0, r0, #1
    adcs  r2, r2, r2             @ shift carry into remainder
    cmp   r2, r1
    blo   2f
    subs  r2, r2, r1
    adds  r3, r3, #1
2:  lsls  r3, r3, #1
    subs  r4, r4, #1
    bne   1b
    lsrs  r0, r3, #1
    pop   {r4, r5, pc}
```

From `bank.s` we learn the standard array-indexing idiom:
```
    ldr   r3, =account
    lsls  r2, r0, #2
    ldr   r0, [r3, r2]
    adds  r0, r0, r1
    str   r0, [r3, r2]
    bx    lr
```

Debugging with gdb: `break *func`, `stepi`, watch register changes to see flag behaviour.

## Lab 2 — Heart on GPIO

Goals: drive the LED matrix directly.

Key code structures:
```c
const unsigned heart[] = IMAGE(
    0,1,0,1,0,
    1,1,1,1,1,
    1,1,1,1,1,
    0,1,1,1,0,
    0,0,1,0,0);

void show(const unsigned *img) {
    for (int t = 0; t < 40; t++) {
        for (int row = 0; row < 3; row++) {
            GPIO_OUT = img[row];
            delay(2);  /* ms */
            GPIO_OUT = 0;
        }
    }
}
```

Button handling (lab 2 task):
```c
if (!TEST_BIT(GPIO_IN, BUTTON_A)) show(small_heart);
else if (!TEST_BIT(GPIO_IN, BUTTON_B)) show(hollow_heart);
else show(heart);
```

The hollow heart design: light only outline LEDs. Good exercise to practice IMAGE macro.

Delay-loop timing: `delay(us)` has an `nop`-padded loop where 8 cycles @ 16 MHz = 500 ns, so `us * 2` loop iterations.

Bonus programs:
- `heart-intr.c` — uses TIMER0 instead of delay loop; foreshadows lab 3.
- `blinky.s` — pure assembly; minimal vector table (only stack_top + reset_vector).

## Lab 3 — Interrupt-driven UART primes

Files:
- `primes-poll.c` — `serial_putc` is polling.
- `primes-intr.c` — `serial_putc` enqueues to a circular buffer and enables TXDRDY interrupt.

Measured observations:
- Transmission at 9600 baud is ~1 ms/char; first 500 primes print in seconds where primes are small. With interrupts, CPU overlap cuts wall-clock roughly in half on the tough workloads.
- Reducing buffer to 1 char still works but wastes time spinning.
- Printing primes above 10⁷: printing time scales with digit count (∼8 chars × 500 = 4000 chars = 4 s), sieve time scales differently; with interrupts, the slower dominates.

S+ tasks:
- Removing `intr_disable`/`intr_enable` is risky: between the `if (txidle)` test and the update of `txidle/TXD`, an IRQ can fire. If the ISR sees `txidle=0` but there's nothing in the buffer, it sets `txidle=1` just before main stores into the buffer and never retriggers.
- Shrinking the critical section to the `else` branch is safer — the `txidle`-branch transitions are atomic enough.
- The RNG sub-task is a great warm-up for lab-4 driver writing.

Further exercises:
- LED-on-while-printing scope trace: visualises the interrupt overlap.
- "Sneaky" stack spy: read words *below* sp every few cycles and see them change — that's the hardware exception frame being written on each interrupt.

## Lab 4 — MicrobiΛn

Files:
- `microbian.c` / `microbian.h` — kernel.
- `mpx-m0.s` — context switch.
- Drivers: `serial.c`, `timer.c`, `i2c.c`, `radio.c`.
- Example apps: `ex-heart.c`, `ex-echo.c`, `ex-race.c`, `ex-today.c`, `ex-level.c`, `ex-remote.c`.

Key takeaways:
1. **Heart + primes**: giving display `P_HIGH` prevents primes-induced flicker. Proof by experiment: strip the priority call and watch it break.
2. **Today (two politicians)**: introduce an interviewer process; mutual exclusion via message-passing rather than shared memory.
3. **Race**: scheduler is deterministic; swapping `start()` calls changes the base of the counter.
4. **Level**: I2C driver posts "new reading" messages at ~200 Hz; main process picks the pixel nearest the tilt direction.
5. **Remote**: radio driver broadcasts button press packets; receivers display A or B.

Driver pattern:
```c
static int DRIVER;

void driver_task(int arg) {
    connect(IRQ_NUM);
    while (1) {
        receive(ANY, &m);
        switch (m.type) {
        case INTERRUPT: /* handle hardware event */ break;
        case CLIENT_REQUEST: /* serve request */   break;
        }
    }
}

void driver_init(void) {
    DRIVER = start("driver", driver_task, 0, STACK);
}

/* client stub */
int driver_op(int x) {
    message m = { .type = CLIENT_REQUEST, .a = x };
    sendrec(DRIVER, &m);
    return m.a;
}
```

### Task S1 (ex-today.c) — Mutual exclusion via interviewer

The unmodified program has `May` and `Farage` calling `put_string` (which sends characters to the serial driver one at a time) while the scheduler can context-switch between serial `send` calls. The result is interleaved characters on the terminal.

Working solution — "Interviewer grants a PING, politician prints, replies":
```c
static int INTERVIEWER;

void process(int n) {
    while (1) {
        receive(PING, NULL);        // block until interviewer says go
        timer_delay(2000);
        put_string(slogan[n]);
        send_msg(INTERVIEWER, REPLY); // signal done
    }
}

void interviewer(int dummy) {
    int may_pid = dummy;
    int far_pid = dummy + 1;
    while (1) {
        send_msg(may_pid, PING);
        receive(REPLY, NULL);
        send_msg(far_pid, PING);
        receive(REPLY, NULL);
    }
}

void init(void) {
    serial_init();
    timer_init();
    int may = start("May",      process,     0,   STACK);
    start(           "Farage",   process,     1,   STACK);
    INTERVIEWER = start("Interviewer", interviewer, may, STACK);
}
```

**Why this works**: each politician blocks in `receive(PING)` until the interviewer sends it a PING token. It prints its slogan atomically (no other process can interleave because the interviewer waits for REPLY before granting the next token). The PIDs of May and Farage are passed to the interviewer as `dummy`; Farage's PID is `may+1` because `start()` allocates PIDs sequentially.

**Alternative (Option A — politician sends slogan to interviewer who prints it)**:
```c
void process(int n) {
    while (1) {
        message m = { .type = REQUEST, .ptr1 = slogan[n] };
        sendrec(INTERVIEWER, &m);  // send + wait for REPLY
    }
}

void interviewer(int dummy) {
    message m;
    while (1) {
        receive(REQUEST, &m);
        put_string(m.ptr1);
        m.type = REPLY;
        send(m.sender, &m);
    }
}
```

### Task S2 (ex-race.c) — Scheduling order and determinism

`proc1` prints `r` 10 times; `proc2` increments `r` to 100000 then spins.

```c
static volatile int r = 0;

void proc1(int n) {
    for (int i = 0; i < 10; i++)
        printf("r = %d\n", r);   // printf blocks on serial driver
}

void proc2(int n) {
    while (r < 100000) r++;
    for (int i = 0; i < 2000000; i++) { nop(); nop(); nop(); }
    dump();
}

void init(void) {
    serial_init();
    start("Proc1", proc1, 0, STACK);
    start("Proc2", proc2, 0, STACK);
}
```

- Both processes start at `P_LOW`. The first `start()` call puts that process at the **head** of the P_LOW queue → it runs first.
- With the order above: `proc1` runs first, prints `r=0`, then blocks on serial; `proc2` gets CPU, increments `r`, context-switches back to `proc1` after each serial write.
- **Swapping** the two `start()` calls makes `proc2` run first → it may reach 100000 before `proc1` ever prints, so all 10 prints show large values.
- **Why consistent run-to-run**: no cache jitter, no OS scheduling noise, deterministic 16 MHz clock. Same instruction count → same timing every power-on.

### Task S3 (ex-heart.c) — Priority and preemption

The current file has `priority(P_HIGH)` **commented out**:
```c
// priority(P_HIGH);
```

With it commented, both `heart_task` (display) and `prime_task` (CPU-bound, starts at 10 000 000) run at `P_LOW`. `prime_task` never calls a blocking system call, so it never voluntarily yields. The only preemption points are timer interrupts (every 5 ms when `timer_delay(5)` fires). But `timer_delay` is itself in `heart_task` — if `prime_task` holds the CPU, `heart_task` never gets to call `timer_delay`, so the timer never fires for it, and the display row never advances → **display freezes or strobes a single row**.

With `priority(P_HIGH)` restored: every timer ISR wakes up `heart_task` (at P_HIGH) which immediately preempts `prime_task` (P_LOW) → display updates on schedule, primes continue in the background.

**What changes when starting primes at 1 000 000 instead of 10 000 000**: each prime test is cheaper (smaller numbers), so `prime_task` burns less CPU per print. With P_HIGH on `heart_task`, this makes no visible difference. Without P_HIGH, the effect is the same — starvation — because the scheduler still only switches on system calls.

### microbian.c internals — process descriptor

```c
struct _proc {
    int      pid;
    char     name[16];
    unsigned state;      // DEAD/ACTIVE/SENDING/RECEIVING/SENDREC/IDLING
    unsigned *sp;        // saved stack pointer
    void     *stack;     // base of stack allocation
    unsigned  stksize;
    int      priority;
    proc     waiting;    // linked list: processes blocked in send() to this one
    int      pending;    // IRQ pending flag (set by default_handler)
    int      filter;     // message type filter for receive()
    message  *msgbuf;    // caller's message buffer
    proc     next;       // next in ready/sender queue
};
```

**Memory layout**: stack space grows **upward** from `__end` (end of BSS). Process descriptors are allocated **downward** from `__stack_limit`. The deliberate gap means a stack overflow writes into unused space before it can corrupt the descriptor array. Each stack is pre-filled with `0xdeadbeef`; the kernel checks the sentinel to detect overflow.

**How send/receive works (simplified)**:
1. `send(dst, &m)`: if `dst` is already in `receive()` for this message type → copy message, both become ACTIVE. Otherwise → caller becomes SENDING, joins `dst->waiting` queue; `choose_proc()` picks next.
2. `receive(type, &m)`: if a matching sender is already queued → deliver immediately. Otherwise → caller becomes RECEIVING, `filter = type`; `choose_proc()` picks next.
3. `sendrec(dst, &m)`: atomically send + set caller to SENDREC. Prevents the race where the REPLY arrives between a manual `send` and the following `receive`.

**Interrupt → message pipeline**: `default_handler()` (in `mpx-m0.s`) disables the IRQ, calls `interrupt(pid)` which sets `pending=1` on the registered driver process and makes it ACTIVE. Driver re-enables the IRQ after handling.

### S+ exercise — Hot Potato (potato.c)

A multi-player radio game using four concurrent microbian tasks on each micro:bit.

| Task | Priority | Behaviour |
|------|----------|-----------|
| `receiver_task` | P_LOW | Blocks on `radio_receive`; on packet `'P'` sets `has_potato=1`, resets heat, sends ACK |
| `sender_task` | P_LOW | Polls buttons every 100 ms; Button A sends `'P'` and releases potato |
| `heat_task` | P_LOW | Every `round_time` ms increments `heat_level`; at 5 sets `game_over=1` |
| `display_task_game` | P_LOW | Every 200 ms: if `game_over` blink sad face; else if `has_potato` show fill level; else show happy face |

Shared volatile state:
```c
static volatile int has_potato  = 0;   // 1 if this device holds the potato
static volatile int heat_level  = 0;   // 0–4; at 5 → BOOM
static volatile int game_over   = 0;
static volatile int round_time  = 3000; // ms, decreases 200ms each catch (min 800ms)
```

Progressive difficulty: every time a device *receives* the potato, `round_time` decreases by 200 ms (floor 800 ms), making the potato get hotter faster each round.

**Design notes and race conditions to be aware of**:
- `has_potato`, `heat_level`, `game_over`, `round_time` are `volatile` but not atomically guarded. On a single-core M0 with no preemption between C statements (only at `timer_delay` / `radio_receive` calls), this is safe in practice — but a rigorous fix would be to move shared state into a single "game server" task communicating via messages.
- `receiver_task` and `sender_task` both write `has_potato` — `receiver_task` sets it to 1, `sender_task` sets it to 0. Because both run at `P_LOW` and context-switches happen only at blocking system calls (`radio_receive`, `timer_delay`), these writes cannot interleave in the current code.
- `heat_task` reads `has_potato` and `game_over`; a production system would use `sendrec` to a game-server rather than shared volatile globals.

`init()` pattern:
```c
void init(void) {
    serial_init();
    timer_init();
    radio_init();
    radio_group(GROUP);   // GROUP 42 — isolates from other groups
    display_init();
    start("Receiver", receiver_task,     0, STACK);
    start("Sender",   sender_task,       0, STACK);
    start("Heat",     heat_task,         0, STACK);
    start("GameDisp", display_task_game, 0, STACK);
}
```

## Lab 5 — Thumb simulator

Goal: extend a simulator that executes Thumb instructions one by one. Test files exercise edge cases (overflow, wrap, negative shifts). Teaches careful reading of ARMv6-M encoding tables.

## Lab 6 — Carry-lookahead adder (Haskell)

Goal: implement ripple-carry and carry-lookahead in functional style, prove equivalence on all 32-bit inputs (or by property-based testing), compare gate counts / delay.

Haskell skeleton:
```haskell
type Bit = Bool

halfAdder :: Bit -> Bit -> (Bit, Bit)
halfAdder a b = (a `xor` b, a && b)

fullAdder :: Bit -> Bit -> Bit -> (Bit, Bit)
fullAdder a b cin = (s, c1 || c2)
  where (s0, c1) = halfAdder a b
        (s,  c2) = halfAdder s0 cin

rca :: [Bit] -> [Bit] -> Bit -> ([Bit], Bit)
rca []     []     c = ([], c)
rca (a:as) (b:bs) c = let (s, c') = fullAdder a b c
                         (ss, cout) = rca as bs c'
                      in (s:ss, cout)
```

For CLA: compute `p_i`, `g_i`, then expand `c_{i+1} = g_i + p_i · c_i` across groups.

---

# Quick-reference cheat-sheets

## A. Thumb instruction list (compact)

```
mov(s)  movs(#imm8)  mvns
add(s)  adds(#imm3) adds(#imm8)  add sp,#   add Rd,sp,#   adr
sub(s)  subs(#imm3) subs(#imm8)  sub sp,#
muls  adcs  sbcs  rsbs Rd,Rn,#0
cmp   cmn   tst
ands  orrs  eors  bics  mvns
lsls  lsrs  asrs  rors   (immediate or register)

ldr  ldrh  ldrsh  ldrb  ldrsb
str  strh         strb
push {..., lr}     pop {..., pc}
ldmia Rn!, {..}    stmia Rn!, {..}

b      b<cond>     bl     bx     blx
svc    bkpt       cpsid i  cpsie i
wfi  wfe  sev  nop  dmb  dsb  isb
mrs  msr   sxth  sxtb  uxth  uxtb  rev  rev16  revsh
```

## B. Condition codes

`eq ne cs/hs cc/lo mi pl vs vc hi ls ge lt gt le`

Unsigned: `cs/hs  cc/lo  hi  ls`
Signed:   `mi  pl  vs  vc  ge  lt  gt  le`

## C. Register conventions (AAPCS)

| Reg        | Role                           |
|------------|--------------------------------|
| r0-r3      | args / return / caller-saved   |
| r4-r11     | callee-saved                   |
| r12        | caller-saved scratch           |
| r13 (sp)   | stack pointer                  |
| r14 (lr)   | link register                  |
| r15 (pc)   | program counter                |

## D. Flag setting

- `s`-suffix arithmetic: `adds` `subs` `muls` `rsbs` `adcs` `sbcs`.
- `s`-suffix logical: `ands` `orrs` `eors` `bics` `mvns` `movs`.
- `s`-suffix shifts: `lsls` `lsrs` `asrs` `rors`.
- Always: `cmp` `cmn` `tst`.

## E. nRF51 IRQ table (from `hardware.h`)

| IRQ        | # |
|------------|---|
| POWER_CLOCK| 0 |
| RADIO      | 1 |
| UART       | 2 |
| I2C        | 3 |
| SPI        | 4 |
| GPIOTE     | 6 |
| ADC        | 7 |
| TIMER0     | 8 |
| TIMER1     | 9 |
| TIMER2     |10 |
| RTC0       |11 |
| RTC1       |17 |
| RNG        |13 |
| TEMP       |12 |
| SVC        |-5 |
| PendSV     |-2 |

## F. MicrobiΛn API

```c
int  start(char *name, void (*body)(int), int arg, int stacksize);
void send(int dst, message *m);
void receive(int type, message *m);
void sendrec(int dst, message *m);
void priority(int p);
void connect(int irq);
int  getpid(void);
void yield(void);
void exit(void);
void dump(void);            /* print process table to serial */
```

Convenience send wrappers (in `microbian.h`):
```c
void send_msg(int dst, int type);
void send_int(int dst, int type, int val);   /* payload in m.int1 */
void send_ptr(int dst, int type, void *ptr); /* payload in m.ptr1 */
```

Message struct:
```c
typedef struct {
    unsigned short type;    /* INTERRUPT, REPLY, REQUEST, PING, ANY=-1, … */
    short          sender;  /* filled by kernel */
    union { int int1; void *ptr1; };
    union { int int2; void *ptr2; };
    union { int int3; void *ptr3; };
} message;
```

Common message types: `INTERRUPT REPLY TIMEOUT REGISTER PING REQUEST READ WRITE OK ERR SEND RECEIVE ANY`

Priority constants: `P_HANDLER=0  P_HIGH=1  P_LOW=2  P_IDLE=3`

## G. Digital-logic identities

```
a + 0 = a          a · 1 = a
a + 1 = 1          a · 0 = 0
a + a = a          a · a = a
a + a' = 1         a · a' = 0
a' ' = a
(a + b)' = a' · b' (a · b)' = a' + b'
a + ab = a          a(a+b) = a
a + a'b = a + b     a(a'+b) = ab
ab + a'c + bc = ab + a'c      (consensus)
```

## H. Full adder / CLA

```
s_i = a_i ⊕ b_i ⊕ c_i
c_{i+1} = a_i b_i + (a_i ⊕ b_i) c_i
p_i = a_i ⊕ b_i     g_i = a_i b_i
c_{i+1} = g_i + p_i c_i
```

Group:
```
G = g_{n-1} + p_{n-1} g_{n-2} + … + p_{n-1} … p_1 g_0
P = p_{n-1} p_{n-2} … p_0
c_{out of group} = G + P · c_{in of group}
```

## I. Datapath control-signal table (sample rows)

| Instr        | cAluOp | cAluSrc | cMemRd | cMemWr | cRegWrite | cWFlags | cPcSrc  |
|--------------|--------|---------|--------|--------|-----------|---------|---------|
| adds Rd,Rn,Rm| ADD    | reg     | 0      | 0      | 1         | 1       | pc+2    |
| adds Rd,Rn,#i| ADD    | imm     | 0      | 0      | 1         | 1       | pc+2    |
| cmp  Rn, Rm  | SUB    | reg     | 0      | 0      | 0         | 1       | pc+2    |
| ldr  Rd,[Rn,#]| ADD   | imm     | 1      | 0      | 1         | 0       | pc+2    |
| str  Rt,[Rn,#]| ADD   | imm     | 0      | 1      | 0         | 0       | pc+2    |
| b    label   | —      | —       | 0      | 0      | 0         | 0       | branch  |
| beq  label   | —      | —       | 0      | 0      | 0         | 0       | cond    |
| bl   label   | —      | —       | 0      | 0      | lr←pc+2   | 0       | branch  |
| bx   Rm      | —      | —       | 0      | 0      | 0         | 0       | reg(Rm) |

---

# Miscellaneous exam-ready facts

1. **Boot sequence**: CPU resets → reads word 0 of vector table into sp → word 1 into pc → executes reset handler → reset handler inits .data/.bss → `init()` or `main()` runs.
2. **Why is the reset-vector address +1?** Thumb bit. The hardware AND-masks the low bit before using as pc but requires it set to confirm Thumb state.
3. **Why does pressing reset recover the device?** Reset vector runs startup again, which reinitialises state.
4. **Clock skew between clocks on the nRF51**: peripheral HF clock is 16 MHz (crystal). CPU runs off the same. Timers prescale from this.
5. **Sleep modes**: `wfi` lets the clock to the core stop until an IRQ becomes pending. Handy for battery-powered designs.
6. **Noise on buttons**: debounce either in hardware (RC) or software (sample and agree N times).
7. **C99 integer types**: `<stdint.h>` gives `uint8_t, int16_t, …, uint32_t`. Use these for hardware registers.
8. **Write-once registers**: some peripheral control bits are "write-clear" — writing 1 clears them. `EVENTS_*` follow that pattern in the labs (actually on nRF51 you write 0 to clear).
9. **Big-endian assumption is wrong**: byte 0 of a 32-bit word is the *least* significant on nRF51.
10. **Interrupts and the C abstract machine**: because interrupts can fire between any two C statements, `volatile` + critical sections are the safety net. `volatile` does not imply atomicity.
11. **Race condition taxonomy**: lost update, reading of torn 32-bit value (not possible on M0 for aligned word), use-after-free across context switch.
12. **IAR / GNU differences**: in the labs we use GNU as with `.syntax unified`. Some datasheets show IAR syntax (`MOVS R0, #imm` — same as GNU).
13. **AAPCS return of 64-bit values**: r0 = low, r1 = high.
14. **Varargs**: r0-r3 then stack. `printf`'s `%s` reads a pointer, `%d` reads an int.
15. **Weakly defined handlers**: in startup code, each IRQ handler is `.weak` and defaults to a dead loop, so you only need to define the handlers you use.
16. **Alignment of string literals**: the linker puts them in `.rodata` at 4-byte alignment by default. Use `ldr =label` to load their address.
17. **`section .bss`**: zero-filled; the startup code zeroes it. Declare uninitialised globals here.
18. **`section .data`**: initialised globals. Image in Flash, copy to RAM at reset.
19. **`const` globals** live in `.rodata` in Flash — no RAM cost.
20. **Watchdog**: not exercised in this course but available as `WDT` peripheral on nRF51.

---

# Glossary

- **AAPCS**: ARM Architecture Procedure Call Standard.
- **APSR**: Application Program Status Register (NZCV bits).
- **NVIC**: Nested Vectored Interrupt Controller (M-class IRQ hardware).
- **PendSV**: pendable service exception; used for deferred context switch.
- **SVC**: supervisor call, triggered by `svc #n`.
- **MSP / PSP**: Main / Process Stack Pointer.
- **PRIMASK**: global interrupt disable bit.
- **EXC_RETURN**: magic value loaded into lr on exception entry, used to decide which stack to pop.
- **RCA**: ripple-carry adder.
- **CLA**: carry-lookahead adder.
- **SOP / POS**: sum-of-products / product-of-sums.
- **FSM**: finite-state machine (Moore or Mealy).
- **IMAGE macro**: the compile-time LED-bit-pattern computer in `hardware.h`.

---

End of guide. If you need more depth on a specific algorithm (e.g. Booth multiplier, restoring vs non-restoring division, Wallace-tree multiplier, priority inheritance, or Moore-machine synthesis), grep this file for the keyword and follow the references; otherwise, drill the "exam traps" sections, work through Sheets 3-6 with pen-and-paper, and you should be in good shape.
