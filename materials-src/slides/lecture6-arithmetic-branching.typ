#import "theme.typ": *
#show: doc => conf(doc)

#title-slide(title: [Lecture 6 \ Finite Width Artithmetic & Branching])

// #enable-handout-mode(true)

#slide[
  #callout_warning[We have not _precisely_ specified finite width arithmetic][
    - Registers have limited _width_ (32 bits for ARM)
    - Can represent $2^32 = #calc.pow(2, 32)$ different values
    - Regular arithmetic is specified on a larger set of numbers!
  ]
  #v(0.6cm)

  So far, we have implicitly assumed that operations work on *unsigned integers*, i.e. numbers from $0$ to $2^32 - 1$.

  Let's _precisely_ define:
  - how we represent numbers
  - what arithmetic operations do

  We will illustrate this for 8 bit binary numbers.


  #callout_question[What happens when we produce a result larger than the max?][
We will precisely specify how condition codes in #psr are set by arithmetic operations.
  ]
  #v(0.8cm)

  #callout_question[How do we represent negative numbers?][]

  #callout_question[How can we implement subtraction?][]

  #callout_question[How do branching operations actually work?][]

]

#slide[
  == Representing Numbers: Unsigned
  Let's be precise about how bitstrings represent numbers:
  // Need to be precise about the bit strings that are physically present in our machine, and the number (which is an idea) that they represent
  // Abstraction function

  $
  "bin" :& {0,1}^n arrow NN \
  "bin"(a) =& "bin"(#for i in range(8).rev() [$a_#i$]) \
  =& 
  sum_(i=0)^(n-1) 2^i a_i
  $
  // How any positional number system represents numbers, we choose base 2. Clearly we can only represent a subset of all numbers!

  // C type unsigned

  // Instructions operate directly on bitstrings, so by making this relationship explicit, we can precisely understand the arithmetic that instructions define

  Can prove that:
  $
  0 <= "bin"(a) <= 2^n-1
  $
]

#slide[
  == Defining Unsigned Addition
  Representing `add` operation on bitstrings as $plus.circle$.
  
  We want:
  $
  "bin"(a plus.circle b) = "bin"(a) + "bin"(b)
  $

  #v(0.8cm)

  #callout_important[We cannot find $plus.circle$ that satisfies this!][Finite width of bitstrings means we cannot represent all answers we want. E.g. 254 + 3 = 257, but cannot represent this with 8 bits!]
]

#slide[
== Defining Unsigned Addition
Instead, want $plus.circle$ so that#footnote[$a≡b mod c$ means that $a-b = k c$, for some $k$ (see modular arithmetic).]:
$
"bin"(a plus.circle b) ≡ ("bin"(a) + "bin"(b)) &#h(2cm)& mod 2^n
$
#v(-0.3cm)
- Gives the same result as normal addition if result $< 2^n$.
- Result "wraps" around to zero if $>= 2^n$.
- Can be implemented as normal binary addition, but ignoring bits $>= n$.

$
&1011 thick 0110 &#h(5cm) 1&82 \
&underline(0101 thick 1101) + & &underline(93)+  \
1 thick &0000thick 0011 & 256 + #h(1cm) &19
$
]

#slide[
  == What can go wrong?

  #callout_idea[Status bits tell us when we deviate from normal arithmetic][]
  
  The status bits `N`, `Z`, `C`, `V` are in #psr. The instruction `adds` is does "add"ition, and sets the "s"tatus bits.
  - `N`: ...
  - `Z`: ...
  - `C`: #text(red)[*Carry bit*. Set if the unsigned addition overflowed. I.e., a carry was produced which could not be stored in the register.]
  - `V`: ...
]

#slide[
  == Representing Negative Numbers
  We can introduce a _different_ mapping from binary representations to numbers, to represent negative numbers.

  #v(0.6cm)
  #callout_idea[Two's Complement Representation][
    $
    "twoc" &: {0, 1}^n arrow ZZ \
    "twoc"(a) &= sum_(i=0)^(n-2) 2^i a_i - a_(n-1) 2^(n-1)
    $
  ]
  #v(0.8cm)
  - Easy to see that it can represent negative numbers.
  - But has many other nice properties!
  - All modern computers use twoc for representing negative numbers.
]

