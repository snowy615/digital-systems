#import "conf.typ": conf
#show: conf.with(
  title: [
    Lab 0: Compiling, Running, Debugging
  ],
  authors: (
    (
      name: "Mark van der Wilk",
      role: "Lecturer & Adaptations"
    ),
    (
      name: "Mike Spivey",
      role: "Lecturer & Course Designer"
    ),
  ),
)
#import "callouts.typ": *









#v(0.4cm)
#callout_info[Little to do, much to read.][
  It should only take you 10 minutes or so to follow the instructions. However, there is a lot of text which explains what is happening under the hood. As a Computer Scientist, you must understand this, and it will save you time in the long run. Read through these instructions before coming to the scheduled lab session, or do this session outside the scheduled sessions, to avoid wasting time where the demonstrators are present, and you can get support.
]


= Introduction
The purpose of this lab is to setup our computer environment so that we are able to compile, run, and test the programs we write. Somewhat annoyingly, this can be sometimes be more difficult than the actual programming itself! Thankfully, the labs are set up in such a way that many of the details are abstracted away. Nevertheless, you will need to develop some "computer use" skills in order to become effective at writing programs. Some students will already be fully comfortable with this, while others will never have used computers in this way before. For this course, and beyond it, you will need to pick up these skills, even though they will not be formally taught. This lab does try to help by providing some explicit guidance. However, for everyone, these skills are to an extent self-taught through practice, internet searches, and exchanges with colleagues.#footnote[The informal nature by which these important skills are developed has been noted by many in the field, and thankfully some have put some effort into collating things together in a short course called "#link("https://missing.csail.mit.edu/")[The Missing Semester of Your CS Education]". It is worth checking this out if you want to develop these skills further.] During labs, you can ask the demonstrators for help, but I also encourage you to discuss with your fellow students. If you have these skills, I encourage you to be helpful to your fellow students, when asked.

In this lab, you will:
+ Learn how to use the Linux command line.
+ Set up our environment and text editor (Geany).
+ Compile a program from source (assembly or C) to a binary program.
+ Copy the binary program to the micro:bit's memory, so the micro:bit can run it.
+ Let the micro:bit communicate with a PC, so we can view the results of our program after it has run.
+ (Optional) Use a debugger.

To carry out the instructions, you will need:
- A BBC micro:bit (provided by the department).
- A USB cable, with a full-size 'Type A' plug on one end and a 'Micro B' plug on the other (provided by the department).
- If you want to use your personal computer that does not have any old 'Type A' USB ports: A converter from the 'Type A' to 'Type C' connectors.

You can use your own USB cables (e.g. if you want it to be longer), but beware that some cables have power wires only, which are useless for our purposes. Our micro:bits will be powered over USB, and will also communicate with the host computer over USB for downloading programs, for sending and receiving charaters on the serial port, and for connection with debugging software running on the host.

If you are using the lab machines, then the toolchain should already be installed for you; otherwise, there's a page with installation instructions for Linux systems.

#v(0.3cm)

#callout_warning[Demonstrators _cannot_ help you set up your personal computer.][
  While I do encourage you to set up the toolchain on your own computer, and program the micro:bit at home (perhaps for practice during the vacation) we cannot provide the tech support to get this running. Demonstrators need to focus on supporting with the actual content of the course.

  The lab machines are properly set up to run the lab, and you are allowed to use them when they are free. So there is an option for additional practice, even if you do not get the toolchain running on your own computer.
]
\


= Getting the Sources
#callout_info[TLDR][If you want guidance for the using the terminal, follow these instructions. Otherwise just clone the repository in your home directory by running
```
git clone https://gitlab.cs.ox.ac.uk/marilk/digital-systems.git
```]
#v(0.3cm)
To start, you will need to get the source code for the labs, which will provide a starting point for the programs that you will be required to make. All the materials for the labs are in the #link("https://gitlab.cs.ox.ac.uk/marilk/digital-systems/")[GitLab repository]#footnote[https://gitlab.cs.ox.ac.uk/marilk/digital-systems/]. GitLab (like the better-known GitHub) is an online service for hosting code. A folder with code in it is known as a "repository", and `git` is a tool that is used to keep track of the history of the code (also known as _version control_). This is crucial when programming, because while working on a program, you will try many different approaches until something works, and you will want to keep track of versions that definitely work so you can roll back in case you introduce a bug. Version control is crucial when multiple people are working on the same codebase, and _all_ programming in a professional context uses it, so you will need to learn how to use it.

