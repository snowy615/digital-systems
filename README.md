# Digital Systems
Welcome to the material repository of the Digital Systems course. This course is fully based on Mike Spivey's course materials, which can be found on [his Digital Systems website](https://spivey.oriel.ox.ac.uk/corner/Digital_Systems). This repo contains the materials that you need directly for the course. Feel free to clone to get a local copy, or to browse online.

## Resources
- [Datasheets & Schematics](schematics/) contain a lot of information on the hardware on the micro:bit.
  You will need this for problem sheets, and for lab exercises.
- A [very quick guide](resources/C-quick-quide.pdf) to programming in C.
  In this course, the labs and lecture examples will be given in C. Some students will have more experience with similar (imperative) programming languages than others. During this course, you will be expected to develop a practical ability to write programs in C, as well as the ability to read C programs.
- [Frequently Asked Questions](resources/FAQ.pdf) about programming the micro:bit, ARM assembly, and low-level C. Worth looking through!

## Lectures
See the [lecture slides](lecture-slides) directory for pdf handouts of all the lectures.

## Course Notes
All [course notes](./notes-digital-systems.pdf) are collected in a single pdf.

## Problem Sheets
Six [problem sheets](./problem-sheets) should be completed throughout the course.
| Sheet | Week  |
|-------|-------|
| 1     | HT 3  |
| 2     | HT 5  |
| 3     | HT 6  |
| 4     | HT 8  |
| 5     | TT 3  |
| 6     | TT 5  |


## Labs
Labs will run in Hilary Term, and will put what we discuss in lectures into practice. The [`labs/`](labs/) directory contains all instructions you need to complete the labs.

## Authors & Attribution
This course is fully based on [Mike Spivey's materials](https://spivey.oriel.ox.ac.uk/corner/Digital_Systems), which were taught by him in CS at Oxford until 2023. The course was then delivered by Mark van der Wilk, with small edits. Use of the materials is done in accordance with the [copyright and attribution policy on Spivey's corner](https://spivey.oriel.ox.ac.uk/corner/Project:Copyright_and_attribution_policy).

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

