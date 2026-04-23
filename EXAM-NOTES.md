# Digital Systems — Exam Notes

Oxford, Trinity Term. ARM Cortex-M0 / nRF51822 / microbian / digital logic / datapath.

---

## 1. Registers & Flags

### Register file
| Reg | Alt | Role |
|-----|-----|------|
| r0–r3 | a1–a4 | args in, return out, caller-saved |
| r4–r11 | v1–v8 | callee-saved — you must push/pop these |
| r12 | ip | caller-saved scratch |
| r13 | sp | stack pointer, full-descending, 8-byte aligned |
| r14 | lr | link register — `bl` stores return address here |
| r15 | pc | program counter — reads as **current + 4** |

r0–r7 = "low registers" (most Thumb instructions). r8–r12 = "high" (only `mov`, `add`, `cmp`, `bx`, push/pop).

### NZCV flags (APSR)
| Flag | Set when |
|------|----------|
| N | result bit 31 = 1 (negative) |
| Z | result = 0 |
| C | unsigned carry out of add; NOT-borrow for sub/cmp (C=1 means a≥b) |
| V | signed overflow |

Only `s`-suffix instructions set flags: `adds movs lsls ands` …  
`cmp cmn tst` always set flags (no non-`s` form).

**C vs V trap**: `0xFFFFFFFF + 1` → C=1, V=0. `0x7FFFFFFF + 1` → C=0, V=1.  
After `cmp r0, r1` (= `r0 − r1`): C=1 means r0 ≥ r1 (unsigned).

---

## 2. Thumb Instructions

```
Data:   movs  adds  subs  muls  adcs  sbcs  rsbs Rd,Rn,#0
Logic:  ands  orrs  eors  bics  mvns
Shift:  lsls  lsrs  asrs  rors
Cmp:    cmp   cmn   tst

Load:   ldr  ldrh  ldrsh  ldrb  ldrsb
Store:  str  strh         strb
Multi:  push {r4,r5,lr}   pop {r4,r5,pc}
        ldmia Rn!, {..}   stmia Rn!, {..}

Branch: b  b<cond>  bl  bx  blx
System: svc  bkpt  wfi  nop  cpsid i  cpsie i
```

### Addressing modes
```
ldr r0, [r1]          base
ldr r0, [r1, #12]     base + immediate offset (word-aligned for ldr)
ldr r0, [r1, r2]      base + register offset
ldr r0, [r1, #4]!     pre-index (update r1 after)
ldr r0, [r1], #4      post-index (update r1 after)
ldr r0, =0x12345678   load literal (assembler puts value in literal pool)
adr r0, label         PC-relative address (within ±1KB)
```

### Condition codes
`eq ne  cs/hs cc/lo  mi pl  vs vc  hi ls  ge lt  gt le`  
Unsigned comparisons use: `hi lo hs ls`  
Signed comparisons use: `ge lt gt le mi pl`

---

## 3. Calling Convention (AAPCS)

- **Args**: r0, r1, r2, r3 then stack.
- **Return**: r0 (64-bit: r0=low word, r1=high word).
- **Caller saves**: r0–r3, r12 (can be trashed by callee).
- **Callee saves**: r4–r11 (must push at start, pop before returning).
- Stack 8-byte aligned at any public function call boundary.

**Leaf function** (calls nothing):
```asm
myfunc: adds r0, r0, r1
        bx   lr             @ no push needed
```

**Non-leaf function** (calls something):
```asm
myfunc: push {r4, r5, lr}   @ save lr or it gets clobbered by bl
        ...
        bl   other
        ...
        pop  {r4, r5, pc}   @ restore and return
```

---

## 4. Memory Map & Startup

```
0x00000000  Flash (code, .rodata)
0x20000000  RAM (.data, .bss, stack)
0x40000000  Peripherals (memory-mapped registers)
0xE0000000  System (NVIC, SysTick, SCB)
```

**Vector table** (starts at 0x0):
- Word 0: initial stack pointer value
- Word 1: reset handler address (**must have bit 0 set** = Thumb bit)
- Words 2+: other exception handlers

**Boot sequence**: reset → load sp from word 0 → load pc from word 1 → reset handler runs → copies `.data` from Flash → zeros `.bss` → calls `init()` / `main()`.

**Sections**:
- `.text` / `.rodata` → Flash, no RAM cost
- `.data` → initialised globals; image in Flash, copied to RAM at reset
- `.bss` → uninitialised globals; zeroed at reset

---

## 5. C for Embedded

### `volatile`
Required when a variable can change outside the compiler's view:
- Hardware registers: `volatile uint32_t * const TIMER = (volatile uint32_t*)0x40008000;`
- ISR-shared variables: `static volatile int flag;`
- Does **not** mean atomic. Use critical sections for read-modify-write.

