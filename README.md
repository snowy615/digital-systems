# Digital Systems
Welcome to the material repository of the Digital Systems course. This course is fully based on Mike Spivey's course materials, which can be found on [his Digital Systems website](https://spivey.oriel.ox.ac.uk/corner/Digital_Systems). This repo contains the materials that you need directly for the course. Feel free to clone to get a local copy, or to [browse online on GitLab (CS dept login required)](https://gitlab.cs.ox.ac.uk/marilk/digital-systems/).

README Contents:
- [How This Course Works](#how-this-course-works)
- [Lab Instructions](#lab-instructions)
- [Schedule & Deadlines](#schedule): Tutorial sheets, lab sign-off deadlines, etc...
- [Resources](#resources): Misc resources (rainbow chart, guide to C, datasheets...)
- [How to Clone this Repo](#how-to-clone-with-git)

## How This Course Works
You should:
- Attend lectures, where I will discuss most of the course material.
  - Lecture slides are [available in this repo](lecture-slides), but you cannot expect to study from only them.
- Review lecture material with the [course notes](./notes-digital-systems.pdf).
  - The lecture notes fill in details of concepts discussed in lectures.
- Do the exercises in the [problem sheets](problem-sheets), to be discussed in tutorials.
- Work on the lab exercises (see [below](#lab-instructions)).
- Practice and self-study certain skills that you need to pick up along the way:
  - C programming, which is discussed in lectures, practiced in labs, but for which you may need to do some self-study with materials online, e.g. [this excellent guide by the previous lecturer of this course](https://spivey.oriel.ox.ac.uk/corner/C_–_a_very_quick_guide_(Digital_Systems)). The level required to answer the relevant questions in the exam is roughly equivalent to what is practiced in labs.
  - Using the command line, for which [lab 0](./labs/lab0.pdf) gives an introduction. This is not examined, but is a skill you need as a computer scientist.
  - Using version control, e.g. git, which is also discussed in lab 0. Again, not examined, but same as above applies.

<!-- This course is different to the others you are taking, in that it is much more practical. One challenge that this brings, is that _you cannot expect to get truly good at this material without practicing these practical skills_ (e.g. C and assembly coding, or writing programs for our example Operating System). In other courses, revising takes the form of reading notes, and working through exercises on pen and paper. Here, you should expect to spend time programming your BBC micro:bit beyond just the labs. You can use the lab computers out of hours for this, or your own computer if you are able to set up the compiler. -->

## Lab Instructions
All instructions for the labs are in the [labs directory](labs).
- Reading the lab sheets in full _before_ attending the scheduled lab sessions.
  - You will not get through enough of the exercises if you need to start reading the lab sheet from scratch!
- Working on the lab exercises during the scheduled sessions.
- Getting your work graded by the required session.
  - No lab reports will be needed. Simply demonstrate that your solution works on the micro:bit, show a required bit of code, or answer a question.
  - There will be a large variation in background knowledge between students. The intention for the labs is to _educate_, not to evaluate. You can get an "S" grade without completing all required elements, if you show that you have engaged well (up to the discretion of the demonstrator). Still, if you do not complete labs, you are unlikely to be well-prepared for the exam.
  - "S+" grades are a bit more elusive. For some labs, I explicitly write something that you should do to get the grade. For others, you should use what you have been taught to build something creative, beyond what the lab sheet required you to do. If you ask us for a specific suggestion of what something "creative" is, you are not being creative.
- Get your labs signed off by the sign-off deadlines in the schedule. Lab demonstrators are allowed to deduct marks if you ask for a sign-off after these sessions. This is both to ensure you keep up with the course, and to avoid pileups of many students showing up in the last session for signoffs.
- Completing the lab sheets outside scheduled lab times.
  - While you are not required to finish all aspects of the labs within the scheduled times, completing the labs in full is one of the best ways to revise and practice for the exams. If you are not able to complete the labs up to "S" standard, you are not prepared to complete the exam questions.
  - Just as additional practice improves your chances in the exam for other courses, doing additional practice in the form of the "S+" exercises will improve your chances for the Digital Systems exam.
  - To practice for the exam, I highly recommend completing the lab exercises beyond what is required for an "S" grade, in your own time if necessary.


## Schedule
See the [lecture slides](lecture-slides) directory for pdf slides and handouts of all the lectures.

### Hilary Term
- "Tutorial Sheet n" indicates that by this lecture, the material required for the tutorial sheet will be covered. Tutorials can be arranged after this lecture.
- "Lab n sign-off" indicates that the results from the lab should be signed off by a lab demonstrator. Demonstrators may deduct marks if you sign off later. This is to ensure that work is signed off on time, and to avoid large pile-ups in later lab sessions.

| Week | Lecture                               | Practical         | Work Deadline    |
|------|---------------------------------------|-------------------|------------------|
| 1 HT | 1 - What is a computer?               |                   |                  |
|      | 2 - State and Instructions            | Lab 0 possible    |                  |
|      | Friday                                | Informal Lab session 0 |             |
| 2    | 3 - Compiling                         |                   |                  |
|      | 4 - Assembly Programming              | Lab 1 possible    |                  |
| 3    | 5 - Optimising Assembly & Subroutines |                   |                  |
|      | 6 - Arithmetic                        |                   | Tutorial Sheet 1 |
|      | Friday                                | **Lab session 1** |                  |
| 4    | 7 - Memory & Addressing               |                   |                  |
|      | 8 - GPIO                              | Lab 2 possible    | Tutorial Sheet 2 |
|      | Friday                                | **Lab session 2** | Lab 1 sign-off   |
| 5    | 9 - Serial                            |                   |                  |
|      | 10 - Interrupts                       | Lab 3 possible    |                  |
| 6    | 11 - Interrupt Mechanism              |                   | Tutorial Sheet 3 |
|      | 12 - Intro to Operating Systems       |                   |                  |
|      | Friday                                | **Lab session 3** | Lab 2 sign-off   |
| 7    | 13 - Device Drivers                   | Lab 4 startable   |                  |
|      | 14 - Context Switching                |                   |                  |
|      | Friday                                | **Lab session 4** | Lab 3 sign-off   |
| 8    | 15 - Scheduling                       |                   |                  |
|      | 16 - Message Passing                  | Lab 4 possible    | Tutorial Sheet 4 |
|      | Friday                                | **Lab session 5** | Lab 4 sign-off   |
| 1 TT | 17                                    |                   |                  |
|      | 18                                    |                   |                  |
| 2    | 19                                    |                   |                  |
|      | 20                                    |                   |                  |
| 3    | 21                                    |                   |                  |
|      | 22                                    |                   | Tutorial Sheet 5 |
| 4    | 23                                    |                   |                  |
|      | 24                                    |                   |                  |
| 5    | 23                                    |                   | Tutorial Sheet 6 |



## Resources
- [Datasheets & Schematics](schematics/) contain a lot of information on the hardware on the micro:bit.
  You will need this for problem sheets, and for lab exercises. It includes:
  - The [list of common instructions and rainbow chart](schematics/rainbow-chart.pdf).
  - The [ARM Architecture Reference Manual](schematics/ARM-architecture-reference-manual.pdf), which specifies the binary encoding of all instructions (`ctrl+f` for the instruction you seek.)
- A [very quick guide](resources/C-quick-quide.pdf) to programming in C.
  In this course, the labs and lecture examples will be given in C. Some students will have more experience with similar (imperative) programming languages than others. During this course, you will be expected to develop a practical ability to write programs in C, as well as the ability to read C programs.
- [Frequently Asked Questions](resources/FAQ.pdf) about programming the micro:bit, ARM assembly, and low-level C. Worth looking through!

## How to Clone with Git
To clone, you should get familiar with using Git repositories. If you are new to this, **start on the lab machines first**, and follow the instructions in [lab 0](./labs/lab0.pdf). To clone on your local machine:
- First make sure you have Git installed.
  - If you use Linux, I assume that you know how to install git, or find out where to learn (e.g. the [Git docs](https://git-scm.com/install/linux)).
  - If you use Mac, I recommend using the `brew` solution discussed in the [Git docs](https://git-scm.com/install/mac).
  - If you use Windows, I recommend following [this YouTube video](https://www.youtube.com/watch?v=UdhAb0t5iHw) to install Git-Bash.
- To clone from outside the department network, you need to set up a Personal Access Token with the `read_repository` permission.
  - Instructions here: https://gitlab.cs.ox.ac.uk/help/user/profile/personal_access_tokens.md#create-a-personal-access-token
  - Make sure to check `read_repository` under "select scopes"!
- To clone, run in your terminal
  - `git clone https://marilk:xyz@gitlab.cs.ox.ac.uk/marilk/digital-systems.git`
  - While taking care to replace "marilk" with your own departmental username, and "xyz" with your personal access token.




---
---
---

## Addenda on the Lectures / Further Thoughts
Here is a collection of random material that I find interesting/helpful, and complements things we have discussed in the course.

### CPU design
In the course we took the first steps into learning about CPU design. At the moment, with the boom in machine learning, compute hardware is a hot topic, and a lot of effort is going into developing new architectures that can offer more compute at less cost. GPUs were the first architecture to be used in ML, and e.g. Google have designed their own further tailored architecture in the form of TPUs.

How do you design an architecture for a specific application? What informs how a design should look? In all of engineering, this is typically the constraints. Or in other words, the limiting factors. It is helpful to start from these, because these are typically reasonably objective, in the sense that they come from physical laws. Designs built on such foundations are therefore more likely to be relevant for longer.

#### Energy usage
[This talk](https://www.youtube.com/watch?v=7XtBZ4Hsi_M&t=1982s) provides a very nice explanation of the design constraints currently facing the design of GPUs, and suggests an alternative architecture that can provide more compute and memory bandwidth within this constraint. I highly recommend watching it, in order to understand the reasoning behind design decisions, and the resulting trade-offs that come from it.

The main thesis is that energy dissipation and memory locality (both in terms of latency and energy usage) are the two biggest constraints in current compute architecture design. The talk argues for a massively parallel architecture with lots of local memory, since memory is a way to usefully use silicon real-estate, in a way that does not dissipate as much energy.

The talk was given several years ago by the CTO of Graphcore, a UK-based company, who are building new compute architectures. The longer in the past this talk was given, the more our benefit of hindsight will be as to whether these ideas really panned out practically. There are lots of reasons why companies and technologies fail and succeed, and sometimes it takes a few reinventions of an idea before it works out, and truly provides a workable solution to a problem. So linking this video is not an endorsement to the company per se. But I do think that we can _learn_ something about the reasoning in this video.

And I certainly would love to hear more about whether these design constraints have changed over the years.

#### SIMD
It would also be interesting to do a literature review on the development of other paradigms intended to speed up certain applications. In the 90s and 00s, SIMD (Single Instruction Multiple Data) instructions were added to CPUs in order to speed up numerical calculations, including graphics. GPUs were later made to further speed up these calculations. What were the design constraints there that made these architectures so successful? There are probably textbooks written about this. If anyone has a good reference, do let me know.

### How to Build a Transistor
This is a fascinating topic, and gaining a qualitative understanding is not all that hard (although actually predicting semiconductor properties _is_ hard, and we'll have to ask our friends in physics to explain this to us). I wish I had the time to give a high-level overview, but in lieu of this, I'll have to rely on a [popular-science video](https://www.youtube.com/watch?v=IcrBqCFLHIY), which I think gives a reasonable explanation.

### Analogue Computing
Again a fascinating topic. Two popular-science videos that I do think raise interesting questions:
- [The Most Powerful Computers You've Never Heard Of](https://www.youtube.com/watch?v=IgF3OX8nT0w) \
   A short history of analogue computing.
- [Future Computers Will Be Radically Different (Analog Computing)](https://www.youtube.com/watch?v=GVsUOuSjvcg&t=898s) \
   An example of a company called Mythic, that proposes to repurpose Flash memory to allow a *single* transistor to perform a low-precision multiplication, in order to implement neural networks in a very energy-efficient manner. I think this is an incredibly cool idea. Again, this is not an endorsement of the company, but it is an interesting idea.
