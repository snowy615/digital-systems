#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)

#title-slide(title: [Lecture 12 \ Operating Systems])

#slide[
  == Problems with Previous Programs
```c
static int row = 0;
void advance(void) {  // Called by an interrupt
  row++;
  if (row == 3) row = 0;
  GPIO_OUT = heart[row];
}
```

- Efficient but inflexible: No waiting around, but needed to manually add code to the interrupt (what if another piece of code wanted to use timer?)
- No control structures inside `advace()`. Effectively, we had to implement a program counter ourselves (`row`).
]

#slide[
  == Problems with Previous Programs
  Use interrupts to overlap printing with the search, but
  - When the serial buffer is full, wastes time waiting in a loop.
  - Disables interrupts to protect the buffer from concurrent modification – hard to get right.

  #v(1.0cm)

  #show: later

  To illustrate inflexibility: Consider writing a program that simultaneously runs beating `heart` and `primes`.
]

#slide[
  == List of Demands
  #item-by-item[
  We have a single CPU that can execute instructions.
  // #callout_idea[The time a program spends waiting to respond to external events, is much larger than the time spent computing.][]

  #item-by-item(start: 3)[
  We want to be able to
  - execute multiple programs simultaneously (concurrency),
  - that can respond to external events and communicate with one another,
  - with each program written using its own control flow,
  - seeming as each program is running simultaneously,
  - and doesn't require the programmer to know when to disable interrupts in order to guarantee correct code.
]
  ]
]

#slide[
  == Why concurrency?
- Sharing one machine between several tasks
- Responding to several sources of events
- Genuinely parallel machines (modern multicore)
- Decomposing one task clearly
]

#slide[
  #item-by-item[
    #callout_idea[Operating System][]
    In next few lectures: Example design of an Operating System
    - Many different ways of designing an OS, with pros/cons.
    - micro:bian's design is based on "message passing".
    - Other structures are arguably more efficient.
    - You will discuss these structures next year (Concurrency), \
      but you _won't_ see low-level implementation of what allows concurrent processes to run.
    - We will discuss low-level mechanisms for allowing concurrent processes.
  ]
]

#slide[
  == OS Constructs
  - Processes: embedded programs are conveniently structured as a set of independent processes.
  - Messages: processes can cooperate by exchanging messages in a way that synchronises their behaviour.
  - Shared variables are best avoided by using messages instead (error-prone, and can be eliminated... at a cost)

  #show: later

  #v(1.0cm)

  In this lecture, we use these concepts to build a concurrent program.
]

#slide[
  == A Process: Heart
  ```c
static void heart_task(int arg) {
  while (1) {
    show(heart, 70); show(small, 10);
    show(heart, 10); show(small, 10);
} }

void show(const unsigned *img, int n){
  while (n-- > 0) {  /* Takes 15msec per iteration */
    for (int p = 0; p < 3; p++) {
      GPIO_OUT = img[p]; timer_delay(5);
} } }
```
]


#slide[
  == Another Process: Prime
  ```c
static void prime_task(int arg) {
  int p = 2, n = 0;
  while (1) {
    if (prime(p)) {
      n++;
      // printf will yield by calling serial_putc()
      printf("prime(%d) = %d\n", n, p);
    }
  }
  p++;
}
  ```
]





#slide[
  == Processes
  #item-by-item[
  - Run until no more progress can be made \
    (co-operative multitasking vs pre-emptive multitasking)
  - When this happens, process _yields_ control of CPU, so other process can make progress.
  - OS will decide which process to devote time to next.
  - After 5ms, "operating system" wakes up process again, and continues.
  - Interrupts can still occur, and interrupt a process.
  #[Notice:]
  - Yield could happen in a subroutine.
  - So, each process needs its own subroutine stack.
]
]

#slide[
  == Startup
  ```c
void init(void) {
  SERIAL = start("Serial", serial_task, 0, STACK);
  TIMER = start("Timer", timer_task, 0, STACK);
  HEART = start("Heart", heart_task, 0, STACK);
  PRIME = start("Prime", prime_task, 0, STACK);
}
```
- a fixed collection of processes created before concurrent execution begins.
- our two processes, plus device drivers for the timer (`timer_delay`) and serial port (`serial_putc`);
- plus an idle task: Only place where CPU gets put to sleep.
]

#slide[
  == Processes
  We saw:
  - Each process is a main program in its own right
  - It can pause itself (or be interrupted) at any point to give others a go.

  We will see implementation:
  - Processes have interleaved access to CPU
  - Each has its own stack

  micro:bian supports a fixed set of processes.
]

#slide[
  #callout_question[How can processes communicate amongst them?][
    Let's rewrite the prime example to split calculating, and handing the "UI" (printing to terminal).
  ]
]

