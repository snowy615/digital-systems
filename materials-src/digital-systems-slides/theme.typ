#import "@preview/polylux:0.4.0": *
#import "@preview/cetz:0.3.4"

#let conf(doc, aspect-ratio: "16-9") = [
#let theme-ox-digital-systems(aspect-ratio: aspect-ratio, body) = {
  let margin = if aspect-ratio == "16-9" {1.5cm} else {2.0cm}
  set page(
    paper: "presentation-" + aspect-ratio,
    fill: white,
    margin: margin
  )
  //set text(font: "Fira Sans")

  body
}

#show: theme-ox-digital-systems.with(aspect-ratio: aspect-ratio)
#set text(size: 25pt)

#show link: underline
#show link: set text(blue)
#show link: strong

#doc
]

// #enable-handout-mode(true)

#let title-slide(title: [], aspect-ratio: "16-9") = {
  slide(
    if aspect-ratio == "4-3" {
    set align(center + horizon)
    rect(width: 95%, radius: 20pt, fill: rgb(233, 243, 253))[
      #show text: it => smallcaps(it)
      #v(1cm)
      #strong(text(size: 1.7em, [Digital Systems])) \
      #text(size: 1.3em, [#title])
      #v(1cm)
    ]
    parbreak()

    [Mark van der Wilk \
     Hilary Term 2024]

    set align(bottom)

    grid(columns: (0.7fr, 1fr), align(left)[#image("./theme/ox-cs-log.png", width: 100%)],
    align(right + bottom)[#rect(stroke: none, {text(size: 0.7em, "Following the course of past years by Mike Spivey")})])
  } else if aspect-ratio == "16-9" {
    set align(center)
    rect(width: 95%, radius: 20pt, fill: rgb(233, 243, 253))[
      #show text: it => smallcaps(it)
      #v(1cm)
      #strong(text(size: 1.7em, [Digital Systems])) \
      #text(size: 1.3em, [#title])
      #v(1cm)
    ]
    [Mark van der Wilk \
     Hilary Term 2025]
    set align(bottom)

    grid(columns: (0.7fr, 1fr), align(left)[#image("theme/ox-cs-log.png", width: 80%)],
    align(right + bottom)[#rect(stroke: none, {text(size: 0.7em, "Following the course of past years by Mike Spivey")})])
  }
)
}

#let callout(title, body, icon: none, colour: rgb(0, 0, 0)) = {
  let icon = {
    if icon.len() > 6 {
      image(icon, width: 1.0em)
    } else {
      icon
    }
  }
  
  if body != [] {
    show rect: set block(spacing: 0.2em)
    //set rect(inset: 10pt)
    rect(width: 100%, stroke: (left: (paint: colour, thickness: 6pt), right: (paint: colour), top: (paint: colour), bottom: (paint: colour)), radius: 6pt)[
      #rect(width: 100%, fill: colour.lighten(85%))[
        #grid(columns: (1.1em, 1fr), icon, align(horizon)[
          #h(0.3em) *#title*
        ])
      ]
      #rect(width: 100%, stroke: none)[#body]
    ]
  } else {
    rect(width: 100%, stroke: (left: (paint: colour, thickness: 6pt), right: (paint: colour), top: (paint: colour), bottom: (paint: colour)), radius: 6pt)[
    #rect(width: 100%, fill: colour.lighten(85%))[#grid(columns: (1.1em, 1fr), icon, align(horizon)[#h(0.3em) *#title*])]]
  }
}


#let thebig(title, icon: none, colour: rgb(0, 0, 0)) = {
  let icon = {
    if icon.len() > 6 {
      image(icon, width: 1.5em)
    } else {
      set text(font: "New Computer Modern", size: 1.5em)
      icon
    }
  }

  set align(center)
  show rect: set block(spacing: 0.6em)
  rect(width: 100%, stroke: (left: (paint: colour, thickness: 6pt), right: (paint: colour, thickness: 6pt), top: (paint: colour), bottom: (paint: colour)), radius: 10pt)[
  #rect(width: 100%, fill: colour.lighten(85%))[#icon]
    #rect(width: 100%, stroke: none)[#strong(text(title, size: 1.4em)) #v(0.3em)]
  ]
}


#let callout_question(title, body) = {callout(title, body, icon: "theme/blue_questionmark_icon.svg", colour: purple)}
#let callout_info(title, body) = {callout(title, body, icon: "theme/quarto-info.svg", colour: blue)}
#let callout_idea(title, body) = {callout(title, body, icon: "theme/quarto-lightbulb.svg", colour: green)}
#let callout_important(title, body) = {callout(title, body, icon: "theme/quarto-important.svg", colour: red)}
#let callout_warning(title, body) = {callout(title, body, icon: "theme/quarto-warning.svg", colour: orange)}
#let callout_caution(title, body) = {callout(title, body, icon: "theme/quarto-caution.svg", colour: rgb("#f0ad4e"))}
#let callout_skill(title, body) = {callout(title, body, icon: "💪", colour: rgb(yellow))}
#let callout_goal(title, body) = {callout(title, body, icon: "🎯", colour: rgb(red))}

#let thebig_question(title) = {thebig(title, icon: "theme/blue_questionmark_icon.svg", colour: purple)}
#let thebig_info(title) = {thebig(title, icon: "theme/quarto-info.svg", colour: blue)}
#let thebig_idea(title) = {thebig(title, icon: "theme/quarto-lightbulb.svg", colour: green)}
#let thebig_important(title) = {thebig(title, icon: "theme/quarto-important.svg", colour: red)}
#let thebig_warning(title) = {thebig(title, icon: "theme/quarto-warning.svg", colour: orange)}
#let thebig_caution(title) = {thebig(title, icon: "theme/quarto-caution.svg", colour: rgb("#f0ad4e"))}
#let thebig_goal(title) = {thebig(title, icon: "🎯", colour: rgb(red))}

#let r0 = `r0`
#let r1 = `r1`
#let r2 = `r2`
#let r3 = `r3`
#let r4 = `r4`
#let r5 = `r5`
#let r6 = `r6`
#let r7 = `r7`
#let r8 = `r8`
#let r9 = `r9`
#let r10 = `r10`
#let r11 = `r11`
#let r12 = `r12`
#let r13 = `r13`
#let r14 = `r14`
#let r15 = `r15`
#let lr = `lr`
#let pc = `pc`
#let sp = `sp`
#let psr = `psr`

#let light(body) = [
  #set text(gray)
  #body
]
