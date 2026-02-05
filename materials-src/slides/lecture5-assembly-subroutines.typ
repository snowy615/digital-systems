#import "theme.typ": *
#show: doc => conf(doc)


#title-slide(title: [Lecture 5 (Part I) \ Optimising Assembly])

#slide[
== Recap: Last time
#callout_info[Understanding Compilation Process][
  What is specified after compilation, and what after linking.
]
#callout_skill[Programming in Assembly][
  - Assembly has quirks: They are there for a reason! (Remember?)
  - Looking them up in references.
]

#callout_skill[Using a Debugger][
  - Stepping through assembly, instruction-by-instruction.
  - Viewing effect on registers.
]
]


#slide[
  == Naive Multiplication in C
    #image("figures/code-multiplication-c.png", height: 90%)
]



#slide[
  == Which Instructions are Actually Used?
#image("figures/code-multiplication-disasm.png", height: 90%)
]

#slide[
  == Look at the Brach Offset
  #set align(center + horizon)
#image("figures/branch-encoding.png", height: 70%)
]


#slide[
== Pipelining
#callout_question[Why is there an offset of 4 in relative addresses in jumps?][
  - `4: beq.n` would jump +2 instructions ahead.
  - `a: b.n  ` would jump -6 instructions ahead.
]
#v(0.8cm)
#show: later
Executing an instruction is more complex than previously described.
 - Executing instruction is broken up into stages.
 - In ARM Cortex-M0, 3 cycles needed to execute a single instruction.
 - However, stages operate in _parallel_, so still 1 instruction _per_ cycle.

]

#slide[
 == Pipelining: Branch offset
 #table(
  columns: (auto, auto, auto, auto, auto, auto),
  inset: 8pt,
  align: horizon,
  [cycle], [#pc], [Fetch], [Decode], [Execute], [],
  [1], [0], [`movs`], [], [], [],
  [2], [2], [`cmp`], [`movs`], [], [],
  [3], [4], [`beq`], [`cmp`], [`movs`], [],
  [4], [6], [`subs`], [`beq`], [`cmp`], [],
  [5], [8], [`adds`], [`subs`], [`beq`], [branch executed now!],
//  [6], [10], [`b`], [`adds`], [`subs`], [next instruction as normal],
//  [7], [12], [`movs`], [`b`], [`adds`], [],
  )
  #item-by-item(start: 2)[
  - When branch is executed, #pc is 8.
  - Want to jump two instructions ahead.
  - $arrow.double$ Encode offset of 2 instructions!
  - CPU handles multiplication by two (bit shift) before adding to #pc.
  ]
]

#slide[
  == How Good is Our Code?
  #one-by-one[
  _Good_ assembly programmers (compiler, mostly) should produce _fast_ code.][
  Instruction timings completely predictable (unlike modern archs):]
  #item-by-item(start: 3)[
  - Usually: One cycle per instruction.
  - Branch: Taken branch takes 2 cycles _extra_ (3 total), otherwise 1.
  - Load / store: Two cycles (one extra for memory access).]
  #uncover("6-")[Find number of cycles:]
  #item-by-item(start: 7)[
  - Can measure (oscilloscope, see labs)
  - Count instructions (7 cycles)
  ]
  #uncover("9-")[
  #callout_question[Why do branches take 3 cycles?][]]
]

#slide[
 == Pipelining: Normal Operation
 #table(
  columns: (auto, auto, auto, auto, auto, auto),
  inset: 8pt,
  align: horizon,
  [cycle], [#pc], [Fetch], [Decode], [Execute], [],
  [1], [0], [`movs`], [], [], [],
  [2], [2], [`cmp`], [`movs`], [], [],
  [3], [4], [`beq`], [`cmp`], [`movs`], [],
  [4], [6], [`subs`], [`beq`], [`cmp`], [],
  [5], [8], [`adds`], [`subs`], [`beq`], [branch not taken],
  [6], [10], [`b`], [`adds`], [`subs`], [next instruction as normal],
  [7], [12], [`movs`], [`b`], [`adds`], [],
  )
]


