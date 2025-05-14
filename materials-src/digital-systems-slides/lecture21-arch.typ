#import "theme.typ": *
#show: doc => conf(doc)
#import "theme/truthtable.typ": truth-table, l-and, l-imp, l-iff, l-not, l-or, l-var, l-operator, l-logic-convert, l-parens-repr-if-composite, l-expr-tree

// #enable-handout-mode(false)

#title-slide(title: [Lecture 21 \ Architectural Elements])

#set table(
  fill: (_, y) => if y==0 { rgb("EAF2F5") },
)

#slide[
  == Roadmap
  #callout_goal[We want to build a CPU][]
  - We needed to build a state machine
    - We know how to build binary circuits
    - We can implement state using flip-flopsm

  Today: Let's actually build circuits needed for implementing instructions.
]


#slide[
  #set align(horizon)
  #thebig_idea[Abstraction \ Put blocks around complicated things, \ and describe only the inputs/outputs.]
]

#slide[
  #set align(center + horizon)
  == Adders
]



#slide[
  == Half Adder
  #[
  #set align(center)
  #image("./figures/half-adder.png", width: 96%)
]
]

#slide[
  == Full Adder
  #set align(center)
  #image("./figures/full-adder.png", height: 90%)
]

#slide[
  == Ripple Carry Adder
  #grid(columns: (3.5fr, 1fr), [
    - Can add multi-bit numbers with full adders in series
    - How long is the propagation delay?
    - Carry lookahead adder with size $O(N)$ and \ depth $O(log N)$.
    #light[
      - Diagram: box around adder, multiple inputs
    ]
  ], [
  #image("./figures/ripple-carry-adder.png", height: 90%)
])
]


#slide[
  #set align(center + horizon)
  == Multiplexers
]

#slide[
  == 1-bit Multiplexer
  #[#set align(center)
  #image("./figures/multiplexer.png", height: 78%)]
  What if you want to select between multiple input signals? (one-hot soln)
]

#slide[
  == Decoder
  #grid(columns: (1.4fr, 1fr), [
We want:
- Take binary encoding in $n$ bits.
- Turn into "one-hot" encoding, \ with $2^n$ outputs.

], [
    #only("2-")[
#image("./figures/decoder.png", height: 90%)]
])
]

#slide[
  == n-way Multiplexer
  #set align(center)
  #image("./figures/n-multiplexer.png", height: 90%)
]

#slide[
  == Example: Multiplexing Groups of Signals
  #light[
  Board:
  - 1-bit controls many
  - many controls many
  - addition vs subtraction
]
]

#slide[
  #set align(center + horizon)
  == ROMs & Programmable Logic
]

#slide[
  == Read-Only Memory (ROM)
  #set align(center)
  #image("./figures/rom.png", height: 90%)
]

#slide[
  == Read-Only Memory (ROM)
  #set align(center)
#image("./figures/rom8x8.png", height: 90%)
]

#slide[
  == Read-Only Memory (ROM)
  - Technically, any circuit can be replaced by ROM!
  - Programmable ROM (PROM) chips are available
]

#slide[
  #[#set align(center + horizon)
  == Registers]
  #light[
  - From flip-flops to registers
]
]

#slide[
  == Registers
  #grid(columns: (1fr, 1fr), [
    We consider a "write-enable" feature.
```c
forever {
  dout = state;
  pause;
  if (we)
    state = din;
}
```
  ], [
  #image("./figures/register-clock-gated.png", height: 90%)
])
]

#slide[
  == Registers (Fully Synchronous)
    #grid(columns: (1fr, 1fr), [
    We consider a "write-enable" feature.

  ], [
    ```c
forever {
  dout = state;
  pause;
  state = (we ? din : state);
}
```
])
#set align(center)
  #image("./figures/register-fully-sync.png", height: 49%)
]

#slide[
  == Register Files
  #set align(center)
    #image("./figures/register-file.png", height: 90%)
]

#slide[
  == Register Files with Special Registers
#grid(columns: (1fr, 1.5fr), [
  #item-by-item[
  #[Special registers:]
  - #[#pc: Always write something.]
  - #[#lr: Sometimes write `nextpc`].
  - #[#pc: Read +4 higher than value.]

  Three read outputs. Why? \
  #[$=>$ `str` addressing]
]
], [
  #only("5-")[
  #set align(horizon)
    #image("./figures/register-file-special.png", width: 100%)
  ]])
]

#slide[
  #set align(center + horizon)
  == Arithmetic Logic Unit (ALU)
]

#slide[
   == ALU
   #grid(columns: (1fr, 0.05fr, 1fr), [
     Inputs:
     - 2x 32 bundles of wires \ (two operands)
     - Control signals.

    Outputs:
    - Numerical calculation, determined by control signals, of the two operands
    - Status bits
], [], [
  #[#set align(center)
   #cetz.canvas({
    // set text(size: 12pt)
    import cetz.draw: *
    let top_w = 2
    let bot_w = 4
    let vert = 1.4

    fill(blue.lighten(70%))
    stroke(black)
    line((-bot_w, -vert), (-top_w, vert), (top_w, vert), (bot_w, -vert),
    (0.2, -vert), (0.0, -vert * 0.7), (-0.2, -vert), close: true)

stroke(black)
fill(none)
set-style(mark: (end: ">"))
line((0.0, vert), (0.0, 2.5 * vert), name: "result")
content(("result.start", 0.0, "result.start"), [Y], padding: 0.35, anchor: "north")
line((0.5 * bot_w, -vert * 2.5), (0.5 * bot_w, -vert), name: "B")
content(("B.end", 0.0, "B.end"), [B], padding: 0.35, anchor: "south")
line((-0.5 * bot_w, -vert * 2.5), (-0.5 * bot_w, -vert), name: "A")
content(("A.end", 0.0, "A.end"), [A], padding: 0.35, anchor: "south")
// line((-bot_w * 1.25, -vert * 0.33), (0.0, -vert * 0.33), name: "A")
//line(..c)
})]
#light[
  - Status-in?
  - Opcode?
  - Status-out?
]
])
]

#slide[
  == Simple ALU
  #grid(columns: (1fr, 1.5fr), [
    Haven't mentioned how multiplication or "^" circuit works!

    Energy efficiency?
  ], [
  #image("./figures/alu.png", width: 100%)
])
]

#slide[
  == Barrel Shifter
  #set align(center)
  #image("./figures/barrel.png", height: 90%)
]

#slide[
  == Conclusion
  - Various useful circuits
]

#slide[
  == Not Discussed
  - EPROM vs EEPROM vs Flash memory
]
