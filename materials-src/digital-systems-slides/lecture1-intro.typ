// Get Polylux from the official package repository
#import "theme.typ": *
#show: doc => conf(doc, aspect-ratio: "4-3")




#title-slide(title: [Lecture 1 \ From abstract Machines to Real Machines], aspect-ratio: "4-3")

// #enable-handout-mode(true)


/*
- First lectures in Digital Systems
- This course is about how computers work
- MS: Only such course in the degree.
- 16L this term 8L next term
- Plan: How computers work at every level of abstraction from the behaviours of individual transistors, up to processors running under an operating system.
- Starting in the middle: Machine code, interface between hardware and software
- Assume machines that obey certain rules, effect of machine instructions
- Next term, how this effect is achieved

- This lecture: One instruction in its binary form, and the rules that state about how the machine behaves determines what the instruction does.
- Machine code programmes in a symbolic form: Assembly language
- 4L Learn to express common programming ideas in machine instructions
  - While we won't do very much of it
  - Important to understand what is going on. High level language, you know how to write in machine code, and understand what compiler is doing
  - More next year, course on compilers
- Instructions doing arithmetic, branching
- Explore how to construct programmes from subroutines
- How to use memory using addressing to represent data sturctures like arrays
- Move onto programmes that interact with the outside world, serial port, several things happening at once, how does this scale? polling / checking. Two answers: hardware and software. Interrupts: hardware mechanism. Can't work if we're interrupted all the time. Wrap up interruptions into messages that are passed around in an OS

Next term, start right at the bottom
- Behaviour of transistors
- Use them to build logic gates
- Logic gates into modules like adders and registers
- Put together these modules to make a data path through which numbers, represented in binary can flow, in a way that corresponds to the machine instructions, discussed this term.
- Control unit, take machine instruction, decode what they mean, instruct the data path to do the calculation, then succeeded in reaching machine code.
- Probably diverse experience. Difficult to make every lecture interesting and comprehensible to everyone.
*/

/*
Hi, and welcome to the first Digital Systems lecture.

In this course we will consider one overarching question: How should we _actually_ build computers?

In many of your other courses, you explore how computation works by specifying and analysing manipulations of symbols. This links computation to logic and mathematics, which allows you to find eternal truths about computation.

This is not such a course. Instead, we will explore how we can take the messy and non-cooperative physics that nature has provided us with, and actually build a computing machine. In this course we will see that if we build carefully, we will end up with a machine with behaviour that we can sensibly reason about in a symbolic way.
*/

#slide[
  == Intro
  #item-by-item[
  - I'm Mark van der Wilk (#link("https://mvdw.uk")[mvdw.uk]) \ your lecturer for this course.
  - I usually work on machine learning, but I will be teaching you Digital Systems.
  - A course on building computers from the ground up.
    - We will investigate simple computer.
    - _Embedded systems_ programming. // Only place where you can find a simple computer is in an _embedded system_
  - I'm very glad I know this stuff:
    - Can build all sorts of gadgets. // Home automation: Open / close curtains based on light.
    - Understanding low-level programming has (in rare but important cases) helped me to make performant code in academic and industry projects.
    - Someone needs to actually build computers, \ and this course teaches you how.
  ]
]

#slide[
  == Plan for the Term
  #item-by-item[
  - All information on Moodle
  - Labs are a crucial part of the course
  - You will not gain everything you need from the lectures
  - Labs are designed to teach
  - You will need to pick up C programming in the labs
  - Official sessions in weeks 3, 4, 6, 7
  - It's a good idea to start sessions earlier (see Moodle)
  - Also teaches general computer literacy \ (command line tools, Linux environments)
  ]
]

#slide[
  == The Overarching Question
  #show: later
  
  #set align(center + horizon)
  #thebig_question[How should we \ _actually_\ build computers?]
]

#slide[
  == Let's start at the beginning
  #callout_info[What is a computer?][#show: later
  A device that produces \ (a representation of) the outcome of a computation, \ given a (representation of) a problem specification.]

  #show: later

  You may well ask: What is a computation?
  - For now: some procedure following "well-defined" steps \ (e.g. calculating the outcome of any algebraic expression). // And you may well as, what is "well-defined"?

  #show: later

  At least there is *one* useful part of this definition:

  #callout_idea[A Computer is a Device][This means that a computer must be built, which means it is made out matter, and is therefore governed by physics.]

  /*
  Definition of computation:
  "Effective method" => Ambiguous
  Church-Turing thesis => Definition of all computational tasks
  
  If it _can_ compute some
  */
]