For the purpose of this course and these labs, we will only use git to share the course materials and lab source code, but you are welcome to use it to keep track of your solutions to the labs!

You will want to get a copy of the course repository (named `digital-sytems`) to your "home" directory. In Linux systems, your home directory is a location associated to your user account where you have read _and_ write permissions, and so it is the right place to store your work. The data is not physically stored on a particular lab computer. Instead it is an NFS (Network File System) directory, stored on another computer in the network, but accessible as a normal directory on _any_ lab machine you log into (the process of making a directory from a particular source, e.g. the network, accessible on your machine is called "mounting"). It is convenient to store files in this way, because it allows you to use any lab machine, rather than needing to sit behind the same lab machine for each session.

We will download a copy of the course repository using the command line. First, open up a terminal (if you don't know how, try an internet search, and if this doesn't help, ask a neighbour or demonstrator). At every point in time, the command line will be located in a particular directory. By default, this is your home directory, indicated as "\~". To get used to the terminal, run through the following commands:
- To find the full path to your current directory, run the "present working directory" command `pwd`.
- To be certain that you are in your home directory, run the "change directory" command `cd`. This will take you to your home directory, regardless of where you are.
- Check that you started in your home directory, by running `pwd` again, and noting that the output was the same as earlier.
- Using the "list" command `ls`, list the files and directories in the current directory.
- You can make `ls` give more information, including the time a file was modified, using the `-l` flag. You can also sort the results by the time a file was modified, by including the `-t` flag.
  - Run `ls -l`, `ls -l -t`, and note the differences in outputs.
  - Run `ls -lt` and note that the result is the same as `ls -l -t`. 

#figure(image("./figures/terminal1.png", width: 70%), caption: [Running a few commands to get to grips with the terminal.])

You can use `git` to download a copy of the sources, which is known as "cloning" a repository.
- Run the command `git clone https://gitlab.cs.ox.ac.uk/marilk/digital-systems.git`.
  - When prompted, fill in your departmental login and password, and then wait for the download to complete.
- Run `ls -lt`, and note that a new `digital-systems` directory has appeared.
- Run `ls digital-systems` to list the contents of this directory.
- Run `cd digital-systems` to move into this new directory.
- Run `ls` and note that its output is the same as before moving into this directory.

#callout_info[The code for all lab sessions are in the directory `digisys-labs-src`.][]


#figure(image("./figures/terminal2.png", width: 70%), caption: [Cloning the course repository, and navigating into it.])

= Setting up an Editor
If you already have a preferred editor, then you can use it to edit the provided programs and make micro:bit programs of your own. I use Emacs and VS Code myself, which can invoke make in an editor window, parse any resulting error messages, and show the lines of source code where the errors occurred. Other editors can do the same, but if you find yourself reading the error messages from the C compiler and counting lines in the source file, then you are using precious brain cells to do something a machine can do better.

If you don't already have an editor you like, then I suggest using Geany for this course. Geany is a simple, open-source editor and IDE that comes with most Linux distributions and is installed by default on the Raspberry Pi. I've prepared a version of Geany that can understand the syntax of ARM assembly language, and set up project files for each lab that contain the commands needed to build the programs (using make behind the scenes), to upload them to the micro:bit, and if needed to start the GDB debugger. Things on the lab machines will be set up so that you just need to double-click on one of these project files in the file manager to open the project in the Geany editor.

#v(0.3cm)
#callout_info[A program can be split across several source files!][
  One particular reason why using a proper code editor, over something simpler like `gedit`, is that a program can be split across different source files. Editors like Geany group together the relevant files in a "project", which makes it easy to navigate between them. It also helps ignore files that are not relevant to _writing_ code, like files generated by the compiler, which clutter up your terminal and graphical file browser.
]
#v(0.3cm)

Having cloned the repository, if you want to use Geany then you will need to configure it for editing ARM assembly language, and you will need to generate Geany project files for each lab.#footnote[These project files are machine-specific and not suitable for checking in to version control.] To do this:
- Change to the `digisys-labs-src` directory.
- Invoke the shell script `setup/install`.

This permanently installs settings under `$HOME/.local/share` and
`$HOME/.config/geany`, and creates files `lab0-echo/lab0.geany`, etc. in the directory for each lab. The command needs to be run only once, not once for each session.

