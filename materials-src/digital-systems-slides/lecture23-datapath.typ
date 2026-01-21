#import "theme.typ": *
#show: doc => conf(doc)
#import "theme/truthtable.typ": truth-table, l-and, l-imp, l-iff, l-not, l-or, l-var, l-operator, l-logic-convert, l-parens-repr-if-composite, l-expr-tree

// #enable-handout-mode(false)

#title-slide(title: [Lecture 23 & 24 \ Designing a Datapath])

#set table(
  fill: (_, y) => if y==0 { rgb("EAF2F5") },
)

#slide[
  == Roadmap  
  #callout_goal[We want to build a CPU][]
  #item-by-item(start: 2)[
  - We needed to build a state machine
  - We know how to build binary circuits
  - We can implement state using flip-flops
  - We have built circuits that implement operations
]
#uncover(6)[#[Today: Let's actually build circuits needed for implementing instructions.]]
]

#slide[
  == Building a Datapath
  Stage-by-stage development of a single-cycle datapath able to execute many Thumb instructions.
  - Single-stage pipeline: Impractical, low clock-speed design. But simple!
  - Ignore multi-cycle instructions (`push`, `pop`, ...)
  - No interrupts.
]

#slide[
  == Datapath Roadmap
  Stage-by-stage development of a datapath design:
- Fetching and decoding
- Arithmetic between registers
- Immediate operands
- Load and store instructions
- Shifts
]


#slide[
  == Complete Datapath
  #set align(center)
#image("./figures/datapath-full.png", height: 90%)
// More is about routing of signals than actually performing operations
]

#slide[
  == Stage 1: Instruction Fetch
  #set align(center)
  #image("./figures/datapath-1.png", height: 90%)
]

#slide[
  == Stage 1: Instruction Fetch
  #set align(center)
  #image("./figures/datapath-1-annotate.png", height: 90%)
]

#slide[
  == Stage 2: ALU Operation: `adds rx, ry, rz`
  #set align(center)
  #image("./figures/datapath-2.png", height: 90%)
]

#slide[
  == Specifying Behaviour of Bundles
  - Lines represent *bundles of wires*
  - `cRegA`, `cRegB`, `cregC` are sub-bundles
  - How to figure out which?
  
  #{" "}
  #show: later
  - From the datasheet, encoding of Thumb instructions.
  #[#set align(center)
  #image("./figures/instr-encoding-adds.png", width: 70%)]
]

#slide[
  == Specifying Behaviour of Bundles
  - How to specify behaviour of `cRegWrite`?
  - How to specify behaviour of `cAluOp`?

  Consider an additional instruction:
  #[#set align(center)
  #image("./figures/instr-encoding-subs.png", width: 70%)] #show: later
  - `cAluOp` can be bit 9 (multiplexer inside ALU)
  - `cRegWrite` should just be `True` for current instruction
]

#slide[
  == A Difficult Instruction
  #[#set align(center)
  #image("./figures/instr-encoding-ands.png", width: 70%)]
  - `cRegC` can no longer be a subset of `instr` wires!
  - Decode would need to do something more complicated!
]

#slide[
  == What is broken?
  #set align(horizon)
  #thebig_warning[No condition codes!]
]

#slide[
  == Stage 2: ALU Operation: `adds rx, ry, rz` (recap)
  #set align(center)
  #image("./figures/datapath-2.png", height: 90%)
]

#slide[
  == Stage 3: Immediate Instructions
  #[#set align(center)
  #image("./figures/instr-encoding-addsimm.png", width: 70%)]
  How to feed right value into ALU? #show: later
  - Multiplexer!
]

#slide[
  == Stage 3: Immediate Instructions
  #set align(center)
  #image("./figures/datapath-3-imm.png", height: 90%)
]

#slide[
  == More Instructions
  #set align(center)
  #image("./figures/instr-encoding-ands.png", width: 70%)
  #image("./figures/instr-encoding-movs.png", width: 70%)
]


#slide[
  == Control Signal Table
  - Symbols in table are electronically implemented as binary encodings
  - Binary encodings $=>$ truth table, for implementation in circuit/ROM
  #[#set align(center)
#image("./figures/decode-table-1.png", height: 69%)]
]

#slide[
  == Types of Signals
  We introduce nomenclature for different types of signals.
  - _Decoded_ signals depend on opcode only
  - _Derived_ signals depend also on variable fields
  - _Dynamic_ signals depend on state of CPU
]

#slide[
  == What is broken?
  #set align(horizon)
  #callout_warning[List of things broken][
    #item-by-item(start: 2)[
    - No condition codes written to #psr
    - Logic for `cRegX` not specified! (Not enough to grab a bundle of wires)
    - `cAluOp`: (Not enough to grab a specific bit from the instruction)
  ]
  ]
]