#slide[
  == Mathematical Descriptions of Physics

  #item-by-item[
  #{[Physics is a mathematical description of how a description of a system (state) behaves through time. \ ]}
  #{[Example: State is the position of masses ${x_i}$. Newton's laws:
  $
    m_i (dif^2 x_i) / (dif t^2) = sum_k F_k
  $]}
  #thebig_idea[If Calculations describe Physics, \ then\  Physics can do Calculations.]
  ]
]

#slide[
== Using Shape for Computation
  Simple example (1600s - 1970s):
  #item-by-item(start: 2)[
  - Can describe physical property of length by a number.
  - Putting objects end-to-end *adds* their lengths.
  - Flip: Represent numbers by lengths $arrow.double$ can add numbers.
  - Add a logarithmic scale, and you can multiply.
  #{block[
    #set align(center)
    #grid(columns: (1fr, 1fr),
    image("figures/wiki-sliderule-demo.jpg", height: 32%),
    image("figures/wiki-sliderule-pic.jpg", height: 38%))
    See https://en.wikipedia.org/wiki/Slide_rule.]}
  ]
]


#slide[
  == Gears for Computation
  Antikythera Mechanism (somewhere 205 BC - 87 BC).
  - Discovered in ancient shipwreck off Antikythera coast in 1901.
  - Predictions of astronomical bodies, eclipses.
  - Precise workings were a mystery for >100 years.

  #{block[
    #set align(center + horizon)
    #grid(columns: (1fr, 1fr, 1fr),
      image("figures/wiki-antikythera-1.jpg", height: 40%),
      image("figures/wiki-antikythera-mech.png", height: 45%),
      image("figures/wiki-antikythera-model.jpg", height: 62%))
    ]}
]

#slide[
  == Integration with Electricity
  #item-by-item[
  #{[How hard is it to integrate a general curve? \ ]}
  #{[An electric circuit does it naturally!
  #figure[
  #image("figures/opamp-integrator.png", height: 50%)
  ]
  $
  V_o (t) = - 1/(R_1 C_F) integral_0^t V_"in" (tau) dif tau
  $]}
  ]
]



#slide[
  #grid(columns: (1fr, 1fr), [
  == Positions, not Lengths
  Blaise Pascal's calculator (1642)
  - Discrete rotational positions.
  - Represents decimals on multiple drums.
  - Adds a carry function.
  ], [
    #set align(right)
    #image("figures/wiki-pascaline-pic.jpg", width: 85%)
  ])
  
  #block[
  #set align(center)
  #grid(columns: (1fr, 1fr),
    image("figures/wiki-pascaline-gears.jpg", height: 53%),
    image("figures/wiki-pascaline-gears-detail.jpg", height: 53%))
  ]
]

#slide[
  == Babbage's Analytical Engine
  - Design only (1837), wasn't built.
  - Some parts displayed in London Science Museum (worth a trip).
  - First _programmable_ device (Ada Lovelace). \ I.e. could be reconfigured to do different calculations.

  #set align(center)
  #image("figures/wiki-babbage-analytical.jpg", height: 62%)
]

#slide[
  == General-Purpose Computers
  #item-by-item[
  #{[From these examples, we have seen:]}
  - Several examples of _physical_ systems that can perform computations.
  - Examples of _analogue_ computers.
  - Examples of _digital_ computers.
  - Example of an early programmable computer.
  #callout_question[How should we build computers?][
    - We now know that physics allows us to build _some_ machines that compute _some_ things.
    - Would it not be better to only have one machine, that can be configured to compute anything?
  ]
  ]
]

#slide[
  == General-Purpose Computers
  #thebig_question[How can we build one machine \ that can be configured \ to perform _any_ computation?]
]

#slide[
  == Turing Machines
  #item-by-item[
  #{[We haven't defined what a computation is yet.]} #{[Alan Turing did...]}
  - Describe a _Turing Machine_ (state machine w/ $infinity$-"tape" memory)
    #image("figures/wiki-turing-machine.jpeg", width: 60%)
  - The choice of state transitions is the program.
  - Argue that a well-defined computation _is_ \
    whatever can be encoded into a set of state transitions.
  ]
]

#slide[
  == Church-Turing Thesis
  #item-by-item[
  #callout_info[Church-Turing Thesis][
    There exists a well-defined method for computing something \
    if and only if \
    there exists a Turing Machine that produces the result.
  ]
  #callout_caution[Hold on... is this not circular?]["A computation is what a computer does"? \
  and \
  "A computer is what does computations"?]
  - The Church-Turing thesis simultaneously _defines_ a computer and a computation.
  - Justification for CT-thesis: "It's a good definition, because no way of defining a larger set of computations."
  ]
  /*
  - Turing argued that all unambiguous instructions could ultimately be reduced to something that a Turing machine could do.
  - Gödel, Church, Turing all found different ways of specifying all possible computations, and they ended up being the same.
  - If you change something about a Turing machine, you either make it substantially less powerful, or more powerful to the point of absurdity.
  */
]

