#import "theme.typ": *
#show: doc => conf(doc)
#import "theme/truthtable.typ": truth-table, l-and, l-imp, l-iff, l-not, l-or, l-var, l-operator, l-logic-convert, l-parens-repr-if-composite, l-expr-tree

// #enable-handout-mode(false)

#title-slide(title: [Lecture 18 & 19 \ Building Logic Gates with Transistors])

#slide[
  #item-by-item[
  #[Last lecture:]
  - Building a CPU requires building binary functions
  - Building blocks for binary functions are logic gates
  #set align(center + horizon)
  #thebig_question[How can we build logic gates?]
]
]

#slide[
  #item-by-item[
  == Why binary?
  #callout_goal[Central goal: Build machines that behave like symbols][
    I.e.~independent of external influences, deterministic, and reproducible.
  ]
  - Making systems reliable is a lot easier if they only have two states.
  - It is preferrable to build something out of many two-state systems, even if you could do it with fewer multi-state / analogue systems.

  #callout_idea[We will represent *state* with *voltage* in an electrical circuit][Today, we will see that if we design circuits to ]
]
]

#slide[
  == Basic Electricity
  - Charge, current, voltage (causes charge to flow, energy per charge)
  - Ohm's law
  - Capacitors
  
  == Potential Divider
  - Voltage distributes proportional to resistance.
  - If we could control resistances, we could control "output" voltage.
  - This is what a transistor is.

  == Transistors
  - I-V characteristics of transistors (n-type + p-type)
  - Minimum $V_(D S)$, $V_(G S)$

  == CMOS Analysis
  - Analysis of given circuit: NOT gate
  - Noise gap in NOT gate. Perhaps full simulation of noise gap?
  - When does current flow? Model input of transistor with capacitor
  - Analysis of given circuit: NAND gate
  - NAND is sufficient
  - Challenge: Multi-input NAND gate
  - Analysis: Reduced noise gap

  == CMOS Design
  - NOR gate: Show bottom
  - What is problem with this circuit? Show with capacitor model: no pull-up, floating gate.
  - Example: Design pull-up circuit
  - Rules of CMOS design: Composed of pull-down and pull-up circuit, one of which is always active.
    - Top: p-type, bottom: n-type
    - Series in one $=>$ parallel in other
  - Example: NOR gate
  - Example: $not ((a and b) or c)$


  == Semiconductors
  - Pure silicon crystal (free electrons, thermal diffusion, voltage applied)
  - Doped silicon (n-type Phosphorous, p-type Boron)
  - p-n junction (diode)
  - FET
  - Flash memory
]

#slide[
  Antimonotonic nature of CMOS circuits
]