#slide[
  == Sending Messages
  ```c
void prime_task(int arg) { int n = 2;
  message m;
  while (1) {
    if (prime(n)) {
      m.int1 = n;
      send(USEPRIME, PRIME, &m);
    }
    n++;
  }
}
```
]

#slide[
  == Receiving Messages
  ```c
void summary_task(int arg) {
  int count = 0, limit = arg; message m;
  while (1) {
    receive(PRIME, &m);
    while (m.int1 >= limit) {
      printf("There are %d primes less than %d\n",
             count, limit);
      limit += arg;
    }
    count++;
  }
}
```
]

#slide[
  == Message Communication
  #item-by-item[
  ```c
  void init(void) {
    ...
    GENPRIME = start("GenPrime", prime_task, 0, STACK);
    USEPRIME = start("UsePrime", summary_task, 1000, STACK);
  }

  ```
  - Messages not buffered.
  - If process wants to receive: It waits for the other process to send.
  - If process wants to send: It waits for other process to receive.
  - If message not ready, process yields, and OS runs another process.
  - If message *is* ready, OS transfers when both processes are frozen.
  - If two processes send to same receiver, OS determines ordering.
]
]

#slide[
  == Message Format
  Both sender and receiver have a message buffer (16 bytes).
  - Message type (2 bytes, `short`)
  - Sender (2 bytes, `short`)
  - Data (3 `ints`, 12 bytes)
]

#slide[
== Alternatives to messages
Message passing:
- no “shared variables” between processes.
- all communication by messages

Shared variables with semaphores:
- like the serial output buffer.
- more efficient, but hard to get right.
]

#slide[
  == Other OSs
  - Processes with communication
  - Drivers for I/O devices
  - Dynamically and unloading processes
  - Memory management (protection/segmentation, virtual memory)
  - File system
  - Networking
]

#slide[
  == Summary
  - Why we need an OS
  - How independent processes operate
  - How processes can communicate by messages
  - Danger of shared variables, safetey of messages
]

#slide[
  == Example
  Heart & Primes example.

  Sequence of events, and when CPU sleeps, and wakes.
]


#slide[
/*- Message passing.
- This way is a good way of structuring software systems that respond to external events.
- Other ways of building OSs for concurrent processes without using messages, arguably more efficient.
- You'll see some of these next year, but what you *won't* see is the low-level mechanism that underlies having concurrent processes on a single machine.
- We will discuss low-level mechanisms for allowing concurrent processes, through the illustration of these message-passing scheme

Three ideas:
- Processes: Multiple programs in the same program, each process can call subroutines, suspend themselves. More flexible than interrupts (cannot suspend themselves)
- Messages: Safe way of communicating and synchronising behaviour between processes. Safe because messages cannot be half sent/delivered. So no confusiong.
- Shared variables: Variables that can be referred to in more than one process. We argue that they're confusing, and error-prone, and we argue it's best to use messages instead. Prove that you can eliminate all shared variables by having enough processes and messages, at the cost of some gross inefficiency.

Heart program is inflexible:
- Structure where place you get to is recorded in variable, rather than program counter...
- What we really want is a loop that displays rows one at a time

Primes program:
- When program generating primes gets ahead, buffer gets full and we wait.
- Can just simply loop and wait, or `pause()`
- Interrupts had to be disabled to avoid concurrent modification of shared variable. Hard to get right. Need to manually think about this!

Let's create a solution using processes. W

After 5 milliseconds, Something mysterious called the operating system, will wake this process up again

When a process goes to sleep, its suspended state is an entire subroutine stack.

We'll have to study a mechanism for multiple stacks to coexist.

Whenever one suspends, the OS will devote attention to the other one.

Whenever an event happens, the OS will stop running whatever process is running at the time, and run one that will deal with the event.

Function `init()` becomes very simple, because all that it does, is start various other processes.

OS system call `start()` returns an integer that identifies a process when they want to communicate.
- Name for debugging purposes
- Function that is main program for process
- Pass integer as a parameter
- Also determine how large the stack should be

Once init returns, no more processes can be started. Larger OSes can stop and start processes. Consequence is that memory gets fragmented, as chunks of free space get allocated and freed. Simpler if processes can only be made at the start, and it's enough for many situations.

This program, two processes that we want to execute, and two processes for our device drivers. Fifth process for OS when there is nothing to do. Give example when this happens.

Idle process puts processor to sleep. No need for any other process to do this.

Not present in microbian is the idea that each process has its own address space (segmentation / virtual memory)

If a process wants to send, it has to wait until the other is ready to receive. If a process wants to receive, it has to wait until the other process wants to send. This is known as a rendezvous. OS realises when this occurs, and then when both programs are frozen, copies the message across.

Sense in which sending messages is safe: If two processes want to send a message to the same process, there will be an ordering in terms of which one goes first, and which one waits. No garbled message. Harder to guarantee with shared memory.*/
]