#slide[
 == Pipelining: Branch Taken
 #table(
  columns: (auto, auto, auto, auto, auto, auto),
  inset: 8pt,
  align: horizon,
  [cycle], [#pc], [Fetch], [Decode], [Execute], [],
  [1], [0], [`movs`], [], [], [],
  [2], [2], [`cmp`], [`movs`], [], [],
  [3], [4], [`beq`], [`cmp`], [`movs`], [],
  [4], [6], [`subs`], [`beq`], [`cmp`], [],
  [5], [8], [`adds`], [`subs`], [`beq`], [branch taken!],
  [6], [12], [`movs`], [`adds X`], [`subs X`], [do not execute!],
  [7], [14], [`bx`], [`movs`], [`adds X`], [do not execute!],
  [8], [16], [`...`], [`bx`], [`movs`], [as normal]
  )
]


#slide[
  == Can We Do Better?
    Solutions:
    - Better algorithm (e.g. $O(log n)$).
    - "Squeeze" loop. // Try to teach you a few techniques.
]

#slide[
  == Optimisation
#image("figures/code-multiplication-asm-opt1.png", height: 90%)
]

#slide[
  == Optimisation
#image("figures/code-multiplication-asm-opt2.png", height: 90%)
]

#slide[
  == Optimisation
  Let subs set the condition codes.
  #image("figures/code-multiplication-asm-opt3.png", height: 57%)
  - 5 cycles per iteration!
  - Would be `do..while` loop in C.
]

#slide[
  == Loop Unrolling
  Duplicate the loop body n times.
 m #image("figures/code-multiplication-asm-opt4.png", height: 66%)
- 3.5 cycles per iteration!
]

#slide[
  == Observations on Assembly Programming
  #item-by-item[
- Writing optimised asm code is labourious! Small changes in details of program impact many other lines (e.g. change in register!)
- Good compilers can generate very efficient assembly code from C code.
  - E.g.: It's hard for us to use higher registers. Requires knowing a lot of these quirks of assembly, which instructions can use high registers, and how. Compilers can do this well.
- It's good to know _how_ to write a very fast, tight loop, but no need to spend all your time doing this for _every_ bit of code. (Amdahl's law)
  ]
  #uncover(4)[
#callout_idea[Debugger is _super_ helpful for writing code. Learn it!][]]
]

#slide[
== Recap
#callout_idea[Pipelining][
- Instructions are executed over multiple clock cycles in parallel.
- Complicates branch instructions, and makes them slower.
]

#callout_skill[Determining execution time of assembly program][]
#v(-0.85cm)
#callout_skill[More complex assembly programming, and optimisation][]
]


#title-slide(title: [Lecture 5 (Part II) \ Subroutines])

// #enable-handout-mode(true)

#slide[
  == Previously: We created a subroutine
  Problems:
  #item-by-item(start: 2)[
  #[We wrote a single subroutine, but with limitations:]
  - Could not call other subroutines.
  - Could only use #r0 - #r3, while leaving #r4 and above unchanged.
  #[These kinds of subroutines are very useful, because they are very *efficient*.] 
  ]
]

#slide[
// == Today
// So far all our assembly programming was in one subroutine, using only registers #r0 to #r3, while leaving the others alone.

#item-by-item[
#callout_question[How can we create subroutines which can call others?][
  - Remember value of #lr that will get overwritten by next jump.
]
#callout_question[How can we use #r4 and above?][
    - Must restore of #r4 and above at the end of subroutine.
]
#callout_question[How can we accept more than 4 arguments?][
  - Arguments are stored in #r0 - #r3. Where do additional ones go?
]
#callout_question[What if we need more local memory than the registers?][
  - Where should we store these?
]
#v(0.6cm)
Today we will discuss how to use RAM to solve these problems.
]
]

#slide[
  #item-by-item[