### Bit manipulation
```c
x |=  (1u << n)     // set bit n
x &= ~(1u << n)     // clear bit n
x ^=  (1u << n)     // toggle bit n
(x >> n) & 1        // test bit n
x = (x & ~mask) | (val << shift)  // set field
```

### Hardware register pattern
```c
#define TIMER_BASE  0x40008000
#define TIMER_START (*(volatile uint32_t*)(TIMER_BASE + 0x000))
#define TIMER_CC0   (*(volatile uint32_t*)(TIMER_BASE + 0x540))

TIMER_START = 1;     // write 1 to TASKS_START
while (!TIMER_CC0);  // poll EVENTS_COMPARE[0]
TIMER_CC0 = 0;       // clear event
```

---

## 6. nRF51 Peripherals

### General pattern
```
configure pins → set parameters → TASK_START → wait EVENTS_x → clear event → repeat
```

### GPIO
```c
GPIO_DIRSET = (1u << pin);       // set pin as output
GPIO_OUT |= (1u << pin);         // set pin high
GPIO_OUT &= ~(1u << pin);        // set pin low
GPIO_IN & (1u << pin)            // read pin (active-low buttons: 0 = pressed)
GPIO_PINCNF[pin] = 0;            // enable input (no pull)
```

### UART
```c
UART_PSELTXD  = USB_TX;          // pin select
UART_PSELRXD  = USB_RX;
UART_BAUDRATE = UART_BAUD_9600;
UART_ENABLE   = 4;
UART_TASK_STARTTX = 1;
UART_TASK_STARTRX = 1;
// Send one byte:
UART_TXD = ch;
while (!UART_EVENT_TXDRDY);
UART_EVENT_TXDRDY = 0;           // MUST clear or it fires again
```

### Timer
```c
TIMER0_PRESCALER = 4;            // 16 MHz / 2^4 = 1 MHz
TIMER0_CC[0]     = 1000;         // compare at 1000 µs
TIMER0_SHORTS    = 1;            // auto-clear on compare
TIMER0_TASK_START = 1;
while (!TIMER0_EVENT_COMPARE[0]);
TIMER0_EVENT_COMPARE[0] = 0;
```

### LED matrix
- 5×5 LEDs, 3 row-select lines, 9 col-select lines, packed into GPIO bits.
- Display one row at a time (multiplex): set `GPIO_OUT = img[row]`, wait 5 ms, repeat.
- `IMAGE(r0c0, r0c1, …, r4c4)` macro packs 25 bits into 3 unsigned ints.
- Minimum refresh ~60 Hz → 3 rows × 5.5 ms ≈ 16 ms per frame.

---

## 7. Interrupts & Exceptions

### What the hardware does on interrupt
1. Pushes r0–r3, r12, lr, pc, psr onto the stack (exception frame, 8 words).
2. Sets pc = vector table entry for that IRQ.
3. ISR runs in Handler mode on MSP.
4. `bx EXC_RETURN` (`0xFFFFFFFD`) returns, hardware pops the frame.

### Writing an ISR
```c
void UART_IRQHandler(void) {
    if (UART_EVENT_RXDRDY) {
        UART_EVENT_RXDRDY = 0;    // clear FIRST, then read
        buf[head++ & MASK] = UART_RXD;
    }
}
```
- Clear event **before** reading data, or interrupt fires again immediately.
- Don't call `printf` from an ISR (deadlock risk with buffered UART driver).
- `volatile` on every variable the ISR shares with main.

### Critical sections
```c
cpsid i          // disable IRQs (in assembly)
/* read-modify-write shared var */
cpsie i          // re-enable
```
In C: `__disable_irq()` / `__enable_irq()`.

### NVIC
```c
NVIC_ISER[0] = (1u << irqn);    // enable IRQ n
NVIC_ICER[0] = (1u << irqn);    // disable
NVIC_ICPR[0] = (1u << irqn);    // clear pending
```

---

## 8. MicrobiΛn OS

### Core idea
All code runs as **processes** communicating by **message passing**. No shared memory between processes (use messages instead). The kernel is a thin layer; each driver is a process.

### Process lifecycle
```c
void init(void) {
    serial_init();     // start serial driver process
    timer_init();      // start timer driver process
    start("Task", task_fn, arg, STACK);  // create process
}                      // kernel starts after init() returns
```
- `STACK = 1024` bytes per process. Max 32 processes.
- Processes start at `P_LOW` by default.

### Priority
| Constant | Value | Used for |
|----------|-------|----------|
| P_HANDLER | 0 | interrupt-side of drivers |
| P_HIGH | 1 | display, responsive tasks |
| P_LOW | 2 | application code, default |
| P_IDLE | 3 | idle process only |

