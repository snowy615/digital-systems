#import "theme.typ": *
#show: doc => conf(doc)

#title-slide(title: [Lecture 2 \ State and Instructions])

// #enable-handout-mode(true)

#polylux-slide[
  #line-by-line[
  #callout_question[How do instructions alter the CPU state?][
    - Understand the effect of instructions on the state of the CPU.
    - Worked example of executing an instruction.
  ]
  #callout_question[How are instructions encoded electronically?][
    And how does this affect programming the machine?
  ]
  #callout_skill[Decode machine code][
    I.e. how to take machine code, and determine what it will do.
  ]
  #callout_question[How can we make parts of a program reusable?][How do subroutines work?]
]
]

#polylux-slide[
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


#polylux-slide[
  == Implementation
  #line-by-line[
  #[We will discuss electronics more later, but for now:]
  - All state is represented by an electrical voltage.
  - Voltage is either "high" or "low".
  - Represents binary encoding of numbers.
  #[We talk about "state", and "registers", and all that, but it's important to keep in mind that...
  #v(0.5cm)]
  #callout_info[What you are about to learn is _physically real_][If you could open up the chip, and attach an LED circuit to the wires, you would literally see them light up according to binary.]
]
]

#polylux-slide[
== Implementation
#grid(columns: (1fr, 1fr), [
#line-by-line[
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

#polylux-slide[
  == Registers: A Closer Look
  For most programming purposes, the state of the registers, is the state that we manipulate with instructions.
  #{
    set align(center)
    image("figures/arm-registers.png", height: 69%)
  }
]
#polylux-slide[
== Registers: Purpose
#line-by-line[
#[All Registers are 32 bits "wide"]
  - #r0 - #r7 : General purpose registers. Can be used for any value used in any calculation.
  - #r0 - #r3 : Handled differently during subroutine calls.
  - #r8 - #r12 : Can be used for any value, but the instruction set makes it hard to access them, so not as "general purpose" as #r0 - #r7.
  - #pc : Program counter. Stores memory address of next instruction.
  - #lr : Link register. Stores address where current subroutine returns.
  - #sp : Stack Pointer.
  - #psr: Processor Status Register. Different bits have very specific meanings. Some instructions write bits, some read bits.
]
]

#polylux-slide[
  == The Effect of an Instruction
  // Let's consider the effect of an instruction.
  // Imagine pc=192, and the instruction at that location is loaded, which we represent in hexadecimal as 0x1840.
  #image("figures/instruction-adds.png", width: 90%)
  - Hex is convenient: Each hex digit corresponds to 4 bits.
  - #text(font: "Fira Code")[0x#highlight(fill: red.lighten(50%))[1]#highlight(fill: green.lighten(50%))[8]#highlight(fill: blue.lighten(50%))[4]#highlight(fill: yellow.lighten(50%))[0] = 0b#highlight(fill: red.lighten(50%))[0001]#highlight(fill: green.lighten(50%))[1000]#highlight(fill: blue.lighten(50%))[0100]#highlight(fill: yellow.lighten(50%))[0000]]
  - In assembly language: `adds r0, r0, r1`.
]

#polylux-slide[
  == Status Bits
  The status bits `N`, `Z`, `C`, `V` are in #psr. The instruction `adds` is does "add"ition, and sets the "s"tatus bits.
  - `N`: Set if the result is negative.
  - `Z`: Set if the result is zero.
  - `C`: Look at later.
  - `V`: Look at later.
]

#polylux-slide[
  == Program Counter
  There are multiple encodings for ARM instructions. Big chips can choose.

  #grid(columns: (1fr, 1fr), [
    #line-by-line[
    - "Native" ARM instructions (32 bits)
    - "Thumb" instructions (16 bits)
    - Thumb-2 extensions (mixture of 16- and 32 bit)
    Cortex-M0 only has Thumb instructions, but Cortex-M4 uses ThumbV2.
  ]
  ], image("figures/thumb-native.png"))
]

#polylux-slide[
  == Assembly Language
  - First level of abstraction up from machine code.
  - Very close correspondence between assembly and machine code.
  - Basically machine code in human-readable form, with tiny bits of "syntactic sugar".
  - Program that translates from assembly to machine code: _Assembler_.
  - Given close correspondence, assemblers are simple programs, particularly when compared to compilers.
]

#polylux-slide[
  == Assembly Language has... "Quirks"
  Consider the instruction

  //#set align(center)

  #[
    #line-by-line[
    - `✅ adds r0, r1, #3`
    - `✅ adds r0, r0, #10`
    - `❌ adds r0, r1, #10` \

    Very annoying!
    - Exam won't test whether you can memorise these rules (you can look them up)
    - But we do want to understand why this happens!
    ]
  ]

  #set align(left)

]

#polylux-slide[
  #callout_skill[Decoding machine code][
    I.e. how to take machine code, and determine what assembly instruction it maps to.
  ]
  #line-by-line[
  #v(0.8cm)
  - As an assembly level programmer, no need to know this.
  - ... unless you want to understand _why_  assembly works the way it does
  - But as a _machine code_ programmer, you definitely do!
    - Or as a designer of the underlying logic circuits!
    - Or if you want to _write_ an assembler.
  ]
]