#[#callout_important[Subroutines should be black-box][
  Subroutines should work no matter who calls them. Instructions inside are fixed!
  - We need conventions that allow the same instructions to perform the same operation, *regardless of the state of the calling subroutine(s)*.
]
#v(0.6cm)]
Store registers in fixed memory addresses?
#[
  #v(0.6cm)
#callout_warning[We cannot use absolute memory addresses][
  What about subroutines calling themselves (indirectly)?
]
]
]
]

#slide[
  #[#thebig_idea[Use a _Stack_ for local variables]
  #v(1cm)]
  - Let subroutines use memory relative to the _stack pointer_ (register #sp).
  - Memory below in the stack is used by calling subroutines, and should remain untouched.
  - Memory above in the stack is free to be used by the subroutine.
#[This is only one possible solution, but is the one chosen by design in ARM. Special instructions are created to facilitate using the stack.]
]

#slide[
  == The Stack
  #v(-0.5cm)
  #grid(columns: (9cm, 3.5cm, 3.5cm, 3.5cm, 3.5cm), gutter: 15pt, [#image("figures/stack.png", width: 100%)], [
  Example: #v(-0.8cm)
  #table(columns: (auto), inset: 10pt, align: horizon, [`main()`], [`sub1()`], [`sub2()`], [`sub3()`])
],
[
  Return:#v(-0.8cm)
#table(columns: (auto), inset: 10pt, align: horizon, [`main()`], [`sub1()`], [`sub2()`], )
],
[
  Call next:#v(-0.8cm)
  #table(columns: (auto), inset: 10pt, align: horizon, [`main()`], [`sub1()`], [`sub2()`], [`sub4()`])
],
[
  Call next:#v(-0.8cm)
  #table(columns: (auto), inset: 10pt, align: horizon, [`main()`], [`sub1()`], [`sub2()`], [`sub4()`], [`sub5()`])
]
)
#v(-0.8cm)
#item-by-item[
- Convention: Stack starts at top of address space, and grows downwards. So "above" in the stack has a lower address!
- Each time a subroutine is called, all memory below #sp is a usable region of memory (stack frame), that won't interfere with other subroutines.
- When a subroutine returns, the caller finds its stack frame as it left it.
]
]

#slide[
  == Subroutine Contract
  #[Calling function:
  - Places first arguments 1 ... 4 in #r0 - #r3
  - Places arguments $>=4$ on stack (called function knows how many to expect) (labs won't need this)]
 #[Called function:
  - Leave values of #r4 and up unchanged on return
  - Leave stack pointer #sp unchanged on return
  - Leave stack below current location (i.e. memory addresses above #sp) unchanged
  - Leave return value in #r0]
]

#slide[
  == Subroutine Convention
  Subroutine can use stack in whatever way it wants (assuming there is space!), but ARM provides instructions for:

  #set align(center)
  #image("figures/subroutine-stack-convention.png", height: 69%)
]

#slide[
  == Storing Registers
#item-by-item[
  #[ARM provides two assembly instructions to make restoring state following subroutines easy:]
  - `push {REGISTER_LIST}`: Place registers in list on stack in order, and decrease #sp accordingly.
  - `pop {REGISTER_LIST}`: Take values from stack, and place into the registers in list order, and increase #sp accordingly.
`func:
    push {r4, r5, lr} @ Save registers
    @ Use r4 and r5, call other routines
    pop {r4, r5, pc} @ Restore and return`
]
// Want to store r4, r5 to abide by the contract to our caller
// Want to store lr so we can call other subroutines
]

// #slide[
// #item-by-item[
// #callout_question[Q: Can you explain why the `push`/`pop` instructions imply that the return addr comes under the saved regs in the stack?][
// This looks like convention, but it has good a good reason!]
// #[
// Answer: If you `pop` back into #pc
// ]
// ]
// ]

