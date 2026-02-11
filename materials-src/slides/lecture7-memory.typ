#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)

#title-slide(title: [Lecture 7 \ Memory and Addressing])

#slide[
  #set align(center + horizon)
  == Questions about the course so far?
]

#slide[
  #callout_question[How can we access memory?][We have seen `push` and `pop`, but they were designed for the stack!]
  #callout_question[How can we place values in a subroutine in memory?][I.e. _local_ variables.]
  #callout_question[How can place values in memory that can be accessed in all subroutines?][I.e. _global_ variables.]
  #callout_question[How can we handle variable amounts of data?][I.e., what happens if we don't know when we write the program, how many variables we need to store?]
]

#slide[
  #set align(horizon)
  #thebig_question[How can we access memory?]
]

#slide[
  == Accessing Memory
  Instructions for storing and loading locations in memory: `str` and `ldr`.
  #item-by-item(start: 2)[
  - Remember: Memory is accessed by providing an _address_. // Draw picture of memory on board
  - `ldr` and `str` have different ways of calculating the address.
  - These are called _addressing modes_.
  ]
  #uncover(5)[
  We can use the `ldr` and `str` instructions in two different syntaxes, to use the different addressing modes:
```
xxr r0, [r1, #20]      @ Load/store r0 in r1 + 20
xxr r0, [r1, r2]       @ Load/store r0 in r1 + r2
```
]
]


#slide[
  == Accessing Memory: Peculiarities
  #item-by-item[
    - Typical encoding: Only the lower registers #r0 - #r7 can be used.
    - Alternative encoding for:
      ```
    --r r0, [sp, #20]
    --r r0, [pc, #40]
    ```
    - Different constant ranges allowed.
    - Addresses must be _aligned_, based on their size. \ E.g. for 4-byte quantities, we need `addr % 4 == 0`.
  ]
    #uncover(5)[
      In Native ARM code, we also allow \
      `    ldr r0, [r1, r2, LSL #x]      @ r1 + r2 << x` \
      to make this easy to enforce. In Thumb, we made need more instructions.
    ]
]


#slide[
  #set align(horizon)
  #thebig_question[How can we store (in memory) local variables?]
]

#slide[
== Local Variables
Local variables are allocated on the stack. #light("Remember why?")
  #set align(center)
  #image("figures/subroutine-stack-convention.png", height: 69%)
]

#slide[
== Factorial Example: Allocating Local Variables
Instead of restoring #r4, #r5, let's keep variables in memory.

#light("draw stack on board")

#grid(columns: (0.65fr, 1fr), [
```c
int fac(int n) {
  int k = n, f = 1;//<==
  while (k != 0) {
    f = mult(f, k);
    k = k-1;
  }
  return f;
}
```], [
```
fac:
    push {lr}       @ Save return addr
    sub sp, sp, #8  @ Allocate 8 bytes
    str r0, [sp,#4] @ Save n as k
    movs r0, #1     @ Set f to 1
    str r0, [sp,#0]
    ...
```])
]


#slide[
== Factorial Example: Accessing Local Variables
#grid(columns: (0.65fr, 1fr), [
```c
int fac(int n) {
    int k = n, f = 1;
    while (k != 0) {
        f = mult(f, k);
        k = k-1;  // <==
    }
    return f;
}
```], [
```


...
ldr r0, [sp, #4]  @ fetch k
subs r0, r0, #1   @ decrement it
str r0, [sp, #4]  @ save it again
...
```])
]


#slide[
== Factorial Example: De-allocating Local Variables
#grid(columns: (0.65fr, 1fr), [
```c
int fac(int n) {
    int k = n, f = 1;
    while (k != 0) {
        f = mult(f, k);
        k = k-1;
    }
    return f;  // <==
}
```], [
```



...
finish:
    ldr r0, [sp, #0]
    add sp, sp, #8
    pop {pc}
```])
Subroutine contract:
- Return value in #r0
- Must leave #sp unchanged (so stack is in same state as we found it)
]




#slide[
  #set align(horizon)
  #thebig_question[How can we store (in memory) global variables?]
]


