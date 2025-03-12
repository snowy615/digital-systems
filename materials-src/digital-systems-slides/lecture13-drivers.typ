#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)


#title-slide(title: [Lecture 13 \ Device Drivers])

#polylux-slide[
  == List of Demands
  We have a single CPU that can execute instructions.
  // #callout_idea[The time a program spends waiting to respond to external events, is much larger than the time spent computing.][]

  We want to be able to
  - execute multiple programs simultaneously (concurrency),
  - that can respond to external events and communicate with one another,
  - with each program written using its own control flow,
  - seeming as each program is running simultaneously,
  - *and doesn't require the programmer to know when to disable interrupts in order to guarantee correct code.*
]

#polylux-slide[
  #line-by-line[
  #callout_question[How can we safely respond to outside events?][]
  - Take advantage of the safety of messages, by making interrupts \ send messages from hardware.
  - Interrupt from peripheral will send messages to _device driver_.
  - Other processes communicate with hardware through device driver, by sending messages.
  - Device driver is a process that serves messages from hardware/software in a loop.
]
]

#polylux-slide[
  == Serial Output
  ```c
void serial_putc(char ch) {
  message m;
  m.int1 = ch;
  send(SERIAL, PUTC, &m);
}
```

- Now interacts with hardware via the driver, rather than directly.
- Request message sent to SERIAL driver.
- Process yields to the OS, and waits if driver is not yet ready.
]

#polylux-slide[
  == Driver Process
  ```c
void serial_task(int arg) {
  static char txbuf[NBUF];  // Note: State is local to driver!
  int bufin, bufout, bufcount; message m; char ch;
  serial_setup();
  while (1) {               // Loop serves request
    receive(ANY, &m);
    switch (m.m_type) {
      ...
    }
  }
}
```
]

#polylux-slide[
  == Setting Things Up
  ```c
void serial_setup(void) {
  ...
  connect(UART_IRQ);
  enable_irq(UART_IRQ);
  UART_INTENSET = BIT(UART_INT_TXDRDY);
}
```
]

#polylux-slide[
  == Handling PUTC Messages
```c
while (1) {
  receive(ANY, &m);
  switch (m.m_type) {
    case PUTC:
      ch = m.int1;
      txbuf[bufin] = ch; ... // rest of circular buffer
      break;
    ...
  }
}
```
- Buffer variables are local, so no other process can interfere.
- No need for `volatile` or to disable interrupts.
]

#polylux-slide[
  == Questions
  Several questions remain to be answered:
+ How do characters get out of the buffer and into the UART?
+ What happens about interrupts?
+ What happens when someone wants to send a PUTC message but the buffer is full?
]

#polylux-slide[
  == Handling Interrupts
Remember: Hardware sends INTERRUPT message.
  
  Inside loop, inside switch...
  ```c
  case INTERRUPT:
    if (UART_TXDRDY) {
      txidle = 1;
      UART_TXDRDY = 0;
    }
    clear_pending(UART_IRQ);
    enable_irq(UART_IRQ);
    break;
  ```
]

#polylux-slide[
  == Responding to Events
  Send character, if possible, after any message.
  ```c
  while (1) {
    receive(ANY, &m);
    switch (m.m_type) {
      ...
    }
    if (txidle && bufcount > 0) {
      UART_TXD = txbuf[bufout]; ...
      txidle = 0;
    }
  }
  ```
]

#polylux-slide[
  #line-by-line[
  == Bug in the Program!
  What if the buffer is full? #[Let’s replace
   ```c
    receive(ANY, &m);
```]
#[with
```c
    if (bufcount < NBUF)
        receive(ANY, &m);
    else    
        receive(INTERRUPT, &m);
```]
When the buffer is full, we just stop accepting requests until it has emptied a bit.
]
]

#polylux-slide[
  #set align(horizon)
  #callout_idea[Use message mechanism to synchronise processes!][]
]

#polylux-slide[
  == Full Driver
  #columns(2, [
    ```c
while (1) {
  if (bufcount == NBUF)
    receive(INTERRUPT, &m);
  else
    receive(ANY, &m);
  switch (m.type) {
  case INTERRUPT:
    if (UART_TXDRDY) {
      txidle=1;UART_TXDRDY=0;}
    clear_pending(UART_IRQ);
    enable_irq(UART_IRQ);
    break;
  case PUTC:
    txbuf[bufin] = m.int1;
    bufin = wrap(bufin+1);
    bufcount++;
    break;
  }
  if (txidle && bufcount>0) {
    UART_TXD = txbuf[bufout];
    bufout = wrap(bufout+1);
    bufcount--;
    txidle = 0;
} } }
  ```
  ])
]

#polylux-slide[
  == Omitted Here
  Lab 4 has a more elaborate serial driver
  - Supports both output and input with echoing and line editing.
  - All UART initialisation details are filled in.
  - There’s an alternative interface print_buf that overcomes the one-message-per-character bottleneck.
]

#polylux-slide[
  == Bottleneck
  #line-by-line[
  - How many context switches per character?
  - Multiple µs per context switch
  - UART baud $=>$ 10k characters/s
  - Can use up to $10^5$ µs of CPU time per second! 10% of CPU time!

This is a downside of the messaging design
- Allow `printf()` to accumulate characters in a buffer, and send them all at once.
- But... shared memory!

]
]

#polylux-slide[
  == Standard Interrupt Handler
  ```c
void default_handler(void) {
  int irq = active_irq();
  int task = os_handler[irq];
  disable_irq(irq);
  interrupt(task);    // Send an interrupt message to process
}
```

- Driver can be ready to accept message \
  $->$ context switch
- Driver can not be ready to accept message \
  $->$ deliver interrupt message later, at next available opportunity

Why do we need `disable_irq(...)`?
]

#polylux-slide[
  == Example
  Heart & Primes example. Can we find sequence of events? When we switch contexts, when CPU sleeps/wakes?
  - Look at `ex-heart.c`.
  - Look at `serial.c`

#v(1cm)

  If time, look at `print_buf()`.
]

#polylux-slide[
  == Summary
  - Take advantage of the safety of messages, by making interrupts \ send messages from hardware.
  - Interrupt from peripheral will send messages to _device driver_.
  - Device driver is a process that serves messages from hardware/software in a loop.

  #pause

  #v(0.8cm)

  #callout_question[How does the OS switch tasks?][
    - How does it decide what to run next?
    - How does it move messages?
    - How does it actually do the context switch?
  ]
]