#slide[
  == Stage 3: Immediate Instructions (recap)
  #set align(center)
  #image("./figures/datapath-3-imm.png", height: 90%)
]

#slide[
  == Stage 4: Data Memory
  #[#set align(center)
  #image("./figures/instr-encoding-ldr.png", width: 70%)
  #image("./figures/instr-encoding-str.png", width: 70%)]
  - `ldr` requires read of 3 registers
  - Address calculation requires ALU (i.e. place mem access after ALU)
]

#slide[
  == Stage 4: Data Memory
  #image("./figures/datapath-4.png", height: 90%)
]

#slide[
  == Stage 4: Data Memory
    #image("./figures/datapath-4-zoom.png", height: 90%)
]

#slide[
  == Control Signal Table
  #set align(center)
  #image("./figures/decode-table-2.png", width: 70%)
]

#slide[
  == Stage 5: Shifts
  #[Q: Where should we put the barrel shifter?] #show: later
  
  #[Full ARM assembly (i.e. not Thumb) allows  `ldr r0, [r1, r2, LSL #2]`.] #show: later
#[#set align(center)
#image("./figures/instr-encoding-ldrstrimm.png", width: 55%)] #show: later
`imm5` is offset in words, not bytes!
]

#slide[
== Stage 5: Shifts
#set align(center)
#image("./figures/datapath-5-shift.png", width: 94%)
]

#slide[
  == Stage 5: Shifts (Example)
  #set align(center)
#image("./figures/datapath-5-zoom.png", height: 90%)
]



#slide[
== Stage 5: Shifts (Control Signals)


#image("./figures/decode-table-3.png")
]

#slide[
  == Stage 6: #pc as a register
  #set align(center)
  #image("./figures/datapath-6.png", height: 90%)
]


#slide[
  == What is broken?
  #set align(horizon)
  #callout_warning[List of things broken][
    #[
    - Logic for `cRegX` not specified! (Not enough to grab a bundle of wires)
    - No condition codes written to #psr
    - `cAluOp`: It's getting complicated to implement this with a multiplexer
  ]
  ]
]

#slide[
  == Stage 7: Register Selection
  #set align(center)
#image("./figures/datapath-7.png", height: 90%)
]

#slide[
  == Stage 7: Register Selection
    #set align(center)
#image("./figures/decode-table-4.png", height: 90%)
]

#slide[
  == Instructions with Fixed Registers
  #set align(center)
#image("./figures/instr-encoding-fixedreg.png", height: 90%)
]

#slide[
  == Stage 7: Register Selection
#image("./figures/decode-table-5.png")
]

#slide[
  == Stage 7: Register Selection
  #set align(center)
#image("./figures/datapath-7.png", height: 90%)
]


#slide[
  == Stage 8: Subroutine Calls
  #set align(center)
#image("./figures/datapath-8.png", height: 90%)
]

#slide[
  == Stage 8: Subroutine Calls
  #set align(center)
#image("./figures/datapath-8-zoom.png", height: 90%)
]

#slide[
  == Stage 8: Subroutine Calls
  #set align(center)
#image("./figures/decode-table-6.png", height: 90%)
]

#slide[
  == Stage 8: Subroutine Calls
  #set align(center)
  #image("./figures/decode-table-7.png", height: 90%)
]

#slide[
  == What is broken?
  #set align(horizon)
  #callout_warning[List of things broken][
    #[
    - #strike[Logic for `cRegX` not specified! (Not enough to grab a bundle of wires)]
    - No condition codes written to #psr
    - #strike[`cAluOp`: It's getting complicated to implement this with a multiplexer]
  ]
  ]
]

#slide[
  == Stage 8: Subroutine Calls
  #set align(center)
#image("./figures/datapath-8.png", height: 90%)
]

#slide[
  == Stage 9: Conditional Branches
  #set align(center)
#image("./figures/datapath-9.png", height: 90%)
]

#slide[
  == Stage 9: Conditional Branches
  #set align(center)
#image("./figures/datapath-9-zoom.png", height: 90%)
]

#slide[
  == Stage 9: Conditional Branches
  #set align(center)
#image("./figures/decode-table-8.png", height: 90%)
]

#slide[
  == Behold: Complete Datapath
  #set align(center)
#image("./figures/datapath-full.png", height: 90%)
// More is about routing of signals than actually performing operations
]

#slide[
      == Conclusion
  - We have seen how to build a complete datapath
  - Reasoned through decoded signals (implement in ROM)
  - Reasoned through derived signals (decoded signals control multiplexer)
  - Understand how symbols can be implemented using binary encoding
  #[This is final lecture! Notes contain detailed derivation of decoding tables, but we discussed in lectures.]
]