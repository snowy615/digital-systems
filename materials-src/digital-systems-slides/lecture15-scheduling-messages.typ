#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)

#title-slide(title: [Lecture 15 & 16 \ Scheduling Processes & Messages])

#slide[
  == C Pointer Syntax
  #item-by-item[
  - Variable containing 1 \
    ```c int a = 1;```
  - Variable able to contain address to memory location containing `int`
    ```c int* b;```
  - Set b to address of a \
    ```c b = &a```
  - Set c to contents of a \
    ```c int c = *b```
  ]
]

#slide[
  == C Pointer Syntax for Structs
  #item-by-item[
  #[```c
typedef struct dst {
  int feet;
  float inch;
} distance;


```]
- Struct-typed variable \
  ```c distance a; a.feet = 9001; a.inch = 11;```
- Pointer to `distance`-typed variable, assign address of `a` \
  ```c distance* b; b = &a;```
- Content of address in b \
  ```c (*b).inch == a.inch;  /* Or... */ b->inch == a.inch;```
]
]

#slide[
  == Today
  #callout_question[How are processes started?][]
  #callout_question[What happens to the Operating System on startup?][]
]


#slide[
  == Starting a Process
  The first time a process runs, it is resumed just as if returning from a system call.
  
  So we set up a fake exception frame that invokes the process body when resumed.
- #r0 = integer argument,
- #pc = process body,
- #lr = address of exit stub, in case body returns.
]

#slide[
  == Creating "fake" Stack Frame
  ```c
int start(...) {
    ...
    unsigned *sp = p->sp - FRAME_WORDS;
    memset(sp, 0, 4*FRAME_WORDS);
    // Macros for offsets in stack, ***_SAVE
    sp[PSR_SAVE] = INIT_PSR;  // Thumb bit switched on
    sp[PC_SAVE] = (unsigned) body & ~0x1; // Activate the proc
    sp[LR_SAVE] = (unsigned) exit; // Make it return to exit()
    sp[R0_SAVE] = (unsigned) arg;  // Pass arg in r0
    sp[ERV_SAVE] = MAGIC;
    p->sp = sp;
    ... }
```
]

#slide[
  == Starting a Process
  #item-by-item[
  #[At this point, every process has a stack frame that:]
  - will restore the #pc at the start of the process's function \
    (i.e. it will run the function)
  - has values for all state and registers that respects the restoring convention (manual part + hardware part),
  - has values in the registers that respect the calling convention of C functions (e.g. integer argument in #r0).
  #[To start, just initiate context switch by returning from `system_call()`.
- Q: Return value?]
]
]

#slide[
  == Starting the OS
  After `init()` called, all tasks have stack frames that will allow a context switch into them.

  ```c
void __start(void) {
    /* Create idle process */
    ...
    /* Call the application's setup function */
    init();
    /* The main program morphs into the idle process. */
    os_current = idle_proc;
    set_stack(os_current->sp);
    idle_task();
}
  ```
]

#slide[
  == Idle Process
  ```c
void idle_task(void) {
  /* Pick a genuine process to run */
  yield();
  
  /* When there's nothing to do: */
  while (1) pause();
}
  ```
]

#slide[
  == Where are we now?
  #item-by-item[
  #[We understand _how_ tasks are switched and started.]
  - OS is an interrupt that performs context switches \ (Q: remind me how)
  - During context switch, interrupt stores some state on stack, \ assembly code stores the rest.
]
]

#slide[
  #item-by-item[
    == What is left to understand?
    #callout_question[How does the OS keep track of processes?][
      We have already seen that we need to start processes, and keep track of various process-specific quantities (e.g. stack location), in order to do context switches. How does the OS do this?
    ]
    #callout_question[How does the OS decide which process to run next?][]
    #callout_question[How are messages transferred between processes?][
      And in particular, how is this done in interrupts?
    ]
  ]
]

#slide[
  #set align(horizon)
      #callout_question[How does the OS keep track of processes?][
      We have already seen that we need to start processes, and keep track of various process-specific quantities (e.g. stack location), in order to do context switches. How does the OS do this?
    ]
]

#slide[
  == Process Structure
  ```c