#slide[
  == Two's Complement Example
  - In the last lecture, we encountered a jump instruction with an offset of `0xFA`.
  - #[Decoded into binary, we get
  $
  mono("0xFA") = mono("0b1111 1010")
  $]
  - And $"twoc"(mono("1111 1010")) = -128 + 122 = -6$
]

#slide[
  == Binary and Twoc Numbers Compared
  #grid(columns: (1.5fr, 1fr), [
    #item-by-item[
    - $-2^(n-1) <= "twoc"_n (a) <= 2^(n-2) - 1$
    - $"twoc"_n (a) = "bin"_(n-1)(a_(n-2:0)) - a_(n-1) 2^(n-1)$
    - So, twoc and bin are equal, or differ by $2^n$
    $ "twoc"(a) ≡ "bin"(a) &#h(1.5cm)& mod 2^n $
    - #[And so, with a bit of work, can show
    $
    "twoc"(a plus.circle b) ≡ "twoc"(a) + "twoc"(b) mod 2^n
    $
  ]
  ]
  ], image("figures/bin-twoc.png", height: 90%))
]

#slide[
  #set align(horizon)
  #callout_idea[Addition is the same for both signed and unsigned numbers!][
    - It's just that the interpretation of the binary string is different!
    - Same addition circuit can be used for signed and unsigned numbers!
  ]
]

#slide[
  == Subtraction
  #callout_question[How can we implement subtraction?][]
  Since $b - a = b + (-a)$, let's first consider how to negate a number.
]

#slide[
  == Negation
  Take $overline(a)$ to be the binary complement of $a$, i.e. $overline(a)_i = 1 - a_i$.
  $
  "twoc"(overline(a)) &= sum_(i=0)^(n-2) (1-a_i)2^i - (1 - a_(n-1)) 2^(n-1) \
  &= -"twoc"(a) + sum_(i=0)^(n-2)2^i - 2^(n-1) \
  &= -"twoc"(a) -1
  $

  So, for all bit strings $a$, we have
  $
  "twoc"(overline(a) plus.circle 1) ≡ -"twoc"(a) &#h(1.5cm)& mod 2^n
  $

  Few things to note:
  - Overflow in $plus.circle$ makes negation of 0 correct (stays zero).
  - Negation of $-128 = mono("0b1000 0000")$, remains itself, \ which is correct $mod 2^n$.
    - Makes sense, since $+128$ cannot be represented in twoc.
]

#slide[
  == Subtraction
  #callout_question[How can we implement subtraction?][]
  Since $b - a = b + (-a)$, let's first consider how to negate a number:
  $
  "twoc"(overline(a)) = -"twoc"(a) - 1.
  $

  So, this allows us to define $b minus.circle a = b plus.circle overline(a) plus.circle 1$, where $plus.circle 1$ can be implemented by starting with a carry of 1!
  $
  "twoc"(b minus.circle a) = "twoc"(b) - "twoc"(a) &#h(1.5cm)& mod 2^n,
  $
]

#slide[
  == What can go wrong?
  Overflows can occur in signed arithmatic too: $"twoc"(127 plus.circle 1) = -128$.
  - Overflow is impossible if the signs are opposite.
  - If numbers have same signs, but result has opposite sign, then a *signed overflow* has occurred.

  Status bits:
  - `N`: ...
  - `Z`: ...
  - `C`: *Carry bit*. Set if the unsigned addition overflowed. I.e., a carry was produced which could not be stored.
  - `V`: #text(red)[*Overflow bit*. Set if signed addition overflowed (test the above).]
]


#slide[
  #set align(center + horizon)
  == Branching & Comparisons
]

#slide[
  == Conditional Branching
  #item-by-item[
  - If/else and loops all require branching if a particular condition is true.
  - ARM provides many branching instructions to make this convenient.
  - The condition of a branch is always a property of arithmetic instr.
  ]
  #uncover("4-")[#callout_idea[In ARM, branching is conditional on state of #psr status bits][]]
  #item-by-item(start: 5)[
  - Properties of arithmetic outcomes are stored in #psr *status bits*.
  - In addition to checks if arithmetic goes wrong, #psr contains bits helpful for branching.
]
]

