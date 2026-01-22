#import "theme.typ": *
#show: doc => conf(doc)
#import "theme/truthtable.typ": truth-table, l-and, l-imp, l-iff, l-not, l-or, l-var, l-operator, l-logic-convert, l-parens-repr-if-composite, l-expr-tree

// #enable-handout-mode(false)
#title-slide(title: [Lecture 17 \ Combinational Logic])

#slide[
  #set align(center + horizon)
  #thebig_question[How can we build a machine \ that executes instructions?]
    /*
  Hi everyone...
  - Last term we used a machine, the CPU, that could execute various instructions.
  - By feeding carefully crafted instructions, we could get the machine to interact with the environment in desired ways.
  - This term, we look into how to build such a machine
  */
]

#slide[
  == Course Outline
  #set align(center + horizon)
  #image("figures/course-outline.png", width: 76%)
  /*
  We will see how this is done from the behaviour of a transistor up...
  */
]

#slide[
  #callout_question[What does it mean to execute an instruction?][]
  Like a Turing Machine, a CPU is a finite state machine:
  $
  s_(t+1) = T(s_t, "mem"[s_t])
  $
  - State (e.g. in registers) is stored as bit-vectors / bit-strings
  - Transition function $T$ therefore maps from bit-vectors to bit-vectors
  
]

#slide[
  #set align(horizon)
  #thebig_goal[We need to specify functions on bit-vectors]
  #v(0.4cm)

  #show: later
  - We need a mathematical way to specify functions on bit-vectors \ (Boolean algebra: conjuction $and$, disjunction $or$, negation $not$.)
  - We need a way to _physically_ implement such functions: Logic gates.
]

#set table(
  fill: (_, y) => if y==0 { rgb("EAF2F5") },
)

#slide[
  == Logic Gates
  - Physical devices for implementing basic functions on bits-strings
  - Building blocks for more complicated functions
  - Can enumerate all behaviours in *truth table*

#grid(columns: (1fr, 1fr), [
#let expression = l-and("A", "B")
#align(center, truth-table(expression, repr_true: 1, repr_false: 0))
], [#set align(center)
#image("./figures/and-gate.png", width: 40%)])
]



#slide[
  == Connecting Gates
  We can compose more complicated functions by composing gates as building blocks.

  #grid(columns: (1fr, 1fr), [
  #let expression = l-and(l-and("A", "B", skip: true), l-and("C", "D", skip: true))
  #box(height: 7.5cm, clip: true, inset: 1.0pt, [
#align(center, truth-table(expression, repr_true: 1, repr_false: 0))
])
], [
  #image("./figures/multi-and-tree.png")
])

]


#slide[
  == Connecting Gates: Multiple Solutions
  We can compose more complicated functions by composing gates as building blocks.

  #grid(columns: (1fr, 1fr), [
  #let expression = l-and("D", l-and("C", l-and("B", "A", skip: true), skip: true))
  #box(height: 6.6cm, clip: true, inset: 1.0pt, [
#align(center, truth-table(expression, repr_true: 1, repr_false: 0))
])
], [
  #image("./figures/multi-and-line.png")
])
#show: later
#callout_question[Do we prefer one over the other?][]
]


#slide[
== Propagation Delay
- As we will see later, gates are implemented as *electical circuits*.
- Takes *time* for signals to settle
#[#set align(center)
#grid(columns: (1.41fr, 1fr), image("./figures/multi-and-line.png", width: 95%), image("./figures/multi-and-tree.png", width: 95%))]
#show: later
#callout_question[How many gates are required?][]
]



#slide[
  == Logic Gates
#image("./figures/logic-gates.png")
]

#slide[
  == Logic Gates & Electrical Amplifiers
]

#slide[
== Connecting Gates
Each acyclic arrangement computes a Boolean function that we can also express as an algebraic formula.
$
not ((a and b) or c)
$
#set align(center)
#image("./figures/gate-sequence.png", width: 94%)

]

#slide[
  == Finding Truth Tables
Can find the truth table for any expression / sequence of gates, by evaluating all inputs, and propagating.
  
  #set align(center)
  #let expression = l-not(l-or(l-and("a", "b"), "c"))
  #truth-table(expression, repr_true: 1, repr_false: 0)
]

#slide[
  #set align(center+horizon)
  #item-by-item[
  #thebig_question[How can we _design_ a circuit to have \ a given truth table?]
  #thebig_question[
    _Is_ there even an arrangement of gates \ that produces any given truth table?
  ]
]
]

#slide[
  == Constructing a Circuit from a Truth Table
  #let my-majority-vote(a, b, c, skip: false) = {
    // convert bools and strings
    // to l-bool and l-var objects
    let a = l-logic-convert(a)
    let b = l-logic-convert(b)
    let c = l-logic-convert(c)

    // automatically place parentheses around a and/or b
    // if they are composite expressions with 2+ children
    let a_repr = l-parens-repr-if-composite(a)
    let b_repr = l-parens-repr-if-composite(b)
    let c_repr = l-parens-repr-if-composite(c)

    l-operator(
        "MY_XOR",
        a, b, c,
        value: mapping => {
            let a_val = (a.value)(mapping)  // consider the given map of (VARIABLE: bool)
            let b_val = (b.value)(mapping)
            let c_val = (c.value)(mapping)

            (a_val and b_val) or (a_val and c_val) or (b_val and c_val)
        },
        repr: "MAJ",
        skip: skip
    )
}

