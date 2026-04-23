# Lab 4: Operating Systems — Study Notes

## Overview

This lab introduces **micro:bian**, a minimal embedded OS kernel for the micro:bit (nRF51822, ARM Cortex-M0). The key idea is **concurrent processes** communicating via **message passing**, replacing the bare-metal polling/interrupts from earlier labs.

---

## Core OS Concepts

### Processes
- A **process** is an independent task with its own stack and program counter.
- Created with `start(name, body_fn, arg, stack_size)` — called from `init()` before the scheduler starts.
- Each process runs the function `body_fn(arg)` and can call `exit()` when done (or loop forever).
- Max 32 processes (`NPROCS`).
- Default stack size: `STACK = 1024` bytes.

### Process States
```
DEAD      → doesn't exist / has exited
ACTIVE    → ready to run (in a ready queue)
SENDING   → blocked, waiting for receiver to call receive()
RECEIVING → blocked, waiting for a message
SENDREC   → sent a message, waiting for REPLY
IDLING    → the special idle process
```

### Scheduler
- **Non-preemptive between system calls** — processes run until they call a system call (send/receive/yield) or a timer/interrupt triggers `cxt_switch`.
- **Priority-based**: lower number = higher priority.
  - `P_HANDLER = 0` (interrupt handlers)
  - `P_HIGH = 1` (responsive tasks, e.g., display)
  - `P_LOW = 2` (normal, default)
  - `P_IDLE = 3` (idle process only)
- Three ready queues (one per non-idle priority). `choose_proc()` picks the highest-priority non-empty queue head.
- Set priority at runtime: `priority(P_HIGH)` — called inside the task body.

### Context Switch
- Triggered by `SVC` instruction (system calls) or hardware interrupts via `cxt_switch`.
- `mpx-m0.s` contains the ARM assembly for saving/restoring registers.
- The exception frame (saved by hardware on SVC) holds r0–r3, r12, LR, PC, PSR. Microbian adds r4–r11 on top.

---

## Message Passing API (microbian.h)

### Message struct
```c
typedef struct {
    unsigned short type;   // message type (INTERRUPT, REPLY, REQUEST, etc.)
    short sender;          // PID of sender (filled in automatically)
    union { int int1; void *ptr1; ... };
    union { int int2; void *ptr2; };
    union { int int3; void *ptr3; };
} message;
```

### System Calls
| Call | What it does |
|------|-------------|
| `yield()` | Voluntarily give up CPU; go back to ready queue |
| `send(dst, &msg)` | Send message to process `dst`; block if receiver not ready |
| `receive(type, &msg)` | Block until a message of `type` arrives (use `ANY` for any) |
| `sendrec(dst, &msg)` | Send + wait for `REPLY` in one atomic operation |
| `exit()` | Terminate current process |
| `dump()` | Print process table to serial (for debugging) |
| `connect(irq)` | Register current process to receive INTERRUPT messages for an IRQ |
| `priority(p)` | Set current process priority |

### Convenience send wrappers
```c
send_msg(dst, type);           // send with just a type
send_int(dst, type, val);      // send with an integer payload
send_ptr(dst, type, ptr);      // send with a pointer payload
```

### Message types (common constants)
```
INTERRUPT, REPLY, TIMEOUT, REGISTER, PING,
REQUEST, READ, WRITE, OK, ERR, SEND, RECEIVE
ANY = -1  (wildcard for receive)
```

---

## Device Driver API

### Serial (serial.c)
```c
void serial_init();         // call once in init()
void serial_putc(char ch);  // send one character (blocking)
char serial_getc();         // receive one character (blocking)
```
- `printf()` from lib.c uses `serial_putc` internally.
- The serial driver is itself a task — `printf` sends messages to it.

### Timer (timer.c)
```c
void timer_init();
void timer_delay(int msec);   // block for msec milliseconds
void timer_pulse(int msec);   // start a pulse (non-blocking)
void timer_wait();            // wait for pulse to complete
unsigned timer_now();         // current time in ms
unsigned timer_micros();      // current time in microseconds
```