= Investigating the Program
Now that we have set up our environment, we are ready to compile our first program. We will focus on the example that is in the directory `lab0-echo` in the `digisys-labs-src` directory. Open up Geany to look at the source files (@fig:geany-lab0). There are several files present, some of which you will again in future lab exercises.

The source file `echo.c` the code for the main program. The program will start in the `init()` function. Even if you don't have experience with writing C code, you should be able to roughly understand what the program does, since the subroutines have descriptive names in English. This program will communicate text with the PC over the USB connection via the "serial port" protocol.#footnote[In the past, the serial port was a very simple way to have computers communicate with each other. It was simple from the point of view of hardware and software: Three wires, and a rudimentary agreement on the electrical format on how to transmit data (we will cover this in lectures later). However, the connected computers needed to know what was connected _before_ communicating. This was a pain, because it required setting up hardware very carefully: First connect it, then install software that could communicate it, and then use it. Disconnecting and reconnecting often wouldn't work. USB was designed to make automate the connection procedure, and to make connections more robust. However, this came at a cost of the simplicity, both in terms of hardware and software. Nowadays, computers no longer have serial ports, and so it is not possible to connect a simple device like the micro:bit via a simple protocol like the serial port. Having the micro:bit communicate with a PC would require setting up an entire USB connection, which requires significantly more complicated software! As a solution, the microbit includes a _different_ chip that converts the simple serial port signals sent by the microbit to signals that can be sent over USB. To the PC, this chip behaves as a serial port, and so simple software on the PC can receive this data. It's slightly ironic that we need such a sophisticated intermediate chip to transmit such a simple communication protocol, but this is the price we pay for abstraction and automation.] The function `serial_getline()` will collect characters sent over the serial port, until a new line is received, at which point the function will return, while `serial_puts()` will send a string of characters to the PC. Hopefully you can infer that this program will prompt the user to input text, and then send the text back. Hence why the program is named "echo".

There is another sourc file called `startup.c`. This file takes care of a few things immediately after the startup of the CPU, that are needed to make the C program work. Eventually, we will discuss the exact sequence of steps that happens after startup. If you're curious, you can take a look at what happens. You can note that another function actually calls `init()`. If you do some detective work, you can infer that the CPU must start at the function `__reset()`, which calls `default_start()` which is an alias for `__start()`, which calls `init()`.

You can also see the following files:
- `hardware.h`: Header files are meant to be included in C source files using the `#include` directive. If you take a look in the file, you'll see a lot of `#define` statements that define constants that will help us interact with the hardware (which we discuss in lectures at some point).
- `Makefile` and `nRF51822.ld`, which specify instructions for how to turn the C source code in to executable bytecode (compiling).


= Compiling the Program
#figure(image("./figures/geany-lab0.png", width: 70%), caption: [The lab0 Geany project, and main source file of the C program that we want to compile.]) <fig:geany-lab0>


The full sequence of actions needed to prepare a program are spelled out in a "makefile". Running the program `make` will look for a file called `Makefile` in the current directory, and follow the instructions in it to build the program.
- Run `make` to build the entire program.

#figure(image("./figures/terminal3-make.png", width: 70%), caption: [Building a demo program using `make`.]) <fig:make>

The individual commands shown below will be executed automatically. I will spell them out so that you know what they do, but after you have built a few programs, you will no doubt be content to let them whizz by without paying much attention – unless the build grinds to a halt with an error message, that is.

The first command to be executed is this:
```sh
arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -O -g -Wall -ffreestanding -c echo.c \
  -o echo.o
```

It uses a C compiler, `arm-none-eabi-gcc`, to translate the source file `echo.c` into object code in the file `echo.o`. This compiler is a "cross compiler", running on an Intel machine, but generating code for an embedded ARM chip: the none in its name indicates that the code will run with no underlying operating system. The  flags given on the command line determine details of the translation process.
- `-mcpu=cortex-m0 -mthumb`: generate code using the Thumb instruction set supported by the ARM model present on the micro:bit.
- `-O`: optimise the object code a little.
- `-g`: include debugging information in the output.
- `-Wall`: warn about all dubious C constructs found in the program.
- `-ffreestanding`: this program is self-contained, so don't make some common assumptions about its environment.
- `-c`: compile the C code into binary machine language, but don't put together an executable image.
- `-o echo.o`: put the binary code in the file echo.o.

