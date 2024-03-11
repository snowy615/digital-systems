#import "theme.typ": *
#show: doc => conf(doc)

#title-slide(title: [Lecture 3 \ Building a Program])

// #enable-handout-mode(true)


#polylux-slide[
  Last lecture:
  - We understood instructions, and how they affect CPU state.
  - We introduced assembly instructions,
  - example of tiny subroutine.

  #line-by-line[
  #callout_skill[Build and run a program on the BBC Microbit?][]
  #callout_question[How do we get our instructions into memory?][]
  #callout_warning[Memory is a bit more complicated than previously implied][]
  ]
]

#polylux-slide[
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

#polylux-slide[
  == Understanding More about the Microbit
  #set align(center)
  #image("figures/microbit-photo.png", height: 90%)
  // You can see the Nordic chip, and the other chip there.
  // The second processor
  // - does usb
  // - makes behave like a storage device
]

#polylux-slide[
  == Transferring a Program to the Microbit
  Microbit behaves like USB storage device. To upload program:
  - You drag a file, containing the program, to the storage device.
  - 2nd processor receives the file over USB
  - *Doesn't* store it! So it will disappear just after it is copied!
  - Instead, the 2nd procressor's program controls pins on the Nordic chip, and transmits the program .
  - The Nordic chip goes into a mode that allows programming the flash.
  - Nordic chip stores the program into Flash memory.

  #pause
  #callout_question[If there are multiple types of memory, how do you access it?][]
]

#polylux-slide[
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

#polylux-slide[
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

#polylux-slide[
  == Demo: Compiling, Assembling, Linking
  #image("figures/makefile.png", height: 90%)
]

#polylux-slide[
  == Demo: Compiling, Assembling, Linking
  #set align(center)
  #image("figures/compiling-overview.png", height: 90%)
]

#polylux-slide[
  == Demo: Programming, Running, Debugging
]

#polylux-slide[
  == Demo: Coding Assembly
]
