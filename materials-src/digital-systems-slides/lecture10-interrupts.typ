#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)

#title-slide(title: [Lecture 10 \ Programming with Interrupts])


/*#slide[
  == More Chocolate
  #grid(columns: (1fr, 1fr), 
  [  #set align(center)
#image("./figures/riddle-train-zoom-out.jpeg", height:78%)], [  #set align(center)
#image("./figures/riddle-train-zoom-in.jpeg", height:78%)])
  What is going on here? Chocolate for the best hypothesis.
]*/

#slide[
  #item-by-item[
  #callout_question[Do we need to wait around while UART is transmitting?][
    What is the point of having hardware to handle receiving/transmission, if the CPU will just wait around until it's done anyway?
  ]
  #v(0.5cm)
    ```c
void serial_putc(char ch) {
    while (! UART_TXDRDY) { /* idle */ } UART_TXDRDY = 0;
    UART_TXD = ch;
}
  ```
  #v(0.5cm)
  #callout_idea[Hardware should operate at the same time as CPU is executing useful instructions.][
    There was a _tiny_ bit of parallelism: The last character to be sent!
  ]
]
]

#slide[
  == Today
  #item-by-item[
  #callout_question[How can we respond to events (that hardware notices), without making the software do nothing while it waits?][]
  #[We will consider various solutions, keeping in mind _design constraints_.] #[We want:]
  - to avoid making the CPU wait until some event occurs in hardware,
  - to be able to deal with many different types of events (not just UART, but e.g. also noticing when a button is pressed),
  - to have a minimal waiting time to respond to an event,
  - software that is modular, in the sense that it doesn't need to be adapted when other parts of the program change which events they deal with.
]
]

#slide[
  == One Possible Solution
  #item-by-item[
  - `serial_putc()` no longer waits and sends character.
  - Instead, it places a character in a buffer.
  - Throughout the program, check if UART is ready, and send character if so.
  ```c
#define NBUF 64
static int bufcnt = 0;
static int bufin = 0;
static int bufout = 0;
static char txbuf[NBUF];
```
]
]


#slide[
  == Circular Buffer
  #image("./figures/circular-buffer.png", height: 69%)
  - Add characters at `bufin`.
  - Send characters from `bufout`.
]

#slide[
  == One Possible Solution
  ```c
void serial_putc(char ch) {
  while (bufcnt == NBUF) { pause(); }   // Buffer is full...
  txbuf[bufin] = ch; bufcnt++;
  bufin = (bufin+1) % NBUF;
}
```
  #image("./figures/polling-throughout.png", height: 49%)
]

#slide[
  == What do we think of this solution?
  #item-by-item[
  #[We want:]
  - ✅ to avoid making the CPU wait until some event occurs in hardware, 
  - ❓ to be able to deal with many different types of events (not just UART, but e.g. also noticing when a button is pressed), 
  - ❓ to have a minimal waiting time to respond to an event,
  - ❌ software that is modular, in the sense that it doesn't need to be adapted when other parts of the program change which events they deal with.
]
]

#slide[
  == Better Solution: Interrupts
#item-by-item[
  #[Hardware _interrupts_ the normal execution of instructions in response to an event, and starts executing a different subroutine.]
  - When `UART_TXDRDY` becomes true, execute `uart_handler()`.
  - Variables that are shared between interrupt and main code, must be marked `volatile` (can change any time, outside direct code execution).
```c
#define NBUF 64
static volatile int bufcnt = 0;
static int bufin = 0;
static int bufout = 0;
static volatile char txbuf[NBUF];
static volatile int txidle;
```
]
]

#slide[
  == Better Solution: Interrupts
```c
void uart_handler(void) {
  if (UART_TXDRDY) {
    UART_TXDRDY = 0;
    if (bufcnt == 0) {
      txidle = 1;
    } else {
      UART_TXD = txbuf[bufout];
      bufcnt--;
      bufout = (bufout+1) % NBUF;
    }
  }
}
```
]

#slide[
  == Better Solution: Interrupts
```c
void serial_putc(char ch) {
  while (bufcnt == NBUF) pause();//volatile ensures fresh read
  intr_disable();
  if (txidle) {
    UART_TXD = ch;
    txidle = 0;
  } else {
    txbuf[bufin] = ch; bufcnt++;
    bufin = (bufin+1) % NBUF;
  }
  intr_enable();
}
```
]

#slide[
  == Why Disable Interrupts?
  - What happens if interrupt occurs before `bufcnt++;`?
  - What happens if interrupt occurs
    ```
ldr r0, =bufcnt
ldr r1, [r0]
                     @ <== here?
add r1, r1, #1
str r1, [r0]
```
]

#slide[
  == Setting Up Interrupts
  ```c
  void serial_init(void) {
    ...
    UART_INTENSET = BIT(UART_INT_TXDRDY);
    enable_irq(UART_IRQ);
    txidle = 1;
  }
```
#set align(center)
#image("./figures/interrupt-sequence.png", height: 42%)
]

#slide[
  == Timings: Early on in Primes Program
  No (noticeable) delays between sending characters.
  #image("./figures/primes-intr-early.png", height: 78%)
]

#slide[
  == Timings: Later on in Primes Program
    No (noticeable) delays between sending characters.
  #image("./figures/primes-intr-later.png", height: 78%)
]

#slide[
  == Timings: End of Primes Program
    Sending characters continues after primes calculation is done!
#image("./figures/primes-intr-end.png", height: 78%)
]


#slide[
  #callout_warning[Crucial detail omitted!][]
]

#slide[
  == Summary
  - How to implement a queue with a circular buffer.
  - Why we need interrupts.
  - What hardware provides for interrupts.
  - How to use interrupts in software.
]