Next, make also compiles the file `startup.c` in a similar way.
```sh
arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -O -g -Wall -ffreestanding \
  -c startup.c -o startup.o
```
The file `startup.c` contains the very first code that runs when the microcontroller starts. It is written in C, but it uses several non-portable constructions, and few of the usual assumptions about the behaviour of C programs apply. With both of the source files translated into object code, it is now time to link them together, forming a file `echo.elf` that contains the complete, binary form of the program. This is done by invoking the C compiler again, but this time providing the two file `echo.o` and `startup.o` as inputs.
```sh
arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -O -g -Wall -ffreestanding \
  -T nRF51822.ld -nostdlib echo.o startup.o -lgcc -o echo.elf -Wl,-Map,echo.map
```
Again, the detailed behaviour of this command is determined by the long sequence of
flags. The new ones are as follows:
- `-T nRF51822.ld`: use the linker script in the file `nRF51822.ld`. This script describes the layout of the on-chip memory of the micro:bit: 128K of flash memory at address `0`, and 16K of RAM at address `0x20000000`. It also says how to lay out the various segments of the program: the executable code `2.text` and string constants `.rodata` in flash, and the initialised data `.data` and uninitialised globals `.bss@` in RAM.
- `-nostdlib`: the usual startup code and libraries for a C program are omitted, because we are supplying our own.
- `-lgcc`: the C compiler's own library is searched for functions (such as out-of-line code for integer division) that the program needs.
- `Wl,-Map,echo.map`: a map of the layout of storage is written to the file `echo.map`
- `-o echo.elf`: the output goes into a file `echo.elf` that has the same format as the `.o` files prepared earlier, but now contains a complete program.

Many of these flags can be used unchanged in building other programs in the course, and it is good to know why they are there. Faced with the problem of fitting an application into a tiny amount of memory, embedded programmers become intensely interested in storage layouts and linker scripts.

#v(0.4cm)
#callout_info[What is object code?][Object code is a kind of partially compiled code. Each `.c` file contains several functions, and in the `.o` file, each function has already been converted into a list of assembly instructions. However, it is possible to call functions defined in a different `.c` file! The `.o` file does not know anything about these other functions! So the compiler _cannot_ yet know, which addresses need to be jumped to, in order to call a particular subroutine. In fact, the location of the functions hasn't been set yet, so some jump instructions have an unknown target location.

The _linker_ combines all the `.o` files together, allocate addresses for all the functions, and fix all the jump instructions, to arrive at a final list of assembly instructions with no unknown addresses, that can be computed to machine code, ready for execution.]
#v(0.4cm)

We are nearing the end of the process. The next command just prints out the size of the resulting program (see @fig:make). Here we see that the program has 972 bytes of code, no initialised storage for data, and 84 bytes of uninitialised space (actually, it is initialised to zero) for global variables. In the echo program, this consists almost entirely of an 80-byte buffer for a line of keyboard input.
- Identify the line in the source code (there are two possible `.c` files to check) that requests this memory in RAM.

The final stage prepares the binary object code in another format, ready to be downloaded to the micro:bit board.
```sh
arm-none-eabi-objcopy -O ihex echo.elf echo.hex
```
The file `echo.elf` is a binary file, containing the object code and a lot of debugging information, whereas `echo.hex` is actually a text file, containing just the object code encoded as long hexadecimal strings, a format that the loading mechanism on the micro:bit understands.

= Copying the Program to the micro:bit
If you plug in a micro:bit, it will appear as a USB drive on your computer, and you can copy the file `echo.hex` to it, either by dragging and dropping from the file manager with the mouse, or by using a shell command:
```sh
cp echo.hex /run/media/marilk/MICROBIT/
```
(with `marilk` replaced by your own username, typically in the format ug19xyz). The yellow LED on the micro:bit will flash briefly, then the program will start to run. Note that the USB drive appears to have a couple of files on it – one a text file giving the version number of the board and its embedded software, another an HTML file with a link to the micro:bit website. Any files you drag and drop there do not appear as files on the drive, however: they are instantly consumed by the flash loader and not stored as files.

= Communicating Between the micro:bit and the PC
The echo program reads and writes the serial interface of the micro:bit, which appears as a terminal device /dev/ttyACM0 on the Linux machine. To connect with this device, it's convenient to use a program called `minicom` on the Linux machine. Open a terminal, then type the command#footnote[If you are lucky, this setup will agree with the default, and you can type just `minicom`]:
```sh
minicom -D /dev/ttyACM0 -b 9600
```

