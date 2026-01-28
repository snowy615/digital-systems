#import "theme.typ": *
#show: doc => conf(doc)

#title-slide(title: [Lecture 3 \ Building a Program])

// #enable-handout-mode(true)

/*
Notes for next year:
- Review questions 3 and 4 in the new problem sheet. This is the context that the lecture is given in.
*/

#slide[
  == Labs
  - If in doubt, start early! The labs are free every week in the allocated time (and also in many times outside this). Use them.
  - See the README for lab policies.
    - E.g. you _must_ sign off your labs by the end of sign-off sessions, or get marks deducted.
]


#slide[
  Last lecture:
  - We understood instructions, and how they affect CPU state.
  - We introduced assembly instructions,
  - example of tiny subroutine.

  #one-by-one(start: 2)[
  #callout_skill[Build and run a program on the BBC Microbit?][]][
  #callout_question[How do we get our instructions into memory?][]][
  #callout_warning[Memory is a bit more complicated than previously implied][]
  ]
]

#slide[
  == Understanding More about the Microbit
  #set align(center)
  #image("figures/microbit-overview.png", height: 90%)
  // So to understand the process by which we transfer programs into the ARM chip's memory
  // we need to understand a bit about the BBC Microbit
  // In order to get a working computer, you need a bit more than just a CPU
  // The Microbit provides the bare minimum, of everything you need
  // Of course, it includes the ARM CPU, which has regs, datapath, ...
  // But the ARM CPU is inside a chip made by a different company, Nordic Semiconductor
  // They include RAM, used for data, ROM, used to store the program
  // But also "peripherals", that allow the chip to communicate with the outside world
  // Finally, this chip is included on the circuit board: the bbc microbit.
  // This includes other peripherlas external to the CPU, like LEDS, buttons, accelerometer mangetometer
  // And also a second processor, that controls the USB
]

#slide[
  == Understanding More about the Microbit
  #set align(center)
  #image("figures/microbit-photo.png", height: 90%)
  // You can see the Nordic chip, and the other chip there.
  // The second processor
  // - does usb
  // - makes behave like a storage device
]

#slide[
  == Transferring a Program to the Microbit
  Microbit behaves like USB storage device. To upload program:
  - You drag a file, containing the program, to the storage device.
  - 2nd processor receives the file over USB
  - *Doesn't* store it! So it will disappear just after it is copied!
  - Instead, the 2nd procressor's program controls pins on the Nordic chip, and transmits the program.
  - The Nordic chip goes into a mode that allows programming the flash.
  - Nordic chip stores the program into Flash memory. #light[(Demo lab2)]

  #show: later
  #callout_question[If there are multiple types of memory, how do you access it?][]
]

#slide[
  == Memory Layout
  #grid(columns: (1fr, 1fr), [
  Memory is mapped into a single _address space_.
  - All memory locations have a 32-bit address
  - Different types of memory are just given addresses
  - Even peripherals are given memory locations! (UART / GPIO) // Careful how to access these
  ], [
    #set align(right + horizon)
    #image("figures/microbit-memory-layout.png", width: 95%)
  ])
  - Single address space makes it easy to access all these: can broadly use the same instructions.
  // Reprogramming ROM can even be done by processor itself, but this requires a different access than just a store, and we won't do this.
]

#slide[
  == Demo: Building and Running Program
  #set align(center)
  #image("figures/assembly-listing.png", height: 90%)

  // Want to write and load an assembly program
  // Our starting point is the two instructions that we discussed at the end of last lecture, which is also the starting point of the lab.
  // The subroutine that ran an addition and then returned back to the caller.
  // Most of the code here is actually comments, any line starting with @
  // All assembly programs will start with the same three lines of boilerplate code, don't want to spend too much time on this.
  // The important thing is that when the subroutine is invoked, the execution starts at upper ----
  // The two inputs to this subroutine are in r0, r1
  // The subroutine then runs code, and some agreements are made to how the registers are used. r0-r3 can be used at will, while the other registers need to be left to have the same value once the subroutine finishes.
  // Finally, the return value must be left in r0.

  // Remember what bx lr does.

  // This leaves a problem for if we wanted to call another subroutine!
  // But this is a problem for later.
  // What is clear though, is that if we have a subroutine that doesn't call another one, we don't need to do a lot of work, which is nice and efficient.
]

#slide[
  == Running Our Subroutine
  We need:
  - to get our subroutine in the correct location in Memory
  - our subroutine to be called (by another program?)
  - to be able to observe the results

  #light[Show source files of `lab1-asm`, demo lab 1 with `minicom`.]

  #show: later

  #callout_idea[The _only_ thing we can do to program this chip, \
  is place instructions in memory.][] #show: later
  So we will need _tools_ that convert source files (C and asm)... \ 
  to a list of instructions to be placed at specific _addresses_.
]

#slide[
== Compilation from the Command Line
#item-by-item[
  - `make all` produces `func.hex`, which you can copy to Microbit.
  - Look at commands it runs. Notice `arm-none-eabi-as`! *Assembler*!
  - `more func.o`: Interpret binary _as_ ASCII-encoded text.
  - `hexdump func.o`: Print the binary nicely as numbers.
  - We notice the machine code we expect! `1840` and `4770`! (Plus metadata)
  - `arm-none-eabi-objdump -d func.o`
  - Compiling and linking.
  - `arm-none-eabi-objdump -d func.elf` #light[(Difference with before?)]
  - `more func.hex` #light[(little-endian)]
]
]

#slide[
  == Big vs Little Endian
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



#slide[
  == Demo: Compiling, Assembling, Linking
  #image("figures/makefile.png", height: 90%)
]

#slide[
  == Compiling & Linking
  - Compilation: From C code to _almost_ machine code.
    - Assembly instructions are decided.
    - But, each `.c` file gets its own `.o` file.
    - $=>$ cannot know the absolute addresses of functions from other files!
    - Functions can call functions from other files!
  - Linking:
    - Fully-functioning program needs to be one long sequence of instructions.
    - Linking arranges subroutines in one long sequence, and assigns absolute addresses.
    - Memory map is specified in _linker script_ (`nRF51822.ld`)
]

#slide[
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

#slide[
  == Demo: Compiling, Assembling, Linking
  #set align(center)
  #image("figures/compiling-overview.png", height: 90%)
]

#slide[
  == CPU Startup Sequence
  - In address space, CPU looks at the first 2 32-bit numbers:
    - Number `0`: Value loaded into `sp` register (stack, later lectures)
    - Number `1`: Value loaded into `pc` register $->$ Jump
  - See `startup.c`:
    - Defines array `__vectors`, which gets placed at address `0`, as determined by the linker script `nRF51822.ld`
    - `__vectors[0]`: `__stack` variable (defined in linker script).
    - `__vectors[0]`: Function `__reset()` is the first to be executed.
]

#slide[
  == Recap
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