#slide[
  == Status Bits
  #[Status bits:
  - `N`: #text(red)[*Negative bit*. If the result is negative, i.e. MSB is one.]
  - `Z`: #text(red)[*Zero bit*. If the result is zero, i.e. all bits in arithmetic result are zero.]
  - `C`: *Carry bit*. Set if the unsigned addition overflowed. I.e., a carry was produced which could not be stored in the register.
  - `V`: *Overflow bit*. Set if signed addition overflowed (test the above).]
]


#slide[
  == Branching Instructions: Equality
  Branching instructions interpret the #psr bits as though a subtraction was performed.

  Compare instruction `cmp` performs subtraction, sets #psr status bits, and does not write result to register.#footnote[Other instructions (e.g. `adds`, `subs`) also set #psr status bits, and can also be used to branch.]

  Equality branches:
  - `beq`: Branch if equal. Branches if `Z`.
  - `bne`: Branch if not equal. Branches if `!Z`.
]

#slide[
  == Branching Instructions: Signed Comparison
  `blt`: Branch if less than (signed). Can we figure out which condition we need to hold the status bits to?

  If $"twoc"(a minus.circle b) < 0$ then either
#item-by-item(start: 2)[
  - we really have $"twoc"(a) < "twoc"(b)$, or
  - the subtraction overflowed (e.g. if $"twoc"(b) < 0 < "twoc"(a)$).
]
  #v(-0.4cm)
  #show: later
  #show: later
  #show: later
  So for this, we need `N` and `!V`.

  If $"twoc"(a minus.circle b) >= 0$ then either
  - we really have $"twoc"(a) >= "twoc"(b)$, or
  - the subtraction overflowed (e.g. if $"twoc"(a) < 0 < "twoc"(b)$)
  #v(-0.4cm)
  So for this, we need `!N` and `V`.
]

#slide[
  == Branching Instructions: Signed Comparison
  So overall, we need (`N` and `!V`) or (`!N` and `V`), which we can summarise as just needing `N != V`.
]


#slide[
  == Branching Instructions: Unsigned Comparison
  `blo`: Branch if lower (unsigned). Can we figure out the condition?
  
  The same $minus.circle$ operation performs subtraction on unsigned numbers, modulo $2^n$ (same reasoning as $plus.circle$, going from bin to twoc).

  Example: $32 - 9$:
  $
&0010 thick 0000 &#h(5cm) \
& quad quad quad thick thick thick 1 \
&underline(1111 thick 0110) + \
1 thick &0001thick 0111
$

If $"bin"(a) >= "bin"(b)$, then we get an overflow.
]

#slide[
  == Branching Instructions: Unsigned Comparision
  Proof:
$
&"bin"(overline(b)) + "bin"(b) = 2^n - 1 &#h(3cm)&& "Every bit in sum is 1." \
&"bin"(overline(b)) + 1 + "bin"(a) >= 2^n &&& "From " "bin"(a) >= "bin"(b) \
&therefore a plus.circle b plus.circle 1 "must overflow."
$

Similar argument showing that if $"bin"(a) < "bin"(b)$, there is  no overflow.

So all we need is `!C`.
]


#slide[
  == Summary
  - Full specification of how bit patterns represent numbers, \ signed (bin) and unsigned (twoc).
  - Full specification of addition and subtraction, and the limitation to _modular arithmetic_.
  - Full specification of status bits, as signifiers of departure from regular arithmetic, and flags helpful for branches (`Z` and `N` flags).
  #v(0.6cm)
  #callout_skill[Derivation of flags required for various branch operations][For exam, must demonstrate/understand reasoning, but no need for memorisation, see instruction list.]
]


/*#slide[
  == TWOC
  - Smallest, and largerst numbers
  - All modern computers use two's complement for representing negatie numbers
  - `0xfa` from last lecture
  - bin(a) twoc(a) are either the same or differ by 256
  - $"twoc"(a plus.circle b) = "twoc"(a) + "twoc"(b)$
  - Same addition circuit can be used for unsigned numbers as for signed numbers
  - Take twoc number, and find negative (can always do this) (flip all bits and add one)
  - How to implement subtraction
  - Can you get overflows from subtraction?
]*/