#grid(columns: (2.9fr, 1fr), [
  Recipe:
  - For each "1" in output, construct an expression that is "1" only for the corresponding inputs.
  $
  a &and& b &and& c \
  not a &and& b &and& c \
  a &and& not b &and& c \
  a &and& b &and& not c
  $
  - Then take disjunction of all terms
  $
  (a and b and c) or (not a and b and c) or &
  (a and not b and c) or (a and b and not c)
  $
], [
#let expression = my-majority-vote("a", "b", "c")
#align(center, truth-table(expression, repr_true: 1, repr_false: 0))
])
]

#slide[
  #callout_idea[
   {AND, OR, NOT} are _sufficient_][Any Boolean function can be represented by a circuit of AND, OR, and NOT gates.]
  // - Recipe above is not a formal proof. But you may be able to formalise it yourself after Intro to Proof Systems!
  #show: later
  #v(0.2cm)
  #callout_warning[But our recipe is not optimal!][
    Recipe does not lead to smallest circuit. Can find smaller expression:
  $
  (a and b) or (a and c) or (b and c)
  $]
  #show: later
  #v(0.5cm)
  #item-by-item(start: 3)[
  - Algorithms for finding minimal "sum of products", e.g. Karnaugh maps.
  - We will just stare hard at expressions.
  ]
]

#slide[
  == Multiplexer
  #grid(columns: (1fr, 1fr), [
    $
    z = (c space ? space b : a)
    $
    If $c = 1$, output $b$, else $a$.

    #let my-multiplexer(a, b, c, skip: false) = {
    // convert bools and strings
    // to l-bool and l-var objects
    let a = l-logic-convert(a)
    let b = l-logic-convert(b)
    let c = l-logic-convert(c)

    // automatically place parentheses around a and/or b
    // if they are composite expressions with 2+ children
    let a_repr = l-parens-repr-if-composite(a)
    let b_repr = l-parens-repr-if-composite(b)
    let c_repr = l-parens-repr-if-composite(c)

    l-operator(
        "MY_MULTIPLEXER",
        a, b, c,
        value: mapping => {
            let a_val = (a.value)(mapping)  // consider the given map of (VARIABLE: bool)
            let b_val = (b.value)(mapping)
            let c_val = (c.value)(mapping)

            (b_val and c_val) or (a_val and not c_val)
        },
        repr: "mult",
        skip: skip
    )
}
#let expression = my-multiplexer("a", "b", "c")
#align(center, truth-table(expression, repr_true: 1, repr_false: 0))
    
  ], [#uncover(2)[#image("./figures/multiplexer.png")]])
]

#slide[
  == XOR gate
  #grid(columns: (1fr, 1fr), [
    Should be 1 if one input is 1, and the other is zero.

    #let my-xor(a, b, skip: false) = {
    // convert bools and strings
    // to l-bool and l-var objects
    let a = l-logic-convert(a)
    let b = l-logic-convert(b)

    // automatically place parentheses around a and/or b
    // if they are composite expressions with 2+ children
    let a_repr = l-parens-repr-if-composite(a)
    let b_repr = l-parens-repr-if-composite(b)

    l-operator(
        "MY_MULTIPLEXER",
        a, b,
        value: mapping => {
            let a_val = (a.value)(mapping)  // consider the given map of (VARIABLE: bool)
            let b_val = (b.value)(mapping)

            ((a_val or b_val) and not (a_val and b_val))
        },
        repr: "xor",
        skip: skip
    )
}
#let expression = my-xor("a", "b")
#align(center, truth-table(expression, repr_true: 1, repr_false: 0))
    
  ], [#uncover(2)[#image("./figures/xor.png")]])

]












/*#slide[
  Building up to assembly programming. Model of transistors crude. Analogue...

  High level overview. Transistors, logic gates, modules (summation), "general purpose computing engine", most of complexity comes from adaptive ways of routing signals through datapath. The routings are controlled by a separate piece of circuitry, decoding instructions, setting switches so each instruction does the right thing. So we end up with an electronic circuit that is capable of executing the very same machine code instructions that we saw last term. (What does it mean to execute instruction?) One way of doing things, often more economically.

  Logic gates (combinational logic), sequential logic (memory), how to build logic gates from transistors

  Example: 4 input AND gate
  Alternative solution to lead to signal propagation

  Stability of signals after a change

  Size vs propagation delay

  Algorithms expressed as gates

  Other examples (see slides)

  Circle means inversion

  Amplifiers, so you can connect one output to many inputs (fan-out)

  This removes "slop" that makes these systems reliable.

  Science museum in London, Babbage, Blade to prevent misalignment from accumulating

  Making reliable systems with more than two states is difficult. So much more difficult, that it is preferrable to build something out of many two-state sytems

  From analysis of gates, to find boolean circuit 

  Q: Can I build a boolean circuit to get a particular table?

  A: If AND, OR, NOT, then yes. Formal proof on Spivey's website.

  Example of Carry computation.

  Recipe is not the best

  Multiplexer
]*/
