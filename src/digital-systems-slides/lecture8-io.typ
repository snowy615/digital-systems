#import "theme.typ": *
#show: doc => conf(doc)

// #enable-handout-mode(true)


#title-slide(title: [Lecture 8 \ Introducing I/O])



#polylux-slide[
  == Question from Last Lecture
  Other load/store instructions...
  
  `ldr` and `str` deal in 32-bit values, the size of a register. But there are also
- `ldrb` and `strb` for 8-bit values (useful for strings).
- `ldrh` and `strh` for 16-bit values.
- `ldrsb` and `ldrsh` to load 8- or 16-bit values with sign extension. #light("Why is this necessary?")
]

#polylux-slide[
  == Aside: Buffer Overrun Attacks
  #line-by-line[
  - See notes. Not examinable this year (sadly!).
  - Shows how, in many programs that communicate with the outside world, to make it execute arbitrary code.
  - Key principle behind lots of exploits \ that allow hacking into computer systems.
  - Highly recommend looking at it, at some point \ (... perhaps after term or in summer)
]
]

#title-slide(title: [Lecture 8 \ Introducing I/O])


#polylux-slide[
  == Today
  #line-by-line[
  #callout_question[How can we control LEDs on the BBC micro:bit?][]
  #[But before we can answer this, we need to know a bit about how LEDs work, _electronically_.]
]
]

#polylux-slide[
  == Electronics of LEDs
  #light[Discuss on board: I-V char of LEDs]
  - Design: $R = 222 ohm, I approx 4.5"mA"$.
  - General Purpose In/Out (GPIO) pins on chip act as voltage source.
  #set align(center)
#image("./figures/led-basics.png", height: 52%)
]

#polylux-slide[
  #set align(horizon)
  #callout_warning[Limited GPIO pins on chip][
    We could connect one LED per GPIO pin... \ but nRF51822 only has 31 GPIO pins!
  ]
]

#polylux-slide[
  == LED Multiplexing
  #grid(columns: (1fr, 1fr), [
    - A, B connected to anode \ (+ side of LED)
    - X, Y, Z connected to cathode \ (- side of LED)
    - Setting cathode-controlling GPIO to high, switches off all LEDs connected to it.
    - LEDs no longer _independently_ controllable.
    - Can still make arbitrary patterns by switching on/off quickly.
  ], [
#image("./figures/led-multiplexing.png", height: 90%)
])
]

#polylux-slide[
  == LED Multiplexing on the BBC
  #grid(columns: (1.7fr, 1fr), [
    - BBC micro:bit has 25 multiplexed LEDs, \ in 5 physical rows and columns.
    - _Electronically_ arranged in 3 groups of 9.
    - Can display patters by controlling each group in sequence:
      - Row 1: 5, 6, 7, 9
      - Row 2: 1, 2, 3, 4, 5
      - Row 3: 1, 4, 5, 6, 7, 8, 9
      #v(-0.7cm)
      #image("./figures/bbc-heart.png", height: 23%)
  ], [
  #image("./figures/bbc-led-schematic.png", height: 90%)
])
]

#polylux-slide[
  == Questions
  #line-by-line[
  #[Consider \ $A$ GPIO ports connected to LED anodes, and \ $C$ GPIO ports connected  to LED cathodes.]
  #callout_question[How many LEDs can you control in total?][]
  #callout_question[How many LEDs can be _independently_ controlled?][]
]
]


#polylux-slide[
  == Controlling GPIO outputs
  - GPIO controls voltage.
  - Peripherals are _memory mapped_, \
    i.e. controlled by writing to a memory location.


```
GPIO_DIR 0x50000514          Controls in/out direction
GPIO_OUT 0x50000504          High or low for each pin
```

#grid(columns: (1fr, 1fr), [
For example:

```
    ldr r0, =0x50000504
    ldr r1, =0x5fb0
    str r1, [r0]
```
], [
  or in C:
```c
    #include ”hardware.h”
    ...
    GPIO_OUT = 0x5fb0
```
])
]

#polylux-slide[
  == Lighting a Single LED
  LEDs are connected as:
  