Lower number = higher priority. Call `priority(P_HIGH)` inside a task body to raise it.

### System calls (= yield points)
```c
send(dst, &m)         // block until dst receives
receive(type, &m)     // block until message of type arrives (ANY = wildcard)
sendrec(dst, &m)      // send + wait for REPLY — one round trip, atomic
yield()               // give up CPU voluntarily
timer_delay(ms)       // block for ms milliseconds
```
**These are the only points where the scheduler can switch tasks.**  
A CPU-bound task that never calls any of these will run forever.

### Message struct
```c
typedef struct {
    unsigned short type;    // INTERRUPT, REPLY, PING, REQUEST, ANY, …
    short          sender;  // filled by kernel
    union { int int1; void *ptr1; };
    union { int int2; void *ptr2; };
    union { int int3; void *ptr3; };
} message;

// convenience wrappers
send_msg(dst, type);
send_int(dst, type, val);
send_ptr(dst, type, ptr);
```

### The three lab tasks

**S1 — ex-today.c (mutual exclusion)**  
Two politicians interleave `put_string` → garbled output. Fix: interviewer process holds a token.
```c
void process(int n) {
    while (1) {
        receive(PING, NULL);        // wait for permission
        put_string(slogan[n]);
        send_msg(INTERVIEWER, REPLY);
    }
}
void interviewer(int may_pid) {
    int far_pid = may_pid + 1;
    while (1) {
        send_msg(may_pid, PING);  receive(REPLY, NULL);
        send_msg(far_pid, PING);  receive(REPLY, NULL);
    }
}
```

**S2 — ex-race.c (scheduler order)**  
`start()` puts a process at the tail of the P_LOW queue. First `start()` → head → runs first.  
Swapping the two `start()` calls changes which process runs first → different values of `r` when `proc1` prints.  
Results are **identical every boot** because M0 has no cache jitter or OS noise — pure deterministic timing.

**S3 — ex-heart.c (priority)**  
`priority(P_HIGH)` is currently **commented out** in the file. Without it:
- Both `heart_task` and `prime_task` are P_LOW.
- `prime_task` never calls a blocking syscall → never yields → hogs CPU.
- `heart_task` never gets to call `timer_delay(5)` → display row never advances → **screen freezes**.  

Fix: call `priority(P_HIGH)` early in `heart_task`. Now every timer interrupt wakes it and it preempts `prime_task`.

### Driver pattern
```c
void my_driver(int arg) {
    connect(IRQ_NUM);          // register for INTERRUPT messages; sets P_HANDLER
    /* init hardware */
    while (1) {
        message m;
        receive(ANY, &m);
        switch (m.type) {
        case INTERRUPT:
            /* handle hardware, re-enable IRQ */
            break;
        case REQUEST:
            /* serve client, send REPLY */
            send(m.sender, &m);
            break;
        }
    }
}
```

### S+ — Hot Potato (potato.c)
Four tasks: receiver, sender, heat, display — all P_LOW. Shared state via `volatile` globals (`has_potato`, `heat_level`, `game_over`, `round_time`). Safe here because context-switches only happen at `timer_delay` / `radio_receive`. In a rigorous design, shared state would live in a dedicated server task.

---

## 9. Digital Logic

### Boolean algebra identities to know
```
a + a'  = 1       a · a' = 0
a + 1   = 1       a · 0  = 0
a + ab  = a       a(a+b) = a        (absorption)
a + a'b = a + b                      (covering)
ab + a'c + bc = ab + a'c             (consensus — bc is redundant)
De Morgan: (ab)' = a'+b'   (a+b)' = a'b'
```

### K-maps
1. Fill from truth table. 2. Group cells in **powers of 2** (1, 2, 4, 8, 16). 3. Largest group first. 4. Wrap edges. 5. Include don't-cares in groups if they make them larger. 6. Each group → one product term (variables that don't change drop out).

4-variable example: `f = Σm(0,2,5,7,8,10,13,15)` — draw it, group corners, get SOP.

### NAND universality
```
NOT a        = NAND(a, a)
AND(a,b)     = NAND(NAND(a,b), NAND(a,b))
OR(a,b)      = NAND(NAND(a,a), NAND(b,b))
SOP → NAND-NAND: f = AB + CD = NAND(NAND(A,B), NAND(C,D))
```

### D flip-flop
- `Q+ = D` on rising clock edge. Output stable otherwise.
- **Setup time** `t_su`: D must be stable this long *before* clock edge.
- **Hold time** `t_h`: D must stay stable this long *after* clock edge.
- **Clock-to-Q** `t_cq`: delay from clock edge to Q changing.
- Timing constraint: `T_clk ≥ t_cq + t_prop + t_su`