#slide[
  == Global Variables
    Global variables are stored at a fixed absolute location. #light("Remember why?")
      #item-by-item(start: 2)[

  Addresses are 32-bit quantities. How can we load the address into a register?
  - Can use `movs rx, #255` to load 8 bits into a register.
  - Can store a 32-bit constant in memory, and load it. #[#set align(center)
  #image("./figures/ldr-const.png", height: 25%)]
    Then can load _value_ with `ldr r2, [r1, #0]`.
]
]


#slide[
  == It's annoying to manually manage addresses and offsets
  #[`ldr` using #pc as the base is again peculiar!]
  - #pc is always 4 ahead of instruction being executed...
    - Makes calculating offsets error-prone.
  - Addresses need to be aligned so `addr % 4 == 0`.
    - Thumb instructions are 16-bit, so #pc can be un-aligned.
  #[

    `ldr r2, [pc, #d]` rounds #pc down to a multiple of 4 #light("(how to implement this in hardware?)") before adding offset.
  ]
#callout_warning[You don't want to memorise or deal with all this.][Don't want to manually assign addresses, or remember peculiarities.]
]


#slide[
  == Relying on the Assembler
  Can we get the assembler to?
  - Select an address in RAM for the global variable?
  - Store the address in ROM?
  - Load the address from ROM without us needing to worry about the address of the address?
]


#slide[
== Global Variables: Example

```c 
int count = 0;
void increment(int n) {
  count = count + n;
}
```


```
   ldr r1, =count      @ Neat shorthand for ldr r2, [pc, #d]!
   ldr r2, [r1, #0]    @ r2: store value of count addr
   adds r0, r2, r0     @ r0: store n
   str r0, [r1, #0]
   
```

Now we must tell the assembler what `count` refers to.
]


#slide[
  == Telling the Assembler about Locations in RAM
  ```
    .bss                @ Place the following in RAM
    .balign 4           @ Align to a multiple of 4 bytes
count:
    .word 0             @ Allocate a 4-byte word of memory
```
]

#slide[
  == Assembler Input
  #columns(2, gutter: 11pt)[
  ```
    .text         @ I.e. ROM
    .thumb_func
func:
    ldr r1, =count
    ldr r2, [r1]
    adds r0, r2, r0
    str r0, [r1]
    bx lr
    .pool         @ Const pool


    
    .bss      @ I.e. RAM
    .align 4
count:
    .word 0
  ```
]
]


#slide[
  == Assembler Output
  #image("./figures/global-assembler-disassembly.png", height: 90%)
]

#slide[
== Linker Output
#image("./figures/global-linker-disassembly.png", height: 90%)
]








#slide[
  #set align(horizon)
  #thebig_question[How can we store (in memory) arrays?]
]

#slide[
== Array Addressing
#grid(columns: (1fr, 1fr), [
- Arrays are just a collection of contiguous memory locations
- Can allocate arrays of fixed size in memory (`.bss`),
- ...or of variable size on stack.

```c
static int account[10];
int deposit(int i, int a) {
  int x = account[i] + a;
  account[i] = x;
  return x;
}
```
], [
#image("./figures/array-addressing.png", height: 85%)
])
]

#slide[
  == Array Addressing in Assembly
  ```
deposit:
    ldr r3, =account  @ r3 is base of array
    lsls r2, r0, #2   @ r2 is 4*index
    ldr r0, [r3, r2]  @ Fetch balance
    adds r0, r0, r1   @ Add deposit
    str r0, [r3, r2]  @ Store back in array
    bx lr
    
    .bss
    .balign 4
account:
  .space 40           @ 40 bytes for 10 ints
  ```
]


#slide[
  #set align(horizon + center)
  == Wrap-up
]

#slide[
  == Other load/store instructions
  `ldr` and `str` deal in 32-bit values, the size of a register. But there are also
- `ldrb` and `strb` for 8-bit values (useful for strings).
- `ldrh` and `strh` for 16-bit values.
- `ldrsb` and `ldrsh` to load 8- or 16-bit values with sign extension. #light("Why is this necessary?")
On Thumb, some of these exist only with the
reg+reg addressing mode.
]

#slide[
  == Summary
  #callout_question[How can we access memory?][`ldr` and `str`.]
  #callout_question[How can we implement local variables?][Allocate on stack, and access with constant offsets.]
  #callout_question[How can we implement global variables?][Store address in ROM, load this, then access RAM location.]
  #callout_question[How can we implement arrays?][Access with addressing that adds two registers.]
]