```
     ...|R3 R2 R1 C9|C8 C7 C6 C5|C4 C3 C2 C1|0000
bits     15----13 12-----------------------4
```

#v(1.5cm)

So lighting LED 5 in row 2..:
#pause
```
...   |R3 R2 R1 C9|C8 C7 C6 C5|C4 C3 C2 C1|0000
...00 | 0  1  0  1| 1  1  1  1| 1  0  1  1|0000
       5           f           b           0
```


```c
GPIO_OUT = 0x5fb0
```
]

#polylux-slide[
  == GPIO Bit Patterns
  LEDs are connected as:
  
```
     ...|R3 R2 R1 C9|C8 C7 C6 C5|C4 C3 C2 C1|0000
bits     15----13 12-----------------------4
```

#grid(columns: (5fr, 1fr), [
      - Row 1: 5, 6, 7, 9
      - Row 2: 1, 2, 3, 4, 5
      - Row 3: 1, 4, 5, 6, 7, 8, 9
    ], [
      #v(-0.7cm)
      #image("./figures/bbc-heart.png", height: 23%)
    ])

    #pause
    
```
...   |R3 R2 R1 C9|C8 C7 C6 C5|C4 C3 C2 C1|0000
...00 | 1  0  0  0| 0  0  0  0| 0  1  1  0|0000
       8           0           6           0
```
]

#polylux-slide[
  == Multiplexing GPIO
```c
while (1) {
    GPIO_OUT = 0x28f0;
    delay(JIFFY);
    GPIO_OUT = 0x5e00;
    delay(JIFFY);
    GPIO_OUT = 0x8060;
    delay(JIFFY);
}
```

Use say JIFFY = 5000 for 67 updates/sec.
]

#polylux-slide[
  == Frame Function
```c
static const unsigned heart[] = {  0x28f0, 0x5e00, 0x8060  }
/* frame -- show three rows n times */
void frame(const unsigned *img, int n) {
  while (n > 0) {
    for (int p = 0; p < 3; p++) {
      GPIO_OUT = img[p];
      delay(JIFFY);
    }
    n--;
  }
}
```

]

#polylux-slide[
  == Implementing Delay
  ```c
void delay(unsigned usec) {
  unsigned n = 2 * usec;
  while (n > 0) {
    nop(); nop(); nop();
    n--;
  }
}
  ```
- Experiment shows that each iteration takes 8 cycles = 0.5μs at 16MHz.
- Different numbers needed on V2 at 64MHz.
- Different numbers needed if compiler changes.
- ... or if anything changes!
]


#polylux-slide[
  #line-by-line[
  #callout_question[How is `GPIO_OUT` implemented?][
    We want to make C write to a specific memory location! Pointers.
  ]
  ```c
  (* (volatile unsigned *) 0x50000504) = ...

  
  ```
  Use C preprocessor to do this.
  ```c
  #define _REG(ty, addr)          (* (ty volatile *) addr)
  #define GPIO_OUT                _REG(unsigned, 0x50000504)
  ```
]
]

#polylux-slide[
  == Pushbuttons
  #light[
    Board: Circuit for pushbutton (pull-up resistor)
  ]

  #line-by-line[
  #[Must configure a pin to be an input:
  ```
SET_FIELD(GPIO_PINCNF[BUTTON_A], GPIO_PINCNF_INPUT, GPIO_INPUT_Connect);
  ```
  #light[See `hardware.h`.]

]
```c
unsigned x = GPIO_IN;
if (GET_BIT(x, BUTTON_A) == 0 || GET_BIT(x, BUTTON_B) == 0) {
  // A button is pressed
}
```
]
]


#polylux-slide[
  == Summary
  #line-by-line[
  - How LEDs work electrically.
  - How we can control $N^2$ LEDs using $2N$ GPIO pins using _multiplexing_.
  - How we can set a single LED in a multiplexed grid.
  - How we can create arbitrary patterns by quickly flashing LEDs on/off.
  - How to configure GPIO.
  - How to use pushbuttons.
]
]