struct _proc {
    int pid;          // Process ID
    char name[16];    // Name for debugging
    unsigned state;   // SENDING, RECEIVING, etc.
    unsigned *sp;     // Saved stack pointer
    int priority;     // Priority: 0 is highest
    proc waiting;     // Processes waiting to send
    int pending;      // Whether interrupt pending
    int msgtype;      // Message to send or receive
    message *msgbuf;  // Pointer to message buffer
    proc next;        // Next process in ready/send queue
};
```

== Possible states
- `DEAD`: process that has exited. It is also the value present in slots of the table that have never been used.
- `ACTIVE`: process is ready to run. The process is either the current process, or the ready queue waiting to become current.
- `SENDING`: process is waiting to send to another; the process will appear in the sending queue of the destination.
- `RECEIVING`: process is waiting to receive a message; the `msgtype` field will specify who may send to it.
- `SENDREC`: call to `sendrec`, combining the functions of send and receive.
- `IDLING`: idle process, which runs when no other process is ready.
]

#slide[
  == Process Structure
  #item-by-item[
  #[```c
  typedef struct _proc *proc;
  ...
  static proc os_ptable[NPROCS];
  ```

]
  #[In `start(...)`: \
  ```c    proc p = create_proc(name, roundup(stksize, 8));```

]
  #[In `create_proc(...)` we]
  - Initialise all the fields to sensible defaults / based on arguments.
  - Find a memory location to initialise the stack (`sbrk(...)`)
  - Find a memory location for proc variable (`new_proc(...)`)
  #light[Draw memory layout (heap, stacks, ..., processes, main stack). $<==$]
]
]

#slide[
  #set align(horizon)
  #callout_question[How does the OS decide which process to run next?][
    Start with the easy case: context switch initiated by `yield()`.
  ]
]

#slide[
  == Ready Queues
  #grid(columns: (1fr, 2.5fr), [#set align(horizon)
    In `ACTIVE` processes, the ready queue is implemented using the `next` field.
  ], [#image("./figures/ready-queue.png", height: 90%)])
]

#slide[
  == Ready Queues
  #item-by-item[
  ```c
#define NPRIO 3      /* Number of non-idle priorities */
...
static struct _queue {
    proc head, tail;
} os_readyq[NPRIO];


```

#[Last line of `start(...)`, after setting up fake exception frame...

```c     make_ready(p);```

Adds process to appropriate queue.]
]
]

#slide[
  == Adding to the Queue: `make_ready()`
  ```c
static inline void make_ready(proc p) {
    int prio = p->priority;
    if (prio == P_IDLE) return;
    
    p->state = ACTIVE;
    p->next = NULL;    // Because last in queue
    queue q = &os_readyq[prio];
    if (q->head == NULL)
        q->head = p;
    else
        q->tail->next = p;
    q->tail = p;                       }
```
]

#slide[
  == Full Story of Startup
  #item-by-item[
    - `startup.c`:  `__reset()` is called.
    - `microbian.c`: `__start()` is called.
    - Calls `init()`, defined by "our" program.
    - Sets up processes by calling `start()`.
    - Creates handcrafted (rather than hardware) stack frame, so process can be started through normal return.
    - Calls `make_ready()` to add process to appropriate queue. \ At initialisation, all processes are `ACTIVE` and in the ready queue.
    - Make current function the idle task.
    - `yield()`, so OS starts scheduling procedure.
  ]
]

#slide[
== Selecting Next Process
We end up in `system_call(...)` again.
```c
unsigned *system_call(unsigned *psp) {
    short *pc = (short *) psp[PC_SAVE]; /* Program counter */
    int op = pc[-1] & 0xff;  // Syscall number from SVC instr
    os_current->sp = psp;    // Save sp of the current process
    ...
    switch (op) {
    case SYS_YIELD:
        // Add current to back of Q. Choose next process.
        make_ready(os_current); choose_proc(); break;
        ... }
    return os_current->sp; }  // Return sp for next process
```
]

#slide[
  == Selecting Next Process
  Find highest priority process to run, remove it from queue, `return`.
  ```c
static inline void choose_proc(void) {
    for (int p = 0; p < NPRIO; p++) {
        queue q = &os_readyq[p];
        if (q->head != NULL) {
            os_current = q->head;
            q->head = os_current->next;
            return;
        }
    }
    os_current = idle_proc;
}
  ```
]

#slide[
#item-by-item[
  #callout_question[How does the OS decide which process to run next?][
    But this time, if we send a message.
  ]
  #[Remember: Send and receive are also calls to OS! \ ]
#[`microbian.c`:
```c
void NOINLINE send(int dest, message *msg) {
    syscall(SYS_SEND);
}
```]

#[`hardware.h`: \
```c #define syscall(op)     asm volatile ("svc %0" : : "i"(op))```]
]
]

#slide[
  == System Call after `send()`
  Just like `yield()`, `send()` simply causes a syscall interrupt.
  ```c
unsigned *system_call(unsigned *psp) {
  short *pc = (short *) psp[PC_SAVE];
  int op = pc[-1] & 0xff;
  os_current->sp = psp;
  switch (op) {
  case SYS_SEND:
    mini_send(arg(0, int), arg(1, int), arg(2, message *));
    break; ...
  }
  return os_current->sp;
}
  ```
]

