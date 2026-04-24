# Interrupts, Drivers & Messaging — Quick Study Guide

Oxford Digital Systems. Focus: microbian OS, UART/timer/I2C drivers, interrupt flow, messaging.

---

## 1. Hardware Register Naming Pattern

Every nRF51 peripheral has three kinds of registers:

| Kind | How to spot | What it does | How to use |
|------|-------------|--------------|------------|
| **Task** | name ends in verb: `_START`, `_STOP`, `_STARTTX`, `_CLEAR` | Writing `1` triggers an action in the hardware | `UART_STARTTX = 1;` |
| **Event** | name ends in noun/adjective: `_TXDRDY`, `_RXDRDY`, `_COMPARE[0]`, `_STOPPED` | Hardware sets it to `1` when something happens | Poll or interrupt on it; **must clear by writing 0** |
| **Register** | config names: `_ENABLE`, `_BAUDRATE`, `_INTENSET`, `_INTENCLR` | Persistent configuration | Read/write normally |

### Key UART variables decoded

```
UART_RXDRDY   event — goes 1 when a byte has arrived in the RX shift register
UART_RXD      register — the received byte; reading it does NOT clear RXDRDY
UART_TXDRDY   event — goes 1 when the transmitter has finished sending and is ready
UART_TXD      register — write a byte here to start transmitting it
UART_INTENSET register — set bits here to enable specific interrupts
UART_STARTTX  task   — write 1 to start the transmitter
UART_STARTRX  task   — write 1 to start the receiver

txidle        your software flag (not a hardware reg) — true when no transmission in progress
```

### The TXDRDY / txidle pattern (from serial.c and primes-intr.c)

```c
// Sending a character:
UART_TXD = ch;     // loads char into hardware; hardware sends it
txidle = 0;        // mark "transmitter busy"

// In the interrupt handler, when UART_TXDRDY fires:
if (UART_TXDRDY) {
    UART_TXDRDY = 0;         // clear event FIRST
    if (buffer_empty)
        txidle = 1;          // nothing more to send
    else
        UART_TXD = next_ch;  // keep the pipeline going
}
```

**Why txidle?** The hardware only generates one TXDRDY per byte. If you want to send a second byte immediately, you load it in the interrupt handler. If there's nothing to send, you set `txidle = 1` so the *next* call to `serial_putc` loads TXD directly instead of waiting for an interrupt that will never come.

---

## 2. Interrupt Flow in microbian

```
Hardware event occurs
  → hardware pushes {r0-r3, r12, lr, pc, psr} onto stack (8 words)
  → jumps to vector table entry → default_handler()

default_handler() {
    irq = active_irq();
    disable_irq(irq);          // ← stops the IRQ in NVIC so it won't fire again
    interrupt(os_handler[irq]); // sends INTERRUPT message to registered task
}

  → driver task wakes up, receives INTERRUPT message
  → calls its own interrupt handler function, which:
        reads/clears hardware events
        clears pending bit in NVIC:  clear_pending(irq)
        re-enables IRQ in NVIC:      enable_irq(irq)
```

### Why disable_irq then re-enable later?

The hardware can generate another event while the driver task is processing the first one. If IRQ stays enabled, `default_handler` fires again immediately and the INTERRUPT message queues up but the task won't read it until it finishes the first one. The pattern:

1. `default_handler` disables the IRQ at NVIC level — no more hardware interrupts from this source.
2. Sends INTERRUPT to the driver task.
3. Driver task handles the event, calls `clear_pending(irq)` (wipes any already-queued interrupt), then `enable_irq(irq)` to let new ones in.

The comment in serial.c explains an important subtlety:
> "The pending bit is cleared on return from the interrupt handler, but that doesn't stop the UART from setting it again."  
So `clear_pending` must be called *after* clearing the hardware event register, not before.

### Order in the interrupt handler function (driver-side)

```c
static void serial_interrupt(void) {
    // 1. Check and clear hardware event registers
    if (UART_RXDRDY) {
        char ch = UART_RXD;   // read data
        UART_RXDRDY = 0;      // clear event
        // ... process ch
    }
    if (UART_TXDRDY) {
        UART_TXDRDY = 0;
        txidle = 1;
    }
    // 2. Clear NVIC pending bit (in case hardware set it again during handling)
    clear_pending(UART_IRQ);
    // 3. Re-enable IRQ so future hardware events can fire
    enable_irq(UART_IRQ);
}
```

---

## 3. connect(), priority(), enable_irq() — what each does

