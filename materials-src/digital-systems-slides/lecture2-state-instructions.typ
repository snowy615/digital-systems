#import "theme.typ": *
#show: doc => conf(doc)

#title-slide(title: [Lecture 2 \ State and Instructions])

// #enable-handout-mode(true)

#slide[
  #one-by-one[
  #callout_question[How do instructions alter the CPU state?][
    - Understand the effect of instructions on the state of the CPU.
    - Worked example of executing an instruction.
  ]][
  #callout_question[How are instructions encoded electronically?][
    And how does this affect programming the machine?
  ]][
  #callout_skill[Decode machine code][
    I.e. how to take machine code, and determine what it will do.
  ]][
  #callout_question[How can we make parts of a program reusable?][How do subroutines work?]]
]

#slide[
  == RISC + The von Neumann Architecture
  #grid(columns: (1.6fr, 1fr),
  [
    //- Turing machines: not practical // Designed for conceptual/mathematical simplicity, not for practical considerations like speed, energy efficiency, programmability...
    Many other architectures are provably equally powerful to Turing machine (if given infinite memory)
    
    // We will consider ARM.

    - State machine: CPU
      - State stored in "registers"
    - Replace tape with *addressable memory* // Each location on memory has an "address", and by specifying the address you can get its contents in constant time.
    - Conceptual separation between instructions and data // Although this only matters for how the state of the CPU evolves. Instructions can be manipulated as data.
      - Can think of instructions as parameterising the lookup.
  ],
  {set align(right); image("figures/risc-vnm.png", width: 100%)})
]


#slide[
  == Operation
  #grid(columns: (1.5fr, 1fr),
  [
    + Controller fetches an *instruction* from memory, at location in Program Counter (#pc) #light[(What is instruction? Look up-table)]
    + Decode instruction \ RISC, so instructions are:
      - Load / Store \ (register $arrow.l.r$ memory)
      - Arithmetic / Logic \ (register $arrow.l.r$ register)
    + Execute instruction #light[(change state)]
    + Increment #pc by 1 instruction, and repeat
  ],
  {set align(right); image("figures/risc-vnm.png", height: 90%)})
]


#slide[
  == Implementation
  We will discuss electronics more later, but for now:
  #item-by-item(start: 2)[
  - All state is represented by an electrical voltage in a wire.
  - Voltage is "high" or "low", represented symbolically as "1" or "0".
  - Collection of wires encodes a binary number. \# of wires is "width".
  ]
  #one-by-one(start: 5)[We talk about "state", and "registers", and all that, but it's important to keep in mind that...
  #v(0.5cm)][
  #callout_info[Symbols we use map onto things that are _physically real_][If you could open up the chip, and attach an LED circuit to the wires, you would literally see them light up according to binary.]
]
]

#slide[
== Implementation
#grid(columns: (1fr, 1fr), [
#item-by-item[
  - Electrical circuits are etched onto silicon.
  - Can zoom in and _look_ at circuits!
  - Register file is a specific segment
  - _Representation_ of numbers, is high/low voltage on wires
]
], {
set align(center)
only(1)[#image("figures/386-chip.jpg", height: 90%)]
only((beginning: 2))[#image("figures/die-labeled-regs-w600.jpg", height: 90%)]
})
]

#slide[
  == Registers: A Closer Look
  Instructions manipulate the state of the CPU, stored in *registers*.
  #{
    set align(center)
    image("figures/arm-registers.png", height: 78%)
  }
]

#slide[
== Registers: Programming Limitations & Convention
All Registers are 32 bits "wide" #light[(How does this look in a physical circuit?)]
#item-by-item(start: 2)[
  - #r0 - #r7 : General purpose registers. Can be used for any value used in any calculation.
  - #r0 - #r3 : Handled differently during subroutine calls.
  - #r8 - #r12 : Can be used for any value, but not all instructions can use them, so not as "general purpose" as #r0 - #r7.
  - #pc : Program counter. Stores memory address of next instruction.
  - #lr : Link register. Stores address where current subroutine returns.
  - #sp : Stack Pointer.
  - #psr: Processor Status Register. Different bits have very specific meanings. Some instructions write bits, some read bits.
]
]