### FSM synthesis
1. State diagram → state table (current state, input → next state, output).
2. Assign binary state codes.
3. Next-state equations: K-map per flip-flop input.
4. Output equations: K-map (Moore: output depends on state only; Mealy: state + input).

**Moore vs Mealy**: Mealy output reacts immediately to input → faster but glitchy. Moore output only changes on clock edge → cleaner. Mealy usually needs fewer states.

Sequence detector 0110 (Mealy):
```
S0 →0→ S1   S0 →1→ S0
S1 →0→ S1   S1 →1→ S2
S2 →0→ S3   S2 →1→ S3? no: S2 →1→ S3 wait...
```
(draw it: one state per prefix of the pattern)

### Adders
**Full adder**: `S = a⊕b⊕cin`   `Cout = ab + (a⊕b)·cin`

**Ripple-carry**: chain full adders, carry ripples through all n bits. Delay = O(n).

**Carry-lookahead**:  
`p_i = a_i ⊕ b_i` (propagate)  `g_i = a_i · b_i` (generate)  
`c_{i+1} = g_i + p_i·c_i` — expand recursively to eliminate ripple.  
Group P/G: `G = g_{n-1} + p_{n-1}·g_{n-2} + … `   `P = p_{n-1}·p_{n-2}·…·p_0`  
Delay = O(log n).

---

## 10. CPU Datapath

### Single-cycle stages
```
Fetch → Decode/RegRead → Execute (ALU) → Memory → Writeback → PC+2
```

### Control signals
| Signal | 0 / off | 1 / on |
|--------|---------|--------|
| cAluSrc | second operand = register | second operand = immediate |
| cMemRd | no memory read | read data memory (ldr) |
| cMemWr | no memory write | write data memory (str) |
| cRegWrite | don't write register | write result to register file |
| cWFlags | don't update flags | update NZCV |
| cPcSrc | PC ← PC+2 | PC ← branch target / register |

### Instruction → control signals
| Instruction | cAluSrc | cMemRd | cMemWr | cRegWrite | cWFlags | cPcSrc |
|-------------|---------|--------|--------|-----------|---------|--------|
| `adds Rd, Rn, Rm` | reg | 0 | 0 | 1 | 1 | pc+2 |
| `adds Rd, Rn, #i` | imm | 0 | 0 | 1 | 1 | pc+2 |
| `cmp Rn, Rm` | reg | 0 | 0 | **0** | 1 | pc+2 |
| `ldr Rd, [Rn, #]` | imm | 1 | 0 | 1 | 0 | pc+2 |
| `str Rt, [Rn, #]` | imm | 0 | 1 | **0** | 0 | pc+2 |
| `b label` | — | 0 | 0 | 0 | 0 | branch |
| `beq label` | — | 0 | 0 | 0 | 0 | cond |
| `bl label` | — | 0 | 0 | lr←pc+2 | 0 | branch |
| `bx Rm` | — | 0 | 0 | 0 | 0 | Rm |

### Pipelining hazards
- **Data hazard**: instruction needs a result not yet written back. Fix: forwarding (bypass) or stall (NOP).
- **Control hazard**: branch destination unknown until execute stage. Fix: flush pipeline, predict not-taken, or delayed branch.
- **Structural hazard**: two instructions need the same hardware unit. Fix: separate instruction/data memories.

---

## 11. Quick Traps List

1. **Reset vector bit 0 must be 1** (Thumb bit). Hardware clears it before use.
2. **Clear peripheral event before returning from ISR** or it fires again.
3. **`cmp` doesn't write a register** (`cRegWrite = 0`).
4. **`str` doesn't write a register** (`cRegWrite = 0`).
5. **`ldr r0, =x` ≠ `ldr r0, [x]`** — former loads a value/address, latter loads from memory.
6. **Non-leaf must push lr** — `bl` overwrites it.
7. **`volatile` doesn't mean atomic** — still need critical sections for multi-step updates.
8. **MicrobiΛn only switches at blocking syscalls** — a busy loop starves everything at equal priority.
9. **C = NOT-borrow after subtraction** — after `cmp r0, r1`: C=1 means r0 ≥ r1.
10. **V = signed overflow, C = unsigned carry** — independent, both can be set simultaneously.
11. **Stack is full-descending** — sp points to the last written word; push decrements first.
12. **Mealy output can glitch** mid-cycle; Moore output only changes on clock edge.
13. **`sendrec` is atomic** — use it for request-reply; `send` then `receive` has a TOCTOU gap.
14. **First `start()` call = head of ready queue = runs first**.
15. **Consensus theorem**: `bc` is redundant in `ab + a'c + bc = ab + a'c`.