### I2C (i2c.c) — for accelerometer
```c
void i2c_init(int chan);                              // I2C_INTERNAL
int  i2c_probe(int chan, int addr);                   // scan for device
int  i2c_read_reg(int chan, int addr, int cmd);
void i2c_write_reg(int chan, int addr, int cmd, int val);
void i2c_read_bytes(int chan, int addr, int cmd, byte *buf, int n);
```

### Radio (radio.c)
```c
void radio_init();
void radio_group(int group);          // set group (0–255), isolates broadcasts
void radio_send(void *buf, int n);    // send up to 32 bytes
int  radio_receive(void *buf);        // receive, returns length; buf = RADIO_PACKET bytes
```
- `RADIO_PACKET = 128` (max buffer size)
- All micro:bits on the same group receive each broadcast.

### Display (display.c)
```c
void display_init();
void display_show(const unsigned *img);   // set display to an image
extern const unsigned blank[];             // all-off image
void image_clear(unsigned *img);
void image_set(int x, int y, unsigned *img);  // x,y in 0..4
typedef unsigned image[3];                 // 3 row-packed unsigned ints
```
- `IMAGE(...)` macro (in hardware.h) packs a 5×5 grid into 3 unsigned ints.

---

## Example Programs

### ex-heart.c — Two concurrent tasks
**What it does:** `heart_task` multiplexes the LED display (beating heart), `prime_task` computes primes and prints them serially. Both run concurrently.

**Key code:**
```c
void heart_task(int n) {
    GPIO_DIRSET = 0xfff0;
    // Set high-drive on row pins
    priority(P_HIGH);   // <-- IMPORTANT: makes display responsive
    while (1) {
        show(heart, 70);
        show(small, 10);
        ...
    }
}

void init(void) {
    serial_init();
    timer_init();
    start("Heart", heart_task, 0, STACK);
    start("Prime", prime_task, 0, STACK);
}
```

**Task S3 — Priority question:**
- Without `priority(P_HIGH)`, both tasks are `P_LOW`.
- `prime_task` is CPU-bound (no blocking calls); it never yields voluntarily.
- The scheduler can only switch on system calls — `prime_task` hogs the CPU, starving `heart_task`.
- With `P_HIGH`, `heart_task` preempts `prime_task` whenever there's a timer interrupt, keeping display smooth.
- **Answer:** The display task needs higher priority to ensure it runs on schedule (every 5ms per row) regardless of CPU-bound background work.

**`show()` function:**
```c
void show(const unsigned *img, int n) {
    while (n-- > 0) {
        for (int p = 0; p < 3; p++) {
            GPIO_OUT = img[p];   // drive one row
            timer_delay(5);      // wait 5ms (blocks, yields CPU)
        }
    }
}
```
- Each call to `timer_delay(5)` is a blocking system call → gives CPU to other processes.

---

### ex-echo.c — Simple UART test
**What it does:** Reads a line from serial, prints it back with length.

```c
void read_line(char *buf) {
    char *p = buf;
    for (;;) {
        char ch = serial_getc();   // blocks waiting for character
        if (ch == '\n') break;
        *p++ = ch;
    }
    *p = '\0';
}

void echo_task(int n) {
    printf("Hello\n");
    while (1) {
        read_line(line);
        printf("--> %s (%d)\n", line, strlen(line));
    }
}
```
- `serial_getc()` is a blocking receive — process sleeps until a character arrives via UART interrupt.

---

### ex-race.c — Scheduling non-determinism
**What it does:** `proc2` increments `r` to 100000; `proc1` prints `r` 10 times. Order of `start()` calls in `init()` matters.

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
```

**Task S2 — Why does swapping start() order matter?**
- `start()` adds processes to the **tail** of the ready queue at `P_LOW`.
- Both processes start at `P_LOW`. Whichever is started first is at the **head** and runs first.
- Original order: Proc1 starts first → runs first → `printf` blocks on serial → Proc2 gets CPU → increments `r` until 100000 → Proc1 gets CPU back after each serial write. The values of `r` printed depend on exactly when Proc1 regains the CPU after each serial send.
- Swapped: Proc2 runs first → may reach 100000 (or partway) before Proc1 ever runs → Proc1 then prints values all close to or at 100000.
- **Why consistent run-to-run?** The micro:bit has no cache variability, no OS scheduler jitter, deterministic clock. Same hardware + same code → same timing every boot. Results are determined by instruction counts, not wall-clock randomness.

---

### ex-today.c — Mutual exclusion problem
**What it does:** Two politician processes (`May`, `Farage`) print slogans simultaneously → output is garbled (interleaved characters).

```c
char *slogan[] = {
    "no deal is better than a bad deal\n",
    "BREXIT MEANS BREXIT!\n"
};

