#import "theme.typ": *
#show: doc => conf(doc)
#import "theme/truthtable.typ": truth-table, l-and, l-imp, l-iff, l-not, l-or, l-var, l-operator, l-logic-convert, l-parens-repr-if-composite, l-expr-tree

// #enable-handout-mode(false)

#title-slide(title: [Lecture 20 \ Sequential Logic])

#set table(
  fill: (_, y) => if y==0 { rgb("EAF2F5") },
)

#slide[
  == Roadmap
  #callout_goal[We want to build a CPU][]
  #item-by-item[
  - We needed to build a state machine
    - We needed to specify binary functions
      - We needed building blocks
        - So we learned how to make logic gates!
    - We need circuits that have state that can change with time
      - We need circuits whose state depends on *past* state
        - Sequential circuits
  ]
]

#slide[
  == Today
    #callout_question[How can we build circuits with state that changes with time?][]
  - Sequential circuits: State depends on history of their inputs.
  - Flip-flop: Building block, that outputs previous input value.
  - Any sequential circuit can be built from \ flip-flops and combinational logic.
]

#slide[
  == D-type Flip-Flop
  #grid(columns: (1.5fr, 1fr), [
    We consider *synchronous* circuits.
    - A  *clock* signal is shared between all components.
    - Circuit changes state on rising edge.
    - Signals must be stable for a given _setup time_, before next rising edge.
  ], [#image("./figures/d-type-flip-flop.png")
  #set align(center)
#table(
  columns: 3,
  [$a_t$], [$z_t$], [$z_(t+1)$],
  [0], [0], [0],
  [0], [1], [0],
  [1], [0], [1],
  [1], [1], [1]
)])
]

#slide[
  == Analysis example: Parity Detector
  #[Given: Sequence of bits $a_1, ..., a_t$. \ ]
  #[Goal: Output is 0 if even number of 1s in $a_t$, 1 if odd number of 1s in $a_t$.]
  #[
    #set align(center)
#image("./figures/parity-detector.png", width: 50%)]
$
x_t = a_t plus.circle z_t quad quad z_(t+1) = x_t quad quad z_0 = 0 \
z_t = a_0 plus.circle a_1 plus.circle dots plus.circle a_(t-1)
$
]


#slide[
  #set align(horizon)
  #thebig_question[How can we build any finite state machine \ out of \ flip-flops and combinational logic?]
]

#slide[
  == Design example: Pulse Shaper
  Actually useful, to synchronise signals from outside the circuit to clock, so it can be used reliably inside the circuit.
#[#set align(center)
  #image("./figures/pulse-shaper-timing.png", width: 83%)]
  Goal: Circuit that turns any continuous pulse, into a pulse 1 cycle long.
]

#slide[
  == Design example: Pulse Shaper
    - Do we actually need sequential logic?
    - Necessarily misses changes within a single pulse. \
    When is the output high?
    - Only when input was high at previous clock rise, but low before that.

    #[Design:]
    - Shift register (board): Gives access to values at previous times.
    - Combine with combinational logic.
]

#slide[
  == Design example: Pulse Shaper
  #image("./figures/pulse-shaper.png")
  Moore machines vs Mealy machines.
]

#slide[
  #slide[
  #set align(horizon)
  #thebig_question[How can we build any finite state machine \ out of \ flip-flops and combinational logic?]
]
]

#slide[
  == Finite State Machines
  - Use combinational logic to define $f(x_t)$.
  - Use flip-flops to map output of combinational logic, to next state $x_(t+1) = f(x_t)$.
]

#slide[
  == Maximum Clock Speed
  #grid(columns: (1fr, 1.3fr), [Must have:
$
T >= t_1 + t_2 + t_3 +t_4
$

I.e. propagation delay of flip-flop and all logic gates, \
plus \
the stabilisation time for the input to the next flip-flop.], [
#image("./figures/clock-speed.png", height: 90%)
])
]

#slide[
  == From Code to Logic Circuit
  #[Alternative way to think about solution to pulse shaper: \
  $quad$ Pseudo-code, describing how states change over time.]
  ```C
x = y = 0;       // State variables, initialised
forever {
  z = x && !y;   
  pause;
  y = x; x = a;  // Simultaneous
}
  ```
  #v(-0.4cm)
  - Simultaneous assignment
  - `pause`: Delay until next clock rising edge
#[You're well-trained in writing code. Perhaps a helpful way to think.]
]

#slide[
  == Design example: Pulse Shaper
  #[#set align(center)
    #image("./figures/pulse-shaper.png", width: 90%)]
  - Variables $=>$ *state*.
  - Simultaneous assignment $=>$ connection to *input* of flip-flop.
  - Mathematical expression $=>$ expressed as *combinational logic*.
]

#slide[
  == Design example: Bathroom Switch
  #[#set align(center)
#image("./figures/bathroom-switch-timing.png", width: 70%)]
- $a_t$: Pull-cord switch (pulled $=>$ HIGH)
- $z_t$: Light state (on $=>$ HIGH)
How many states do we need?
]

#slide[
  == Design example: Bathroom Switch
  #[#set align(center)
#image("./figures/bathroom-switch-timing.png", width: 75%)]
- The light z changes state once for each pull of the cord a.
- Notice there are four states, because $a = 1$ and $z = 1$ at both places marked, and yet the next state is different.
]

#slide[
  == Design example: Bathroom Switch
  #grid(columns: (1fr, 0.3fr, 1fr), [
    - When the cord is pulled, x remembers the state before the pull, and y is set opposite to it.
    - When the cord is released, y is continually copied to x ready for the next pull.
    - The output is y.
  ], [], [
  #only(1)[```C
x = y = 0;
forever {
  z = y;
  pause;
  if (a)
    y = !x;
  else
    x = y;
}
  ```]
  #only("2-")[
```c
forever {
  z = y;
  pause;
  x = (a ? x : y);
  y = (a ? !x : y);
}
```
]
])
#item-by-item(start: 3)[
Now we have an assignment in terms of gates that we know how to build!
]
]

#slide[
  == Design example: Bathroom Switch
  #set align(center)
  #image("./figures/bathroom-switch-logic.png", width: 55%)
]

#slide[
  == Conclusion
  - Combinational logic circuits have a state that is determined by \ the inputs at the current time.
  - Sequential circuits can have output that depends on *history*.
  - Any finite state machine can be made from flip-flops (storing state) \ and a combinational logic circuit (state transition function).
  - Design tips for sequential circuits (shift register, code to gates).
]

#slide[
  Not discussed:
  - Gated clocks
  - How to create (minimal) sequential circuits from finite state machines
]