After connecting, you should press the reset button on the micro:bit to start the program again. You should see the message `Hello micro:world`, followed by `>` as a prompt. Type characters at the prompt: they will be echoed, and you can use the backspace key to make corrections. When you press Return, the line you typed will be repeated, and then a new prompt appears (see @fig:minicom).

#figure(image("./figures/terminal4-minicom.png", width: 70%), caption: [Communicating with the micro:bit using `minicom`.]) <fig:minicom>

= Using Geany
The instructions above tell you how to compile, upload and run a micro:bit program from the command line, but all the same actions can be performed from the Geany editor. To open the program as project within Geany, use the file manager to look for the file `lab0-echo/lab0.geany` and double-click on it. This should launch Geany with the file `echo.c` initially open, and the Build menu filled with appropriate actions for the project. Specifically, when we choose Build>Make in a moment to compile the program, Geany will use the Makefile provided, and therefore invoke the cross-compiler `arm-none-eabi-gcc` rather than the native C compiler that is called just plain gcc. (Don't try opening individual files of C code with Geany rather than opening the project, or the setup will be wrong.)

To build and run the program from within Geany:
- Choose Build>Make to compile the program. Geany will invoke make, and the same steps will happen as were listed earlier. The commands and any error messages will appear in a separate pane at the bottom of Geany's window, and afterwards Geany will analyse the error messages and highlight corresponding lines in the source file.
- Choose Build>Upload to upload the program to a plugged-in micro:bit.
- Choose Build>Minicom to launch a new window running minicom to talk to the micro:bit.
You can leave this window open as long as you like, or close it when you have finished interacting with the running program.

#v(0.4cm)
#callout_idea[If things don't work, remove levels of abstraction.][The more steps that are automatically done for you, the more steps can silently go wrong. If something doesn't work as expected, try running it from the basics using the terminal only. It may be that Geany is incorrectly configured. Alternatively, Geany may not be displaying helpful error messages, that the terminal does, which can help you figure out how to fix things.]

= Optional: Using a Debugger
The USB interface between the host computer and the micro:bit serves three purposes: it enables us to upload programs to the board, it lets us interact with a program running on the board over the micro:bit's serial port, and thirdly it allows a debugger running on the host to monitor and control the execution of the program on the micro:bit.

Here's how to run the program under control of a debugger, so as to execute it step by step. You will use two terminal windows for this experiment – one to connect to the micro:bit using `minicom` as before, a second one to run the GNU debugger `gdb`. Instructions are given here to start a debugging session from the command line, but the same effect can be achieved by choosing Build>Minicom and Build>Debug from within Geany. However you start the debugger, you may like to enlarge its window to show more lines, particularly if you want to use the multi-panel interface described later.

#v(0.4cm)
#callout_info[Some knowledge of C programming required][
  This section will explore running the C source code. You should be familiar enough with C to understand roughly what each line in `echo.c` is doing. You may want to review the "very quick guide to C" first, or return to this section after Lab 1.

  See #link("https://spivey.oriel.ox.ac.uk/corner/C_–_a_very_quick_guide_(Digital_Systems)").
]

== Halting and Running
#callout_warning[The Debugger is Brittle: When in doubt, turn it off, and then on again.][
When the CPU is halted, take care to not press more than one character in minicom. This causes the process to crash. If this happens, quit the debugger using `Ctrl+C` followed by `Ctrl+D`, reset the micro:bit, and then restart the debugging process.
]
+ Plug in the microbit, and open a terminal window to run `minicom`, as before. Reset the microbit, and check that you can type characters and have them echoed by the program.
+ Open another terminal window, change to the `lab0-echo` directory, and run the shell script `./debug echo.elf`. This script first starts an adapter program `pyocd` that can talk to the micro:bit over the USB link, then connects to the adapter with the interactive debugger GDB. See @fig:debugger.

#figure(image("./figures/terminal5-debugger.png", width: 100%), caption: [Halting the demo program in the debugger.]) <fig:debugger>


The debugger has stopped the program wherever it was: as you might expect, the program is sitting in a tight loop, waiting for a character to be typed on the keyboard. As we'll learn much later, `UART_RXDRDY` is a register in the serial interface whose value indicates whether a character has been received, and line 28 is a loop that tests the register repeatedly until a character arrives. Sadly, the debugger doesn't have a sophisticated graphical user interface, and we will interact with it using text commands. Let's practice halting and continuing program execution.

