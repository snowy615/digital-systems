#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)

#title-slide(title: [Lecture 9 \ Serial I/O])


#polylux-slide[
  == More Chocolate
  #grid(columns: (1fr, 1fr), 
  [  #set align(center)
#image("./figures/riddle-train-zoom-out.jpeg", height:78%)], [  #set align(center)
#image("./figures/riddle-train-zoom-in.jpeg", height:78%)])
  What is going on here? Chocolate for the best hypothesis.
]


#title-slide(title: [Lecture 9 \ Serial I/O])

#polylux-slide[
  #line-by-line[
  #callout_question[How can computers communicate with each other?][
    Say we want to transfer a file between computers?
  ]
  - We have electrical signals at our disposal.
  - Design constraint: Let's try to use as few pins as possible.
  - Communicate bits sequentially over a single wire.
  #light[History, current hardware setup (PC, Freescale, Nordic), linux device driver, terminal.]
]
]


#polylux-slide[
  == Serial Communication: Oscilloscope
  #grid(columns: (1fr, 1.55fr), [
    #line-by-line[
    - Idle: High.
    - Start bit: Indicates data transmission.
    - Read data at regular time intervals (crucial!).
    // Timing is crucial to read a the correct point
    // Read in middle of period, or average a few
    // Hardware can adjust reading time a bit, based on timing of edges
    - Stop bit: Return to high for idle.
    - Configured baud rate: 9600 symbols/s (i.e. bits/s).
    - Could implement w/ GPIO
  ]
  ], {image("./figures/serial-oscilloscope.png", height: 90%)})
]

#polylux-slide[
  == UART Interface
  On Nordic chip, hardware handles most conversions, with a convenient _memory-mapped_ interface.
  
  Universal Asynchronous Receive Transmit interface on the Nordic chip provides:
  - Full-duplex operation: Separate receive/transmit wires, for simultaneous receive/transmit.
  - Universal: Can operate at different speeds.
  - Asynchronous: No shared clock signal (cf. SPI)
]

#polylux-slide[
  == A Basic UART Driver: Setup
  ```c
  void serial_init(void) {
    UART_ENABLE = 0;
    // Select 9600 Baud, relative to 16 MHz crystal
    UART_BAUDRATE = UART_BAUD_9600;
    UART_CONFIG = UART_CONFIG_8N1;  // 8N1 (8 data,1 stop)
    UART_PSELTXD = USB_TX;          // choose pins
    UART_PSELRXD = USB_RX;
    UART_ENABLE = UART_Enabled;
    UART_RXDRDY = 0; UART_TXDRDY = 0;
    UART_STARTTX = 1; UART_STARTRX = 1;
    txinit = 1;
}
  ```
]

#polylux-slide[
  == A Basic UART Driver: Transmission
  ```c
void serial_putc(char ch) {
    while (! UART_TXDRDY) { /* idle */ } UART_TXDRDY = 0;
    UART_TXD = ch;
}
  ```
  - _Polling_ to wait for previous character to finish transmiting.
  - `printf()` is wrapper around this.
]

#polylux-slide[
  == A Communicating Program
  Print out sequence of primes via serial.
```c
start_timer();
while (count < 500) {
  if (prime(n)) {
    count++;
    printf(“prime(%d) = %d\r\n”, count, n);
  }
  n++;
}
stop_timer();

```
Polling: Spends a lot of time transmitting, rather than calculating!
]

#polylux-slide[
  == Timing with Logic Analyser
  #grid(columns: (1.1fr, 1fr), [
    Can confirm this hunch by looking at signals from pins.
    - Like an oscilloscope, but only stores digital state.
    - More channels (8).
    - Can record for longer time.

    Here: Monitors both LED and UART.
  ], {image("./figures/logic-analyser.png", height: 90%)})
]


#polylux-slide[
  == Timing with Logic Analyser
  Early on, most time is spent waiting for UART to send.
  #set align(center)
  #image("./figures/logic-analyser-uart-bottleneck.png", height: 75%)
]

#polylux-slide[
  == Timing with Logic Analyser
  Later on, longer periods are spent calculating.
  #set align(center)
  #image("./figures/logic-analyser-calc-bottleneck.png", height: 75%)
]

#polylux-slide[
  #set align(horizon)
  #callout_question[Do we need to wait around while UART is transmitting?][
    What is the point of having hardware to handle receiving/transmission, if the CPU will just wait around until it's done anyway?
  ]
]

#polylux-slide[
  == Summary
  - Electrical serial protocol.
  - Software interface of serial.
]


#polylux-slide[
  == Bonus
  Remember:
  ```c
unsigned x = GPIO_IN;
if (GET_BIT(x, BUTTON_A) == 0 || GET_BIT(x, BUTTON_B) == 0) {
  // A button is pressed
}
```
  
  Let's look at macros in `hardware.h` in more detail.

  
  - `GPIO_OUT`
  - `SET_FIELD(GPIO_PINCNF[BUTTON_A], GPIO_PINCNF_INPUT, GPIO_INPUT_Connect);`
  - `GET_BIT`, `SET_BIT`, `CLR_BIT`
]
