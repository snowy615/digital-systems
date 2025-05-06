#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)

#title-slide(title: [Lecture 11 \ The Interrupt Mechanism])

#slide[
  == Last Lecture...
  We left off with the question: How does the interrupt know 

  Table with all interrupt addresses

  vectors part of the rom, all the way at the bottom of the address space
]

#slide[
  #callout_question[What _actually_ happens on an interrupt?][
    #item-by-item[
    - Last lecture, we showed how to program an interrupt in a high-level language.
    - ... this course is about you being able to understand every detail so you can _actually build_ a computer.
    - So we'll need to dive deeper:
      - What does hardware actually do on an interrupt?
      - What does the hardware do to the _state_ of the CPU on an interrupt?
    ]
  ]
]

#slide[
  == What additional tasks must subroutines do?
  - An interrupt looks like a subroutine, inserted at an arbitrary point.
  - Interrupt _handlers_ can be normal subroutines.
    #image("./figures/polling-throughout.png", height: 70%)
]

#slide[
  == Satisfying the Subroutine Convention in Interrupts
  #item-by-item[
  #callout_question[What _additional_ work needs to be done on an interrupt, compared to calling a normal subroutine?][]
  - Remember the subroutine convention. \ What does the interrupt handler expect?
  - What is different about an interrupt cf a normal subroutine? \
    What does the interrupted code assume?
  #callout_warning[Parent's code does not know it will be interrupted!][
      So we need to more careful with storing/restoring _state_.
    ]
    - Must also store #psr, #pc, #lr, #r12, #r0 - #r3!
  ]
]

#slide[
  == Satisfying the Subroutine Convention in Interrupts
  #set align(center)
  #image("figures/interrupt-save-state.png", height: 90%)
]

#slide[
  == Satisfying the Subroutine Convention in Interrupts
  #item-by-item[
  #[Imagine interrupt happening in:
  #v(-0.4cm)
  ```
    cmp r0, r1
    beq label
  ```]
  - Must restore #psr on returning from the interrupt. \
    Code doesn't know that #psr can be overwritten, as for normal subroutine calls.
  - Must satisfy rest of calling convention (e.g. handler can use #r0 - #r3).
  #callout_idea[Hardware ensures subroutine convention for interrupts.][
    Our _design choice_ for wanting interrupt handlers to be normal subroutines (in assembly). So _hardware_ must ensure this.
  ]
]
]

#slide[
  == Hardware Interrupt Process
  Exception / interrupt frame. State is same as after normal subroutine call.
  #set align(center)
  #image("figures/hardware-interrupt-process.png", height: 78%)
]

#slide[
  == Entering Handler (that can call subroutines)
  Can `push` additional registers in the usual way.
  #set align(center)
#image("figures/interrupt-entering-handler.png", height: 78%)
]

#slide[
  == Exiting Handler (what software must do)
  Can return from subroutine in usual way (`bx lr` or `pop`).
  #set align(center)
#image("figures/interrupt-exiting-handler.png", height: 78%)
]

#slide[
== Exiting Interrupt
#pc is set to magic number $=>$ follow return from interrupt procedure.
#set align(center)
#image("figures/interrupt-exiting-interrupt.png", height: 78%)
]

#slide[
  == Hardware Obeys Calling Conventions
Advantages
- Interrupt handlers can be ordinary subroutines.
- No need for assembly-code adapters.

Disadvantages
- Interrupt latency is fixed and large.
]

#slide[
  #set align(center + horizon)
  == Example: Timers
]

#slide[
  == Scheduling Regular Actions
  Version 0: delay loops (already seen).
  - Wasteful of time and power.
Version 1: use a timer for delays (this lecture).
- Easier to maintain, but still wasteful of time and power.
Version 2: purely interrupt driven (this lecture).
- Allows computation while waiting but inflexible.
Version 3: use an operating system (next time).
- Best of all worlds!
]

#slide[
  == Timers
Multiple compare circuits and counters (up to 32-bit) are available.
  #set align(center)
  #image("./figures/timer.png", height: 75%)
]

#slide[
  == Delay v1: Power Efficient
  ```c
unsigned volatile millis = 0;
void timer1_handler(void) {
    if (TIMER1_COMPARE[0]) {
        millis++;
        TIMER1_COMPARE[0] = 0;
    }
}

void delay(unsigned usec) {
    unsigned goal = millis + usec/1000;
    while (millis < goal) { pause(); } // Uses wfe instruction
}
```
]


#slide[
  == Aside...
```c
void delay(unsigned usec) {
    unsigned goal = millis + usec/1000;
    while (millis < goal) { pause(); } // Uses wfe instruction
}
```

#item-by-item[
  Any bugs / annoyances about this bit of code?
  - If `goal` overflows, loop terminates immediately $=>$ maximum delay gets smaller as `millis` increases! How to fix?
  - `while ((millis - start_millis) < usec / 1000)`
  - _Still works_ if `millis` overflows!
]

]


#slide[
  == Delay v2: Interrupt-driven
  To allow computation while waiting, make `timer_interrupt` call this at 5ms intervals:
  ```c
static int row = 0;
void advance(void) {
    row++;
    if (row == 3) row = 0;
    GPIO_OUT = heart[row];
}
```
- Compare to `delay()` solution where beating heart is shown with loop.
- Here: no internal control structure allowed.
- Efficient but inflexible.
]

#slide[
  == Summary
  - Details of how interrupts work.
  - Timer circuits.

#v(0.8cm)

#callout_question[How can we allow multiple subroutines to operate in an interleaved way?][
  - Currently, we can have one "main" function, that is interrupted. This function is special.
  - How can we have multiple processes running concurrently, that are interrupted to interleave with one another?
]
]