#slide[
  == Sending Messages
  Remember the rules for communication by messages!

  #item-by-item[
    #[Two possible cases:]
    
    #[The destination process is `RECEIVING` and can receive message]
    - Transfer message to destination. Destination `READY`. Add to queue.

    #[The destination process cannot receive...]
    - Multiple possible reasons for this (Q: which?)
    - Must (somehow) keep sender in queue until process is ready to receive it.
  ]
]

#slide[
== Sending Queues
Processes can have multiple other processes waiting to send.
#grid(columns: (1fr, 2.1fr), [
  #set align(horizon)
  Next process trying to send is stored in `waiting`.

  Rest of the send queue is chained through `next`.

  Q: Does this conflict with the ready queue?
], [#set align(center)
#image("./figures/sending-queues.png", height: 78%)])
- Active process has 3 processes waiting to send to it.
- One process waiting to send also has a process waiting to send to _it_.
- One waiting to receive, but nothing to send to it yet.
- One waiting to receive, with one waiting to send to it, but not the right type of message.
]
/*
In the diagram, there is also a process that is in RECEIVING state, waiting to receive a message. It is not linked to any sender, but potential senders know its process id, and can get in touch when they are ready to send. In addition, there is a process that is in RECEIVING state but nevertheless has another process waiting to send to it. That process must have asked to receive a message with a specific type, and the process that is waiting wants to send a different type of message. The receiving process will have to receive first the message it is waiting for; then perhaps it will call receive again and accept the message from the waiting process.
As the diagram shows, any process that is not DEAD (or the idle process), and is not currently waiting to receive from ANY, can have a queue of other processes waiting to send. Each waiting process is in SENDING state (so is not on the ready queue), and can be on the queue of only one process – the one it is hoping to send to. Therefore, we can manage with only one next link for each process, and we don't have to allocate storage dynamically to cope with any eventuality that might arise.
*/



#slide[
  == System call after `send()`
```c
static void mini_send(int dest, int type, message *msg) {
  int src = os_current->pid;
  proc pdest = os_ptable[dest];
  if (accept(pdest, type)) { // Receiver is waiting
    deliver(pdest->msgbuf, src, msg);
    make_ready(pdest); make_ready(os_current);  // *DISCUSS*
  } else {
    os_current->state = SENDING;
    queue_send(pdest);  // Sender waits. Join receiver's queue
  }
  choose_proc();
}
```
]


#slide[
  #callout_question[How does the OS decide which process to run next?][
    But this time, if we *receive* a message.
  ]
#item-by-item[
  #[Three possible cases:
  
]
  #[Can receive a message from an interrupt $=>$ discuss later.]
  
  Suitable message is waiting to be delivered.
  - Deliver message of suitable type, from process.
  - Both processes can now continue.
  No suitable message can be delivered.
  - 

  
]
]





#slide[
== Receiving Messages
```c
static void mini_receive(int type, message *msg) {
  if (/* interrupt is due */) { // later...
  } else {
    proc psrc = find_sender(os_current, type);// search send Q
    if (psrc != NULL) { // Is a sender waiting?
      deliver(msg, psrc->pid, psrc->msgbuf);
      make_ready(os_current); make_ready(psrc);
    } else { // No luck: we must wait
      set_state(os_current, RECEIVING, type, msg);
  } }
  choose_proc();
}
```
]

#slide[
  #set align(horizon)
  #callout_question[How are messages transferred between processes?][
    And in particular, how is this done in interrupts?
  ]
]

#slide[
  == Interrupt Handler
```c
void default_handler(void) {
    int irq = active_irq(), task;
    if (irq < 0 || (task = os_handler[irq]) == 0)
        panic("Unexpected interrupt %d", irq);
    disable_irq(irq);
    interrupt(task);
}
```

#light[Discuss code.]
]

#slide[
  #item-by-item[
  #callout_question[How are messages delivered][]
```c
static inline void deliver(proc pdest, proc psrc)
{
    if (pdest->msgbuf) {
        *(pdest->msgbuf) = *(psrc->msgbuf);
        pdest->msgbuf->sender = psrc->pid;
    }
    make_ready(pdest);
}
```
]
]

#slide[
  == Summary
  - Process table
  - Process states
  - Ready queues
  - Send queues
  - Implementation of delivery schedule of messages

  Notes contain another example of a device driver, and a discussion of `SENDREC`. Do take a look at this.
]

#slide[
  == End of Term!
  Next term, start from the complete bottom of the stack:

  #callout_question[How to we build a computer?][... starting from a transistor]
]