#slide[
  == Push & Pop Peculiarities
  - `push`/`pop` can store/restore lower registers (#r0 - #r7)
  - `push` can store `lr`, as well
  - `pop` can restore to `pc`, as well

  #show: later
  #[Prev, we saw we could return from a subroutine using `bx lr`. Using `pop` to restore to #pc gives the same effect, but without first restoring to #lr!]

  #show: later
  #[#v(0.6cm)
    #callout_info[`push`/`pop` depart from RISC principles!][Normally, one instruction does one thing, but this gives speedup! \ Load/store operation is 2 cycles, while `push`/`pop` is 1+n cycles.]]
  #[
  #v(0.6cm)
  Remember, instruction set designers optimised the common case.]

]

#slide[
#set align(center + horizon)
== Putting it all together
]

#slide[
== Example: Factorial
`int fac(int n) {
    int k = n, f = 1;
    while (k != 0) {
        f = mult(f, k);
        k = k-1;
    }
    return f;
}`

Subroutine calls another subroutine! So we will use what we discussed.
]



#slide[
== Example: Factorial, opening
- As usual, let's start by converting code to assembly, and not worrying about efficiency.
- For clarity, I recommend making clear which variables are assigned to which registers (little table in your exam answer helps!)
- Let's assign `k` to #r4, and `f` to #r5 (logic behind this?)
- Must use `push`.


`fac:
    push {r4, r5, lr}
    movs r4, r0             @ Initialise k to n
    movs r5, #1             @ Set f to 1`
]



#slide[
== Example: Factorial, Loop
Again, we can worry about optimisations later:

`fac:
    push {r4, r5, lr}
    movs r4, r0             @ Initialise k to n
    movs r5, #1             @ Set f to 1
again:
    cmp r4, #0              @ Is k = 0?
    beq finish              @ If so, finished`
]




#slide[
== Example: Factorial, Subroutine Call
Again, we can worry about optimisations later:

`...
again:
    cmp r4, #0              @ Is k = 0?
    beq finish              @ If so, finished

    movs r0, r5             @ Set f to f * k
    movs r1, r4
    bl mult                 @ branch link instruction!
    movs r5, r0`
]




#slide[
== Example: Factorial, Finish Loop
`...
again:
    cmp r4, #0              @ Is k = 0?
    beq finish              @ If so, finished

    movs r0, r5             @ Set f to f * k
    movs r1, r4
    bl mult                 @ branch link instruction!
    movs r5, r0

    subs r4, r4, #1         @ Decrement k
    b again                 @ And repeat`
]





#slide[
== Example: Factorial, Return Subroutine
`...
again:
    cmp r4, #0              @ Is k = 0?
    beq finish              @ If so, finished

...

finish:
    movs r0, r5             @ Return f
    pop {r4, r5, pc}`
]




#slide[
== Example: Factorial, All Together
`fac:
    push {r4, r5, lr}
    movs r4, r0             @ Initialise k to n
    movs r5, #1             @ Set f to 1
again:
    cmp r4, #0              @ Is k = 0?
    beq finish              @ If so, finished

    movs r0, r5             @ Set f to f * k
    movs r1, r4
    bl mult                 @ branch link instruction!
    movs r5, r0

    subs r4, r4, #1         @ Decrement k
    b again                 @ And repeat
finish:
    movs r0, r5             @ Return f
    pop {r4, r5, pc}`
]





#slide[
== Example: Factorial, optimisation
You may have spotted that `f` can live in #r0 constantly, since the return value of `mult()` will also be the first argument for the next call.

Optimising compilers can spot this.
]


#slide[
== Summary
#callout_question[How can we create subroutines which can call others?][
  - Remember value of #lr that will get overwritten by next jump.
]
#callout_question[How can we use #r4 and above?][
    - Must restore of #r4 and above at the end of subroutine.
]
#[
  #v(0.8cm)
- See notes for:
  - Expanded discussion
  - More efficient multiplication routine
- Don't forget rainbow chart and instruction overview!]
]


// `bl` instruction: branch and link
// Little table of which variables you assign to which register. Make it easy on your examiner to verify your code!