#polylux-slide[
  == Rainbow Chart
  In Moodle you can find `rainbow-chart.pdf`.
  - Nice summary of how binary patterns map to instructions.
  - List of all instructions used in the course.
  - Will be included in the exam.

  #set align(center)
  #image("figures/rainbow-chart.png", height: 75%)

  #text(font: "Fira Code")[0x1840 = 0b#highlight(fill: orange.lighten(80%))[0001 100] #highlight(fill: black.lighten(80%))[001] #highlight(fill: purple.lighten(80%))[000] #highlight(fill:maroon.lighten(50%))[000]]


  #text(font: "Fira Code")[#highlight(fill: orange.lighten(80%))[adds] #highlight(fill: maroon.lighten(50%))[r0], #highlight(fill: purple.lighten(80%))[r0], #highlight(fill: black.lighten(80%))[r1]]
]

#polylux-slide[
  #set align( horizon)
  #light[Show how to find this in the datasheet
  - `adds` (register)
  - `adds` (immediate)]
]

#polylux-slide[
  == Consequences of Encoding
  #line-by-line[
  #[We know know _why_]
  - Only the lower 8 registers can be accessed by most instructions.
    - Allocating 3 bits to indicate the register only gives 8 options!
  - The assembler language `adds r0, r1, #10` is illegal.
    - We only have 3 bits to allocate to the constant, giving only 8 options!
  ]
]

#polylux-slide[
  == The Next Instruction
  #[Now the #pc points to 194 in memory, and contains the instruction
  #[
    #set align(center)
    #text(font: "Fira Code")[0x#highlight(fill: blue.lighten(70%))[47]70 = 0b01000111 0 #highlight(fill: red.lighten(80%))[1110] 000]
  ]
  #line-by-line[
    
  #grid(columns: (1.1fr, 1fr),
  line-by-line(start: 2)[
    #[which decodes to:]
    #[#highlight(fill: blue.lighten(70%))[`bx`]. \ ]
    #[
      Looking at the instruction reference:
    #image("figures/instruction-bx.png")
    ]
    #[
      Regs encoded in following bits \
      #highlight(fill: red.lighten(80%))[`0b1110`] = 14, and #r14 is #lr, so:
      #[
        #set align(center)
        #highlight(fill: blue.lighten(70%))[`bx`] #highlight(fill: red.lighten(80%))[lr]
      ]
    ]
  ]
  , {set align(right); image("figures/rainbow-chart-B.png", width: 90%)})
  ]
]
]

#polylux-slide[
  == Datasheets: How we know how regs are encoded
  #line-by-line[
  #[This behaviour is not mysterious. It was _designed_ by humans. Humans want others to understand. So they write documentation / datasheets. ARM publishes all this in easy-to-search formats!

  So if you:]
  - go to https://spivey.oriel.ox.ac.uk/digisys/The_BBC_micro:bit,
  - click on ARM "architecture reference manual",
  - look at the contents, and find "A5.1 Thumb instruction set encoding",
  #[you will find all information that the rainbow chart was made from. \ \ ]
  #[Follow links further, and you will find A6.7.15 for `bx`.]
  ]
]

#polylux-slide[
  == The Effect of `bx lr`
  // Let's consider the effect of an instruction.
  // Imagine pc=192, and the instruction at that location is loaded, which we represent in hexadecimal as 0x1840.
  #image("figures/instruction-bxlr.png", width: 100%)
]

#polylux-slide[
  == Subroutines
  #line-by-line[
  #callout_question[How can we make parts of a program reusable?][]
  #[Store a re-usable sequence of instructions, starting at a known memory location (e.g. 660). Then run program:]
  - Instr: Store location of next instruction in #lr.
  - Instr: Change the #pc to known subroutine location.
    - Run multiple instructions in subroutine.
    - Change the #pc back to #lr.
  - Continue program.
  #[We saw how `bx lr` allows the program to continue.]
  ]
]

#polylux-slide[
  == Subroutines
  #callout_warning[Register values remain the same between subroutines!][
    - When jumping into a subroutine, the registers may be in use by the caller.
    - Subroutine needs to use registers as well! \
    \ 
    $=>$ We need conventions on how to use registers to prevent overwriting data that is in use, and how to communicate results of subroutine.
  ]

  // So calling subroutines is a bit harder, and we'll get to that.
]

#polylux-slide[
  == Lab Exercise One
  - Practice writing assembly language.
  - Your assembly language will be in a subroutine.
  - Called from a bigger C program that handles I/O.
]

#polylux-slide[
  == Conclusion
  #callout_question[How do instructions alter the CPU state?][
    - Understand the effect of instructions on the state of the CPU.
    - Worked example of executing an instruction.
  ]
  #callout_question[How are instructions encoded electronically?][
    And how does this affect programming the machine?
  ]
  #callout_skill[Decode machine code][
    I.e. how to take machine code, and determine what it will do.
  ]
  #callout_question[How can we make parts of a program reusable?][How do subroutines work?]
]

#polylux-slide[
== References / Further reading
- Image of 386 chip. https://collection.sciencemuseumgroup.org.uk/objects/co523252/intel-386-microprocessor-1985
- Image of 386 die. Ken Shirriff's Blog. _Reverse engineering the Intel 386 processor's register cell_. http://www.righto.com/2023/11/reverse-engineering-intel-386.html
]