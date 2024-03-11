#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)

#title-slide(title: [Lecture 14 \ Context Switching])

#polylux-slide[
== Today
    #callout_question[How does the OS switch tasks?][
    - How does it decide what to run next?
    - How does it move messages?
    - *How does it actually do the context switch?*
  ]
]

#polylux-slide[
  == Context Switching
  Switch processes on `send()`, `receive()`, `yield()`, or interrupt.
  
  Temporarily passes control to OS, which then decides what to do next.

  #line-by-line[
  #[The plan to do so:]
  - Enter the OS via a software interrupt instruction `svc`, or by a normal interrupt.
  - Save _entire_ processor state on the stack.
  - After choosing a new process, restore its state to continue.

  #callout_idea[Operating System is basically one big interrupt][]
]
]

#polylux-slide[
  == `svc` interrupt vs normal interrupt
  #line-by-line[
  #[Instruction `svc` (supervisor call) operates like a normal interrupt:]
  - Hardware stores the usual state to conform to calling convention.
  - `r0-r3`, `r12`, `lr`, `pc`, `psr`
  - Magic value is placed in `lr`, so hardware knows to do special return.

  #[Differences:]
  - Hardware moves CPU to different state (traced in `CONTROL`), from "user" to "kernel".
  - `sp` now patches through a different register, so OS has its own stack.
  - Different magic value is placed in `lr`.
]
]

#polylux-slide[
  == Context Switch I
  #set align(center)
  #image("./figures/context-switch1.png", height: 90%)
]

#polylux-slide[
  == Context Switch II
  #[We additionally want:]
  - to be able to run a different process,
  - so we cannot rely on subroutine conventions to restore state in correct way,
  - we must store _all_ state of the process on the stack.
]

#polylux-slide[
  == Context Switch II
  #set align(center)
  #image("./figures/context-switch2.png", height: 90%)
]

#polylux-slide[
  == Context Switch III
  #set align(center)
#image("./figures/context-switch3.png", height: 90%)
]

#polylux-slide[
  == Context Switch IV
  #set align(center)
#image("./figures/context-switch4.png", height: 90%)
]

#polylux-slide[
  == Context Switch V
  #set align(center)
#image("./figures/context-switch5.png", height: 90%)
]

#polylux-slide[
  == Context Switch VI
  #set align(center)
#image("./figures/context-switch6.png", height: 90%)
]

#polylux-slide[
  == Initiating System Calls
#image("./figures/system-calls.png", height: 90%)
]

#polylux-slide[
  == Handling System Calls
  #line-by-line[
  #[Sequence of events:]
  - `startup.c`: Vectors table.
  - `mpx-m0.s`: `svc_handler` stores remaining state.
  - `microbian.c`: `system_call()` handles call, determines next process, returns stack pointer of process.
  - `mpx-m0.s`: `svc_handler` restores state of (new) process.
  - `bx ...`: Returns to magic number `0xfffffffd`
]
]

#polylux-slide[
  == `svc_handler`
  ```
svc_handler:
    isave @ Complete saving of state
    @@ Argument in r0 is sp of old process
    bl system_call @ Perform system call
    @@ Result in r0 is sp of new process
    irestore @ Restore saved state
```
]

#polylux-slide[
  == Saving the State
  Unavoidable bit of assembly to store additional state, since this is not done by hardware, cannot be done by calling convention, and C cannot be trusted to get this right.
  ```
@@@ isave -- save context for system call
    .macro isave
    mrs r0, psp         @ Get thread stack pointer
    subs r0, #36
    movs r1, r0
    mov r3, lr          @ Preserve magic value
    stm r1!, {r3-r7}    @ Save low regs on thread stack
    mov r4, r8          @ Copy from high to low
    mov r5, r9
    mov r6, r10
    mov r7, r11
    stm r1!, {r4-r7}    @ Save high regs on thread stack
    .endm               @ Return new thread sp
```
]

#polylux-slide[
  == System Call: OS Side
  //- Receives stack pointer of current process.
  //- Returns stack pointer of process to be restored.
```c
unsigned *system_call(unsigned *psp) {
    short *pc = (short *) psp[PC_SAVE];
    int op = pc[-1] & 0xff;
    os_current->sp = psp;
    switch (op) {
    case SYS_YIELD:
        make_ready(os_current);
        choose_proc();
        break; ...
    }
    return os_current->sp;
}
```
]

#polylux-slide[
== Remaining details
- How to start a process.
- How to start the entire operating system.
- How to schedule processes (next time).
]

