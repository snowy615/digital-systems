#import "theme.typ": *
#show: doc => conf(doc)

#title-slide(title: [Lecture 4 \ Assembly Programming])

// #enable-handout-mode(true)

#slide[
  == Datasheet: Different ways of Adding
  // Back to our question
  #item-by-item[
  #callout_question[How to look up allowed instructions?][
    We have three summaries:
    - "Rainbow Chart" (included in exam)
    - List of common instructions (included in exam)
    - Arm Thumb Quick Reference Guide (official from ARM)
    #v(0.3cm)
  
    Definitive document is ARM v6-M Architecture Reference Manual.
  ]
  // Describes all quirks of programming for ARM.
  // More detail than we'll usually need. And like I said in previous lectures, no need to memorise all quirks.
  // Still, the reference manual for our CPU core is 374 pages. Contrast this to the one for the chip on Raspberry PI is 12000 pages.
  // When doing anything with hardware, you will need to interact with datasheets at some point.
  // Skill: To find the pages that you need from the entire forest.
  // Things that are included give a general description, and we will guess that behaviour will otherwise be fairly uniform.
  // Demo: 
  #v(0.6cm)
  #[Let's look at details of `add` instruction.
  - Index: A.6 Thumb Instruction Details // All explanations are in that document! First sections of A.6
  - A.6.7 Alphabetical list of ARMv6-M Thumb instructions
  - Various flavours of `add` instructions.
]
// Scroll through
// ADC addcarry (add but uses the status bits to chain together add operations, if you need to add numbers larger than 32 bits)
// Let's first look at the flavour ADD (register)
// If you add two numbers in a high-level language, this is probably the instruction it'll translate to.
// You see two flavours: Two source, one dest reg, but all lower regs.
// Or addition with any regs, but you need to overwrite one of the source regs.
// Consequence of limited space in the encoding.
// Weird quirk in the encoding: split address for register "DN". No idea why. But luckily assembler takes care of this!
//
// Second flavour of ADD: ADD (immediate)
// Several sub-flavours, can add two registers and a 3 bit constant constant (we saw this)
// While this seems really restrictive, there's sipmly limited space in the instruction encoding, so things need to be prioritised.
// ARM Designers were very careful to prioritise operations that are common.
// Addition with small constants are very common. Most common is plus 1, think for loops.
// Alternatively, you can add one register and 8 bit constant.
// If you want the destination to be a different register, you may need to load a large constant into a different register first, and then perform the addition, at the cost of using two instructions.
// So overall, the design principle is to make the common case fast, while leaving the uncommon case possible.
]
]

#slide[
  == Different Flavours of Addition
  #image("figures/arm-addition-instructions.png")

  #v(0.6cm)

  #callout_idea[Optimise The Common Case][
    - Design principle: Make the common case fast, while leaving uncommon case possible.
    - Amdahl's law: The maximum achievable speed-up of an optimisation is limited by how often the optimised part is used.
  ]
]


// Now that you have some more tools to figure out what goes on
#slide[
  #set align(center + horizon)
  = More Assembly Programming
]


#slide[
  == Naive Multiplication in C
    #image("figures/code-multiplication-c.png", height: 90%)
]

#slide[
  == Naive Asm Translation of Naive Multiplication in C
#image("figures/code-multiplication-asm.png", height: 90%)
]

#slide[
  == Which Instructions are Actually Used?
#image("figures/code-multiplication-disasm.png", height: 90%)
]

#slide[
== Pipelining
#item-by-item[
#callout_question[Why is there an offset of 4 in relative addresses in jumps?][
  - `4: beq.n` would jump +2 instructions ahead.
  - `a: b.n  ` would jump -6 instructions ahead.
]
Executing an instruction is more complex than previously described.
 - Executing instruction is broken up into stages.
 - In ARM Cortex-M0, 3 cycles needed to execute a single instruction.
 - However, stages operate in _parallel_, so still 1 instruction _per_ cycle.
]
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
  #item-by-item[
  #[_Good_ assembly programmers (compiler, mostly) should produce _fast_ code.]
  #[Instruction timings completely predictable (unlike modern archs):
  - Usually: One cycle per instruction.
  - Branch: Taken branch takes 2 cycles _extra_ (3 total).
  - Load / store: Plus one cycle.]
  #[Find number of cycles:
  - Can measure (oscilloscope, see labs)
  - Count instructions (7 cycles)
  ]
  #callout_question[Why do branches take 3 cycles?][]
  ]
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
  #item-by-item[
  #[
    Solutions:
    - Better algorithm (e.g. $O(log n)$).
    - "Squeeze" loop. // Try to teach you a few techniques.
  ]
]
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
- Remember Amdahl's law!
  - It's good to know _how_ to write a very fast, tight loop, but no need to spend all your time doing this for _every_ bit of code.
  - Focus on where it matters.
  ]
]

#slide[
== Recap
#callout_skill[Looking up things in datasheets][]

#callout_idea[Instruction set restrictions][... exist for a reason and are specified in the datasheet.]
#callout_idea[Pipelining][
- Instructions are executed over multiple clock cycles in parallel.
- Complicates branch instructions, and makes them slower.
]

#callout_skill[Determining execution time of assembly program][]
#v(-0.85cm)
#callout_skill[More complex assembly programming, and optimisation][]
]




/*#slide[
Introduce program
- Connecting values to registers
- Talking in arguments to the function
- Transate C code to assembly
- Initialising to zero
- Introduce loop, branching instructions
- cmp instruction, subtraction, but output not written, only NZVC are set
- beq branch if equal, looks at Z bit, N bit if result is negative. V and C are related to overflow. Subtract negative number, then can overflow
- Need to put result in the right register, mov
- subs instruction
- adds instruction
- branch, conditional vs non-conditional. Perhaps discuss the various branch instructions seen so far.

Remember, different kinds of machine code for the same assembly instruction! There is ambiguity in our program. So, Q: Which one did the assembler actually choose? subs is a good example of this, since two constraints are satisfied, so multiple choices available.

Can we do better?
- Count instructions, in the loop. Done multiple times, so number of instructions here has most effect.
- Can assign time to each instruction
- If branch isn't taken: 1 cycle, if it is 3 cycles.
- Explain why: start by introducing pipelining
- More complicated processors: Branch prediction, caches... Can help things speed up, but also makes things less predictable.
- 7 cycles per loop

Some micro-optimisations:
- Branching back up, in order to do comparison
- Not to branch to top unless you need to.
- 5 cycle solution: translate back into C

Reminder about Amdahl's law. It's good to know _how_ to write a very fast, tight loop, but no need to spend all your time doing this for _every_ bit of code. Focus on where it matters.
- Writing optimised asm code is labourious! Small changes in details of program impact many other program properties
- Good compilers can generate very efficient assembly code from C code.
- It's hard for us to use higher registers. Requires knowing a lot of these quirks of assembly, which instructions can use high registers, and how. Compilers can do this well.
]
*/