void process(int n) {
    while (1) { put_string(slogan[n]); }
}
```
- `put_string` calls `serial_putc` per character. Each character send blocks briefly → scheduler may switch mid-slogan.

**Task S1 — Add an interviewer process:**

**Option A — Politicians send full slogans to interviewer:**
```
politician → send slogan pointer → interviewer → print → send REPLY → repeat
```
- Politicians block after send until interviewer is done. Natural serialization.

**Option B — Interviewer grants permission:**
```
interviewer → send PERMIT → politician → print → send DONE → interviewer → next politician
```
- Interviewer acts as a mutex/semaphore, granting turns one at a time.

**Key concept:** Message passing enforces mutual exclusion — only one process can hold the "token" at a time.

---

### ex-level.c — I2C accelerometer + display
**What it does:** Reads X/Y acceleration, maps to a pixel position, shows a moving dot as a spirit level.

```c
static int scale(int x) {
    if (x < -20) return 4;
    if (x < -10) return 3;
    if (x <= 10) return 2;
    if (x <= 20) return 1;
    return 0;
}

while (1) {
    timer_delay(200);
    accel_reading(&x, &y, &z);
    x = scale(x); y = scale(y);
    light(x, y);   // display single pixel at (x, y)
}
```
- Uses `I2C_INTERNAL` channel to talk to the onboard MMA8653 accelerometer.
- `i2c_map()` scans the I2C bus and prints addresses of found devices (useful for debugging).
- `display_show()` drives the LED matrix via GPIO.

**Initialisation pattern:**
```c
void init(void) {
    serial_init();
    timer_init();
    i2c_init(I2C_INTERNAL);
    display_init();
    start("Main", main, 0, STACK);
}
```

---

### ex-remote.c — Radio communication
**What it does:** Two tasks — `sender_task` polls buttons and broadcasts, `receiver_task` receives packets and shows A or B on display.

```c
#define GROUP 17   // isolates from other groups in the room

void sender_task(int dummy) {
    while (1) {
        if (GET_BIT(GPIO_IN, BUTTON_A) == 0) {
            radio_send("1", 1);
        } else if (GET_BIT(GPIO_IN, BUTTON_B) == 0) {
            radio_send("2", 1);
        }
        timer_delay(100);   // debounce + yield
    }
}

