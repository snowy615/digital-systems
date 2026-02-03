#import "theme.typ": *
#show: doc => conf(doc)

#title-slide(title: [Lecture 4 \ Assembly Programming])

// #enable-handout-mode(true)

#slide[
  == Last Lecture: Recap
  #item-by-item[
    - Different types of memory on micro:bit, all in one address space
      - Flash, RAM, memory-mapped peripherals
    - Compiling: Each source (`.c` or `.s`) file becomes an object (`.o`) file.
      - Turning each source file into machine code
      - We saw the machine code of our `adds` and `bx lr` instructions!
      - Unknown absolute memory addresses
    - Disassembly: From machine code back to assembly.
    - Linking: Giving subroutines absolute addresses.
    - Startup procedure
  ]
]

#slide[
  == Forgot to mention... // TODO: Remove next year, should not be necessary
  What is the format that we actually _send_ the final code in?
  #item-by-item(start: 2)[
  - `more func.hex` \
    I.e. _text_-encoded hexadecimal. The "programmer chip" on the micro:bit turns this into binary, before sending it to the Nordic ARM chip.
  - Can we still see `18404770` anywhere?
  - No! Instead, we see `40187047`. Stored "little-endian".
  ]
  #set align(center)
  #uncover(4)[
  #image("./figures/endianness-wikipedia.png", width: 40%)]
]

#slide[ // TODO: Remove next year
  If you want to practice + learn more about this: \
  - Additional questions on this in `problem-sheets/prob1-new.pdf`. \
  - Answers are included, so good study material.
]

#slide[ // TODO: Remove next year
  #set align(horizon)
  #callout_question[Why is there a separation between the compiler and linker?][]

  #show: later

  #one-by-one(start: 2)[
    So you can pre-compile parts of your code.
    - Compiling takes time! Some projects take hours to compile. \
      Only compiling parts that have changed, saves time.][
    Simplification and encapsulation of tasks:
    - Compiler only needs to know what CPU _core_ we're running on, i.e. which instructions our CPU (Cortex-M0) has.
    - Linker needs to know details about specific chip, e.g. the memory map.
  ]
]

#title-slide(title: [Lecture 4 \ Assembly Programming])


#slide[
  == Demo: Coding Assembly
  #reveal-code(lines: (3,4,5,6,7))[
    ```
    @ (a^2 - b^2) = (a+b) * (a-b)
    @ at calling a is stored in r0
    @            b is stored in r1
    adds r3, r0, r1     @ (a + b) stored in r3
    subs r0, r0, r1     @ (a - b) stored in r0
    muls r0, r3, r0
    bx lr
    ```]
]


#slide[
  == What Instructions Can I Use?
  // Back to our question
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
  Let's look at details of `add` instruction.
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

#slide[
  == Different Flavours of Addition
  #image("figures/arm-addition-instructions.png")

  #v(0.6cm)

  #callout_idea[Optimise The Common Case][
    - Design principle: Make the common case fast, while leaving uncommon case possible.
    - Amdahl's law: The maximum achievable speed-up of an optimisation is limited by how often the optimised part is used.
  ]
]

#slide[
  #set align(horizon)
  #thebig_idea[For the exam:
  
  Familiarise yourself with the instructions, \ but no need to memorise.]
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
  == Demo: Programming, Running, Debugging
  How do we check whether the programming is running as expected?

  Directory `/lab1`
  #item-by-item[
  - `make mul1.hex`
  - Run code. `minicom` for communication.
  - `./debug mul1.elf`
  - `layout asm`
  - `layout regs`
  - `break *func`
  - `stepi`
  ]
]

#slide[
== Recap
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