#slide[
  == Interesting questions we won't answer
  #callout_question[Why are there no computations that a Turing Machine cannot do?][]
  #v(0.4cm)
  #callout_question[Are there computers that can compute things fundamentally _faster_ than a Turing Machine?][
    - What does it mean for a type of computer to be "fundamentally faster"?
    - E.g. is there an analogue computer that is fundamentally faster than a Turing machine at certain computations?
    - Quantum computers *are* faster at certain things!
  ]
  #v(0.4cm)
  #callout_question[Physical Church-Turing thesis][
    - Can the outcome of any physical process be calculated by a Turing machine (up to some precision?)
  ]
]

#show "LOOKUP": text(`lookup_table`)
#show "TAPE": text[`tape`]
#slide[
  == A Closer Look at a Turing Machine
    #grid(columns: (1.1fr, 1fr), [
  - "CPU" has a "state" at each time
  - "CPU" sits at location on tape
  - "CPU" can write a symbol in that location
  - "CPU" moves 1 step on tape
  - Look up table determines movement, and next state
  ], [
    #set align(right)
    #image("figures/wiki-turing-machine.jpeg", width: 95%)
  ])

  $
  "TAPE"(L_t) &= "LOOKUP"_1(S_t, "TAPE"(L_t)) \
  S_(t+1) &= "LOOKUP"_2(S_t, "TAPE"(L_t)) \
  L_(t+1) &= "LOOKUP"_3(S_t, "TAPE"(L_t))
  $
  - State and lookup tables can be implemented mechanically.  // This was known before Turing (e.g. Babbage)
  - Programming is a pain, you need to  select these lookup tables.
]

#slide[
  #thebig_question[How can we build one machine \ that can be configured \ to perform _any_ computation?]
  
  #thebig_idea[
    The definition of _any_ computation \ is basically given by \ the capabilities of a buildable machine \
    ... so let's build that.
  ]
]

#slide[
  == Practical Computers
  - Turing Machine technically can do anything.
  - But is it the most _practical_?

  #item-by-item[
  #callout_question[How to build a machine to perform any computation?][
    But we also want it to:
    - perform computations _quickly_ (constants matter!)
    - be programmable by humans
  ]
  - This is where we depart from mathematical eternal truths, \ and enter the world of design and engineering.
  - Things can get messy, but *usually there is a good reason* for doing things a particular way.
  //- Goal: To build an in-depth understanding of how to build a computer, from the transistor up.
]
]

#slide[
  == _Our_ Practical Computer
#image("figures/microbit-photo.png")
]

#slide[
  == RISC + The von Neumann Architecture
  #grid(columns: (1fr, 1fr),
  [
    //- Turing machines: not practical // Designed for conceptual/mathematical simplicity, not for practical considerations like speed, energy efficiency, programmability...
    Many other architectures can be proven to be equally powerful to Turing machine \ (if given infinite memory)
    
    We will consider ARM.

    - State machine: CPU
    - State stored in "registers"
    - Replace tape with addressable memory // Each location on memory has an "address", and by specifying the address you can get its contents in constant time.
    - Conceptual separation between instructions and data // Although this only matters for how the state of the CPU evolves. Instructions can be manipulated as data.
  ],
  {set align(right); image("figures/risc-vnm.png", width: 95%)})
]


#slide[
  == Operation
  #grid(columns: (1fr, 1fr),
  [
    + Controller fetches an instruction from memory, at location in Program Counter (#pc)
    + Decode instruction \ RISC, so instructions are:
      - Load / Store \ (register $arrow.l.r$ memory)
      - Arithmetic / Logic \ (register $arrow.l.r$ register)
    + Execute instruction
    + Increment #pc by 1, and repeat
  ],
  {set align(right); image("figures/risc-vnm.png", width: 95%)})
]

#slide[
  == Course Outline
  #set align(center + horizon)
  #image("figures/course-outline.png", width: 80%)

  // Now throughout this course, we will show how to build such a computer, all the way from the transistors upwards
]

#slide[
  == Interesting Stuff (totally non-examined)
  Veritasium on analogue computers:
  - #link("https://www.youtube.com/watch?v=IgF3OX8nT0w")[The Most Powerful Computers You've Never Heard Of (YouTube)]
  - #link("https://www.youtube.com/watch?v=GVsUOuSjvcg")[Future Computers Will Be Radically Different (YouTube)]

  More than you could ever want to know about the Antikythera mechanism:
  - #link("https://www.youtube.com/watch?v=xWVA6TeUKYU")[Talk on the decipherment of the Antikythera mechanism]

  
  Todo: Attribution of images (from Wikipedia)
]






/**/