#slide[
  == The Effect of an Instruction
  // Let's consider the effect of an instruction.
  // Imagine pc=192, and the instruction at that location is loaded, which we represent in hexadecimal as 0x1840.
  #image("figures/instruction-adds.png", width: 90%)
  - Hex is convenient: Each hex digit corresponds to 4 bits.
  - #text(font: "Fira Code")[0x#highlight(fill: red.lighten(50%))[1]#highlight(fill: green.lighten(50%))[8]#highlight(fill: blue.lighten(50%))[4]#highlight(fill: yellow.lighten(50%))[0] = 0b#highlight(fill: red.lighten(50%))[0001]#highlight(fill: green.lighten(50%))[1000]#highlight(fill: blue.lighten(50%))[0100]#highlight(fill: yellow.lighten(50%))[0000]]
  - In assembly language: `adds r0, r0, r1`.
]

#slide[
  == Positional Number Systems
  - We represent numbers as strings of digits, where each digit is a symbol taken from some set.
  - Digits in decimal numbers come from a set with 10 elements.
  - We can also construct numbers using sets of different size.

  $
  "int"(s, b) = sum_(i=0)^"len"(s) d_i dot b^i \
    x = "int"([d_(L-1), ..., d_3,d_2,d_1,d_0])
  $

  #v(0.3cm)
  #callout_skill[Converting between different bases, e.g. binary, hexadecimal.][
    Exercise: Write a little program to print a number in an arbitrary base!
  ]
]

#slide[
  == Status Bits
  The status bits `N`, `Z`, `C`, `V` are in #psr. The instruction `adds` is does *`add`*ition, and sets the *`s`*tatus bits.
  - `N`: Set if the result is negative. #light[But how do we represent negative nums?]
  - `Z`: Set if the result is zero.
  - `C`: Look at later.
  - `V`: Look at later.
]

#slide[
  == Assembly Language
  - First level of abstraction up from binary machine code.
  - There is a simple map between assembly and machine code.
  - Basically machine code in human-readable form, with tiny bits of "syntactic sugar".
  - Program that translates from assembly to machine code: _Assembler_.
  - Given close correspondence, assemblers are simple programs, particularly when compared to compilers.
]

#slide[
  == Assembly Language has... "Quirks"
  Consider the instruction

  //#set align(center)

    #item-by-item[
    - `✅ adds r0, r1, #3`
    - `✅ adds r0, r0, #10`
    - `❌ adds r0, r1, #10`]

    #uncover("4-")[Very annoying!]
    #item-by-item(start: 5)[
    - Exam won't test whether you can memorise these rules (you can look them up)
    - But we do want to understand why this happens!
    ]
]

#slide[
  #callout_skill[Decoding machine code][
    I.e. how to take machine code, and determine what assembly instruction it maps to.
  ]
  #v(0.5cm)
  #item-by-item(start: 2)[
  #v(0.8cm)
  - As an assembly level programmer, no need to know this.
  - ... unless you want to understand _why_  assembly works the way it does
  - But as a _machine code_ programmer, you definitely do!
    - Or as a designer of the underlying logic circuits!
    - Or if you want to _write_ an assembler.
  ]
]

#slide[
  == Rainbow Chart
  In GitLab you can find `rainbow-chart.pdf`.
  - Nice summary of how binary patterns map to instructions.
  - List of all instructions used in the course.
  - Will be included in the exam, if needed.

  #set align(center)
  #image("figures/rainbow-chart.png", height: 75%)

  #text(font: "Fira Code")[0x1840 = 0b#highlight(fill: orange.lighten(80%))[0001 100] #highlight(fill: black.lighten(80%))[001] #highlight(fill: purple.lighten(80%))[000] #highlight(fill:maroon.lighten(50%))[000]]


  #text(font: "Fira Code")[#highlight(fill: orange.lighten(80%))[adds] #highlight(fill: maroon.lighten(50%))[r0], #highlight(fill: purple.lighten(80%))[r0], #highlight(fill: black.lighten(80%))[r1]]
]

#slide[
  == Conventions?
  #callout_question[Who decides these encodings?][]

  #show: later
  The instruction set designers! In this case ARM.
  - It is _chosen_ by humans (i.e. not an eternal truth)
  - But, like everything in this course, not _arbitrary_!
  - Design constraint: Encode as many useful instructions into 16 bits as possible!

  #set align(horizon)
  #light[Show how to find this in the datasheet
  - `adds` (register)
  - `adds` (immediate)]
]

#slide[
  == Consequences of Encoding
  #one-by-one[We know know _why_][
  - Only the lower 8 registers can be accessed by most instructions.
    - Allocating 3 bits to indicate the register only gives 8 options!
  - The assembler language `adds r0, r1, #10` is illegal.
    - We only have 3 bits to allocate to the constant, giving only 8 options!
  ]
]