The program is now halted. The CPU is no longer executing any instructions.

3. Check that the CPU is halted by pressing a key in the minicom window. The corresponding character will *not* appear, since minicom has only sent the character to the micro:bit. In normal operation, the program on the micro:bit sends the character back to minicom so it gets displayed. However, since the program is halted, this does not happen.
+ In the `gdb` prompt, use the command `cont` to continue execution of the program, and notice that the character will appear in minicom. You can now continue to type characters, and they will appear as usual, since the program is running as normal (@fig:debugger-cont).
+ To again halt the execution, press `Ctrl+C` in the `gdb` window. You can now repeat the process above (@fig:debugger-halt).

#figure(image("./figures/terminal5-debugger2.png", width: 100%), caption: [Continuing the program, and noting that the character that was typed earlier (in this case 'c') has suddenly appeared.]) <fig:debugger-cont>

#figure(image("./figures/terminal6-debugger3.png", width: 100%), caption: [Terminating using `Ctrl+C` (displayed as `^C`), pressing the 'd' key in minicom, and continuing to see the 'd' appear.]) <fig:debugger-halt>


== Stepping through Code
Debuggers are primarily used to *observe the state* of the computer as we run through the code. This is helpful for getting rid of bugs, because we can observe whether the code we have written has the desired effect on the state of the computer. When the actual state of the computer departs from the state we expect/desire, we know that the code that has been run must contain the bug.

We will now use the debugger to run the C code line-by-line, starting from the very beginning of the program.
1. Halt the CPU at some point, by starting the debugger as described in the previous section.
2. Run the command `(gdb) monitor reset halt`. This resets the CPU, which has an effect similar to pressing the button on the micro:bit board, but halts the CPU execution immediately.
3. Run the command `(gdb) advance init`. This allows the CPU to run as normal, up to the start of the `init()` function in `echo.c`, at which point the debugger halts the CPU again.
4. We can now use the command `(gdb) next` to execute a single line of C code, and then halting again. Run this until you see the "Hello" message appear (@fig:debugger-next).
5. Now try using the command `(gdb) step`, which _steps into_ any function call that is made in this line.
6. Use next several more times, until the prompt does not appear again. To get an S+ for lab 1, tell the demonstrator which line of code you think is currently being executed, and how to get the debugger to continue.
7. Once you get the debugger to continue, keep running lines in order to get you back to a line in `init()`.

At this point, you have seen how to step past and into function calls. You may want to practice this a bit more. Some more useful debugger commands are:
- `(gdb) where`: This displays the _call stack_, i.e. the list of functions that were called to get you to the line where you are currently stopped.
- `(gdb) up`: Move up in the call stack. This allows you to get out of a function that you accidentally stepped into.
- `(gdb) down`:  The opposite of `up`.

Although GDB does not have a GUI, it can produce a display of what is happening in the
program by using a multi-panel "Text User Interface". Before activating it, you may like to
stretch the terminal window vertically so it occupies most of the height of your display.

9. Activate the UI by running `(gdb) layout regs` (see @fig:debugger-split).

#figure(image("./figures/terminal7-debugger4.png", width: 100%), caption: [Stepping through C code, line by line. Note that here we are halted after sending the first "Hello micro:world!" message, but before sending the "> " prompt indicator.]) <fig:debugger-next>

#figure(image("./figures/terminal8-debugger5.png", width: 100%), caption: [Stepping into `serial_getline()`, and following the code to get back to the next line in `init()`.]) <fig:debugger-step>

#figure(image("./figures/terminal9-debugger-layout-split.png", width: 70%), caption: [Text-based UI of the debugger.]) <fig:debugger-split>

== Stepping through Assembly
So far, we have only looked at stepping through C code line by line. We can also do the same for each individual assembly instruction, and look at the effect they have on the state of the CPU.

+ Halt the CPU at an arbitrary point.
+ Run the commands `(gdb) layout split` and `(gdb) layout regs`. 
+ Run the command `(gdb) stepi`, to execute the next instruction, and then halt again (see @fig:debugger-assembly).

This is extremely useful when practicing assembly programming, because you can directly see the effect your instructions have on the register state.

#figure(image("./figures/terminal10-debugger-assembly.png", width: 100%), caption: [Debugger stepping through assembly code, while visualising the effect on the state of the CPU (i.e. the registers).]) <fig:debugger-assembly>