void receiver_task(int dummy) {
    while (1) {
        n = radio_receive(buf);   // blocks until packet arrives
        if (n == 1 && buf[0] == '1') display_show(letter_A);
        else if (n == 1 && buf[0] == '2') display_show(letter_B);
    }
}
```
- `radio_receive` is blocking — receiver task sleeps until a packet arrives via radio interrupt.
- Button pins need `GPIO_PINCNF[pin] = 0` to enable input (no pull-up/down).
- All micro:bits in the same group receive all broadcasts (no addressing by default).

**S+ extension idea:** Add a destination byte at `buf[0]`, payload at `buf[1..n]`. Each micro:bit checks `buf[0]` against its own ID and ignores packets not addressed to it.

---

## microbian.c Internals (for understanding)

### Process descriptor (`struct _proc`)
```c
struct _proc {
    int pid;           // process ID (= index in os_ptable)
    char name[16];
    unsigned state;    // DEAD/ACTIVE/SENDING/RECEIVING/SENDREC/IDLING
    unsigned *sp;      // saved stack pointer
    void *stack;       // base of stack allocation
    unsigned stksize;
    int priority;
    proc waiting;      // linked list of processes waiting to send to this one
    int pending;       // hardware interrupt pending flag
    int filter;        // message type filter for receive
    message *msgbuf;   // pointer to caller's message buffer
    proc next;         // next in ready queue or sender queue
};
```

### Memory layout
- Stack space grows **up** from `__end` (end of BSS).
- Process descriptors are allocated **down** from `__stack_limit`.
- Deliberate separation so stack overflow is less likely to corrupt descriptors.
- Stack filled with `0xdeadbeef` sentinel; overflow detected when the sentinel is overwritten.

### How send/receive works
1. **send(dst, msg)**: If `dst` is already waiting in `receive()` for this message type → deliver immediately, both become ACTIVE. Otherwise → sender state = SENDING, joins dst's `waiting` queue. `choose_proc()` picks next process.
2. **receive(type, msg)**: If a matching sender is already queued → deliver immediately. Otherwise → state = RECEIVING, filter = type. `choose_proc()` picks next process.
3. **sendrec(dst, msg)**: Atomically send + wait for `REPLY`. Used for request-reply patterns (e.g., driver calls). Prevents a race where a reply arrives between the send and receive.

### Interrupt handling
- `connect(irq)` registers current process; sets priority to `P_HANDLER`.
- On interrupt: `default_handler()` disables the IRQ, calls `interrupt(pid)` which delivers an `INTERRUPT` message to the handler process.
- Handler process re-enables the IRQ after handling.
- Driver processes (serial, timer, i2c, radio) all use this pattern internally.

---

## Lab Tasks Summary

### Task S1: Today (Mutual Exclusion)
- **Problem:** Two processes interleave output → garbled text.
- **Fix:** Add a third "interviewer" process. Politicians must get permission or pass through the interviewer before printing.
- **Mechanism:** `send`/`receive` message passing.

### Task S2: Race (Scheduling)
- **Observe:** Values of `r` printed depend on process start order.
- **Swap start() order:** The first-started process runs first (at head of P_LOW queue). This changes how much Proc2 has incremented `r` before Proc1 gets CPU.
- **Consistent results:** Deterministic hardware + no OS jitter = same schedule every run.

### Task S3: Heart (Priority)
- **Remove `priority(P_HIGH)`:** Both tasks at P_LOW. Prime task (no yields) starves display task → display freezes or flickers badly.
- **Start primes at 1000000:** Much more work per prime → even more starvation without priority.
- **Reinstate:** Display runs reliably because P_HIGH preempts P_LOW on timer interrupts.
- **Why high priority for display?** Real-time constraint: each row must be refreshed every ~5ms for smooth multiplexed display. A CPU-bound background task must not be able to delay this.

### S+ Task: Radio Application
- Use `radio_send`/`radio_receive` with a structured packet (destination + payload).
- Example: chain reaction game — pressing a button sends a message to the "next" micro:bit, which then sends to the next, etc.

---

## Common Patterns

### Initialise all drivers in init()
```c
void init(void) {
    serial_init();   // always needed for printf
    timer_init();    // needed for timer_delay
    // add: i2c_init, radio_init, display_init as needed
    start("TaskName", task_fn, arg, STACK);
}
```

### Task with high priority
```c
void display_task(int n) {
    priority(P_HIGH);   // call early in task body
    while (1) { ... }
}
```

### Request-reply with sendrec
```c
// Client:
message m;
m.type = REQUEST;
m.int1 = value;
sendrec(server_pid, &m);   // blocks until server replies
// m now contains the REPLY

// Server:
message m;
receive(REQUEST, &m);
int val = m.int1;
int client = m.sender;
m.type = REPLY;
m.int1 = result;
send(client, &m);
```

### Interrupt-driven driver pattern
```c
void driver_task(int n) {
    connect(IRQ_NUMBER);   // register for interrupts, sets P_HANDLER
    // init hardware
    while (1) {
        message m;
        receive(ANY, &m);
        if (m.type == INTERRUPT) {
            // handle hardware event
            enable_irq(IRQ_NUMBER);   // re-enable for next interrupt
        } else if (m.type == REQUEST) {
            // handle request from user process
        }
    }
}
```