#slide[
  == The Next Instruction
  #[Now the #pc points to 194 in memory, and contains the instruction
  #[
    #set align(center)
    #text(font: "Fira Code")[0x#highlight(fill: blue.lighten(70%))[47]70 = 0b01000111 0 #highlight(fill: red.lighten(80%))[1110] 000]
  ]

  #grid(columns: (1.1fr, 1fr),
  one-by-one[
    which decodes to:][
    #highlight(fill: blue.lighten(70%))[`bx`]. \ ][
      Looking at the instruction reference:
    #image("figures/instruction-bx.png")
    ][
      Regs encoded in following bits \
      #highlight(fill: red.lighten(80%))[`0b1110`] = 14, and #r14 is #lr, so:
      #[
        #set align(center)
        #highlight(fill: blue.lighten(70%))[`bx`] #highlight(fill: red.lighten(80%))[lr]
      ]
    ]
  , {set align(right); image("figures/rainbow-chart-B.png", width: 90%)})
]
]

#slide[
  == Datasheets: How we know how regs are encoded
  #one-by-one[
  This behaviour is not mysterious. It was _designed_ by humans. Humans want others to understand. So they write documentation / datasheets. ARM publishes all this in easy-to-search formats!

  So if you:][
  - go to README in #link("https://gitlab.cs.ox.ac.uk/marilk/digital-systems/")[gitlab.cs.ox.ac.uk/marilk/digital-systems/],
  - Find the link for "architecture reference manual" under "Resources",
  - look at the contents, and find "A5.1 Thumb instruction set encoding",][
    you will find all information that the rainbow chart was made from. \ \ ][
  Follow links further, and you will find A6.7.15 for `bx`.]
]

#slide[
  == The Effect of `bx lr`
  // Let's consider the effect of an instruction.
  // Imagine pc=192, and the instruction at that location is loaded, which we represent in hexadecimal as 0x1840.
  #image("figures/instruction-bxlr.png", width: 100%)
]

#slide[
  == Program Counter
  There are multiple encodings for ARM instructions. Big chips can choose.

  #grid(columns: (1fr, 1fr), [
    - "Native" ARM instructions (32 bits)
    - "Thumb" instructions (16 bits)
    - Thumb-2 extensions (mixture of 16- and 32 bit)
    Cortex-M0 only has Thumb instructions, but Cortex-M4 uses ThumbV2.
  ], image("figures/thumb-native.png"))
]

#slide[
  == Subroutines
  #callout_question[How can we make parts of a program reusable?][]
  #show: later
  Store a re-usable sequence of instructions, starting at a known memory location (e.g. 660). Then run program:

  #item-by-item(start: 3)[
  - Instr: Store location of next instruction in #lr.
  - Instr: Change the #pc to known subroutine location.
    - Run multiple instructions in subroutine.
    - Change the #pc back to #lr.
  - Continue program.
  ]

  #uncover("6-")[We saw how `bx lr` allows the program to continue.]
]

#slide[
  == Subroutines
  #callout_warning[Register values remain the same between subroutines!][
    - When jumping into a subroutine, the registers may be in use by the caller.
    - Subroutine needs to use registers as well! \
    \ 
    $=>$ We need conventions on how to use registers to prevent overwriting data that is in use, and how to communicate results of subroutine.
  ]

  // So calling subroutines is a bit harder, and we'll get to that.
]

#slide[
  == Lab Exercise One
  - Practice writing assembly language.
  - Your assembly language will be in a subroutine.
  - Called from a bigger C program that handles I/O.
]

#slide[
  == Conclusion
  #callout_question[How do instructions alter the CPU state?][
    - Understand the effect of instructions on the state of the CPU.
    - Worked example of executing an instruction.
  ]
  #v(-0.05cm)
  #callout_question[How are instructions encoded electronically?][
    And how does this affect programming the machine?
  ]
  #v(-0.05cm)
  #callout_skill[Decode machine code][
    I.e. how to take machine code, and determine what it will do.
  ]
  #v(-0.05cm)
  #callout_question[How can we make parts of a program reusable?][How do subroutines work?]
]

#slide[
== References / Further reading
- Image of 386 chip. https://collection.sciencemuseumgroup.org.uk/objects/co523252/intel-386-microprocessor-1985
- Image of 386 die. Ken Shirriff's Blog. _Reverse engineering the Intel 386 processor's register cell_. http://www.righto.com/2023/11/reverse-engineering-intel-386.html
]