```c
connect(UART_IRQ);    // registers THIS process as the handler for UART_IRQ
                      // also sets process priority to P_HANDLER (highest = 0)

priority(P_HANDLER);  // manually set priority (use if you want P_HANDLER but
                      // didn't call connect, e.g. timer_task)

enable_irq(UART_IRQ); // tells NVIC to pass UART interrupts to the CPU
                      // without this, hardware events never reach default_handler
```

**Calling pattern in a driver task:**
```c
void my_driver(int arg) {
    /* configure hardware first */
    UART_INTENSET = BIT(UART_INT_RXDRDY) | BIT(UART_INT_TXDRDY); // tell peripheral which events → IRQ
    connect(UART_IRQ);   // register & set P_HANDLER
    enable_irq(UART_IRQ); // arm NVIC
    // now the main loop
}
```

---

## 4. send vs sendrec vs receive — when to use each

### send(dst, &m)
- Fire and forget. Blocks until `dst` has received it, but expects no reply.
- Use when: notifying a task of an event, sending a character to serial, one-way data.
- The receiver must call `receive(type, &m)` at some point or you block forever.

```c
send_int(SERIAL_TASK, PUTC, ch);   // put char in serial queue; no reply expected
send_msg(client, REPLY);           // send a reply back (inside a driver)
```

### receive(type, &m)
- Block until a message of the given type arrives. `ANY` (`= -1`) accepts anything.
- Use when: you are the server waiting for requests, or a client waiting for a `PING`.

```c
receive(ANY, &m);         // driver main loop — accept any message
receive(INTERRUPT, NULL); // wait specifically for next interrupt (NULL = don't care about contents)
receive(PING, NULL);      // timer_wait() — sleep until next timer tick
receive(REPLY, &m);       // wait for a reply (rare — use sendrec instead)
```

### sendrec(dst, &m)
- Send a message, then block until `dst` sends back a `REPLY` message *into the same buffer*.
- Atomic: no other message can arrive in between.
- Use when: you need the answer before continuing (synchronous RPC).

```c
// Client side — serial_getc():
m.type = GETC;
sendrec(SERIAL_TASK, &m);
return m.int1;             // result is in m after sendrec returns

// Client side — i2c_xfer():
m.type = READ;
m.byte1 = addr; ...
sendrec(I2C_TASK[chan], &m);
return m.int1;             // status
```

The driver side must send back `REPLY`:
```c
m.type = REPLY;
m.int1 = result;
send(client, &m);          // driver sends REPLY back to unblock the client
```

**Why NOT send + receive separately?** There is a tiny window between `send` and `receive` where another message could arrive first. `sendrec` closes that window.

### Quick decision table

| Situation | Call |
|-----------|------|
| Telling serial to print a character | `send_int(SERIAL_TASK, PUTC, ch)` |
| Asking serial for the next character | `sendrec(SERIAL_TASK, &m)` |
| Waiting for a timer tick | `receive(PING, NULL)` |
| Waiting for any hardware event (driver loop) | `receive(ANY, &m)` |
| Sending result back to a client | `send(client, &m)` with `m.type = REPLY` |
| Client requesting I2C read | `sendrec(I2C_TASK[chan], &m)` |
| Setting up a repeating timer | `send(TIMER_TASK, &m)` — no reply needed |

---

## 5. When to disable/re-enable interrupts (and which mechanism)

There are **two different levels** of interrupt control. Know which to use.

### Level 1: Whole-CPU disable — `intr_disable()` / `intr_enable()`

```c
intr_disable();   // sets PRIMASK=1; stops ALL interrupts reaching CPU
/* critical section */
intr_enable();    // clears PRIMASK
```

Use when: a variable is shared between an ISR and normal code, and you need an atomic read-modify-write that can't be interrupted. Classic example from `primes-intr.c`:

```c
void serial_putc(char ch) {
    while (bufcnt == NBUF) pause();   // wait for space
    intr_disable();
    if (txidle) {
        UART_TXD = ch;   // start transmission
        txidle = 0;
    } else {
        buf_put(ch);     // add to buffer
    }
    intr_enable();
}
```

Without the critical section: the interrupt could fire *between* checking `txidle` and calling `buf_put`. The handler would see an empty buffer, set `txidle = 1`, then your code puts the char in the buffer — but nothing will ever send it.

**Don't use inside a microbian driver task** — the driver task already runs at P_HANDLER and won't be preempted by the interrupt it handles. Use `clear_pending` / `enable_irq` instead.

### Level 2: Per-IRQ disable — `disable_irq(irq)` / `enable_irq(irq)`

```c
disable_irq(UART_IRQ);   // clears bit in NVIC_ICER — only UART interrupts blocked
enable_irq(UART_IRQ);    // sets bit in NVIC_ISER
clear_pending(UART_IRQ); // clears bit in NVIC_ICPR — wipes a queued-but-not-yet-fired interrupt
```

Used by `default_handler` and re-enabled in the driver's interrupt function.

### When you DON'T need to disable interrupts

- Reading a single-word variable that is only written by one ISR (reads are atomic on M0).
- Inside a microbian driver at P_HANDLER (hardware interrupts can't preempt P_HANDLER tasks — the NVIC already disabled the IRQ before sending you the message).
- In the i2c driver: `i2c_wait()` calls `receive(INTERRUPT, NULL)` to wait, then re-enables the IRQ. It doesn't need `intr_disable` because it's the only task that ever touches I2C registers.

---

## 6. The volatile keyword — when required

```c
static volatile int txidle;     // shared between main code and ISR
static volatile char txbuf[];   // same
volatile uint32_t * const UART_RXDRDY = (volatile uint32_t*)0x40002108; // hardware reg
```

**Required when:**
- A variable is written by an ISR and read by main code (or vice versa).
- A variable maps to a hardware register (value can change without the CPU writing it).

**Not required when:**
- A variable is only used inside a single microbian task (no ISR touches it directly).
- You're in a driver task receiving messages — the message passing itself handles synchronisation.

**Common mistake:** forgetting `volatile` means the compiler might cache the value in a register and never re-read memory, so it never sees the ISR's update.

---

## 7. Driver task skeleton (complete pattern)

```c
static int MY_TASK;

static void my_task(int arg) {
    message m;

    /* 1. Configure hardware */
    MY_PERIPHERAL_ENABLE = 1;
    MY_PERIPHERAL_CONFIG  = ...;

    /* 2. Enable specific interrupts at peripheral level */
    MY_PERIPHERAL_INTENSET = BIT(MY_INT_EVENT1) | BIT(MY_INT_EVENT2);

    /* 3. Register with microbian and arm NVIC */
    connect(MY_IRQ);          // sets P_HANDLER, registers this pid
    enable_irq(MY_IRQ);

    while (1) {
        receive(ANY, &m);

        switch (m.type) {
        case INTERRUPT:
            /* Handle hardware events */
            if (MY_PERIPHERAL_EVENT1) {
                MY_PERIPHERAL_EVENT1 = 0;   // clear event
                /* do work */
            }
            clear_pending(MY_IRQ);
            enable_irq(MY_IRQ);
            break;

        case REQUEST:
            /* Serve a client */
            /* do work */
            m.type = REPLY;
            send(m.sender, &m);  // or use sendrec's implicit reply
            break;

        default:
            badmesg(m.type);
        }
    }
}

void my_init(void) {
    MY_TASK = start("MyDrv", my_task, 0, 256);
}
```

---

## 8. Timer driver specifics

The timer uses a separate `timer1_handler` function that is the *actual hardware ISR* (not a microbian task):

```c
void timer1_handler(void) {        // real ISR, runs in handler mode
    if (TIMER1_COMPARE[0]) {
        millis += TICK;
        TIMER1_COMPARE[0] = 0;     // clear event
        interrupt(TIMER_TASK);     // send INTERRUPT message to task
    }
}
```

The timer task does NOT call `connect()` for its IRQ — it calls `priority(P_HANDLER)` manually:
```c
priority(P_HANDLER);   // makes it high priority like a handler
enable_irq(TIMER1_IRQ); // arm NVIC
```

This is different from the serial/I2C pattern where the task itself calls `connect()`. For the timer, the hardware ISR sends the `interrupt()` message directly.

**timer_delay** vs **timer_pulse + timer_wait:**
```c
timer_delay(100);     // blocks for 100 ms, returns once (one-shot)

timer_pulse(5);       // register: fire every 5 ms, don't block
while (1) {
    timer_wait();     // blocks until next tick (= receive(PING, NULL))
    // do work every 5 ms
}
```

---

## 9. Message fields — what goes where

```c
typedef struct {
    unsigned short type;   // INTERRUPT, REPLY, PING, PUTC, GETC, READ, WRITE, …
    short sender;          // filled by kernel automatically
    union { int int1; void *ptr1; byte byte1, byte2, byte3, byte4; };
    union { int int2; void *ptr2; };
    union { int int3; void *ptr3; };
} message;
```

Examples from actual drivers:

```c
// serial_putc → SERIAL_TASK
m.type = PUTC;
m.int1 = ch;           // character to send

// print_buf → SERIAL_TASK  
m.type = PUTBUF;
m.ptr1 = buf;          // pointer to buffer
m.int2 = n;            // length

// timer_delay → TIMER_TASK
m.type = REGISTER;
m.int1 = msec;         // delay
m.int2 = 0;            // 0 = one-shot, nonzero = repeat period

// i2c_xfer → I2C_TASK
m.type = READ or WRITE;
m.byte1 = addr;        // I2C device address
m.byte2 = n1;          // command buffer length
m.byte3 = n2;          // data buffer length
m.ptr2 = buf1;         // command buffer
m.ptr3 = buf2;         // data buffer
```

---

## 10. Common traps and what goes wrong

### Forgetting to clear the hardware event register
If you return from the driver without clearing `UART_RXDRDY`, the UART immediately re-fires the interrupt. `default_handler` runs again, sends another INTERRUPT, and you get an infinite loop of INTERRUPT messages. Always `REG_EVENT = 0` before `clear_pending`.

### Forgetting clear_pending after clearing the event
Even after you write `UART_TXDRDY = 0`, the NVIC may already have the pending bit set (the hardware set it while the driver was processing). If you skip `clear_pending(IRQ)`, `enable_irq` re-arms an interrupt that fires *immediately* — spurious interrupt.

### Calling enable_irq but forgetting INTENSET
`enable_irq(UART_IRQ)` turns on the UART IRQ in the NVIC. But if the UART peripheral itself hasn't been told to generate interrupts (`UART_INTENSET` not set), the hardware never raises the IRQ line. Both must be set.

### Using send then receive instead of sendrec
```c
// WRONG — another message can arrive between send and receive
send(SERIAL_TASK, &m);
receive(REPLY, &m);    // might receive someone else's message

// RIGHT
sendrec(SERIAL_TASK, &m);
```

### Two processes waiting for input
`serial_getc` stores the waiting process PID in `reader`. If two processes both call `serial_getc`, the second one will set `reader` to its PID and the first will never be woken. The serial task panics: "Two clients cannot wait for input at once." Design: only one reader task.

### Not setting volatile on ISR-shared variables
The classic race from `primes-intr.c`:
```c
// Without intr_disable:
// main: checks txidle == 0, about to go to else branch
// ISR fires: buffer empty, sets txidle = 1
// main: puts char in buffer — nobody will ever send it
```

### Forgetting to re-enable IRQ in driver
After handling an INTERRUPT, if you forget `enable_irq(irq)`, no more interrupts from that device will ever arrive. The driver will receive no more INTERRUPT messages and silently hang.

### sendrec with REPLY type
`sendrec` panics if `msg->type == REPLY`. You can't use sendrec to send a reply — use plain `send`.

---

## 11. Priority — what matters for the exam

| Process | Priority | Effect |
|---------|----------|--------|
| Interrupt handler / driver task | P_HANDLER (0) | Preempts everything; woken by `interrupt()` call from ISR |
| Display / time-sensitive | P_HIGH (1) | Preempts P_LOW tasks |
| Normal application code | P_LOW (2) | Default; can starve at same priority |
| Idle | P_IDLE (3) | Only runs when nothing else can |

**Key rule:** Microbian only switches tasks at blocking system calls (`send`, `receive`, `sendrec`, `yield`). A P_LOW task that never calls these runs forever and starves everything at the same priority. To preempt it you need a P_HIGH task — a timer interrupt will wake the P_HIGH task and it will preempt via the PendSV mechanism.

**connect() sets P_HANDLER automatically.** You do not need to call `priority(P_HANDLER)` separately after `connect()`.

---

## 12. One-page cheat sheet

```
UART event registers:
  UART_RXDRDY   = 1 when byte received → read UART_RXD then UART_RXDRDY = 0
  UART_TXDRDY   = 1 when transmitter ready → means TXD is free, write UART_TXDRDY = 0

txidle (software):
  = 1  transmitter idle, next serial_putc writes TXD directly
  = 0  transmitter busy, put in buffer; ISR will drain it

Interrupt flow:
  HW fires → default_handler → disable_irq → interrupt(task_pid) → task receives INTERRUPT
  task handles → clear_pending(irq) + enable_irq(irq)

send(dst, &m)        one-way; blocks until received; NO reply expected
receive(type, &m)    wait for message of type (ANY = wildcard)
sendrec(dst, &m)     send + wait REPLY atomically; best for request-response

connect(irq)         registers as handler + sets P_HANDLER; call from driver task
enable_irq(irq)      arms NVIC; call AFTER connect
PERIPHERAL_INTENSET  arms peripheral; set BEFORE enable_irq
clear_pending(irq)   wipe queued NVIC interrupt; call at end of handling

Disable interrupts:
  intr_disable()/intr_enable()  ← whole CPU; use in bare-metal ISR-shared vars
  disable_irq/enable_irq        ← per-device; used by microbian internals

volatile needed:
  ✓ variable shared between ISR and normal code (bare-metal)
  ✓ hardware registers
  ✗ variables only used inside one microbian task
```
