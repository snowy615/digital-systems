#let callout(title, body, icon: none, colour: rgb(0, 0, 0)) = {
  let icon = {
    if icon.len() > 6 {
      image(icon, width: 1.0em)
    } else {
      icon
    }
  }

  set rect(inset: 2.5pt)
  if body != [] {
    show rect: set block(spacing: 0.2em)
    
    rect(width: 100%, stroke: (left: (paint: colour, thickness: 4pt), right: (paint: colour), top: (paint: colour), bottom: (paint: colour)), radius: 4pt)[
      #rect(width: 100%, fill: colour.lighten(85%))[
        #grid(columns: (1.1em, 1fr), icon, align(horizon)[
          #h(0.3em) *#title*
        ])
      ]
      #rect(width: 100%, stroke: none)[#body]
    ]
  } else {
    rect(width: 100%, stroke: (left: (paint: colour, thickness: 4pt), right: (paint: colour), top: (paint: colour), bottom: (paint: colour)), radius: 4pt)[
    #rect(width: 100%, fill: colour.lighten(85%))[#grid(columns: (1.1em, 1fr), icon, align(horizon)[#h(0.3em) *#title*])]]
  }
}


#let thebig(title, icon: none, colour: rgb(0, 0, 0)) = {
  let icon = {
    if icon.len() > 2 {
      image(icon, width: 1.5em)
    } else {
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

#let callout_question(title, body) = {callout(title, body, icon: "callouts/blue_questionmark_icon.svg", colour: purple)}
#let callout_info(title, body) = {callout(title, body, icon: "callouts/quarto-info.svg", colour: blue)}
#let callout_idea(title, body) = {callout(title, body, icon: "callouts/quarto-lightbulb.svg", colour: green)}
#let callout_important(title, body) = {callout(title, body, icon: "callouts/quarto-important.svg", colour: red)}
#let callout_warning(title, body) = {callout(title, body, icon: "callouts/quarto-warning.svg", colour: orange)}
#let callout_caution(title, body) = {callout(title, body, icon: "callouts/quarto-caution.svg", colour: rgb("#f0ad4e"))}
#let callout_skill(title, body) = {callout(title, body, icon: "💪", colour: rgb(yellow))}

#let thebig_question(title) = {thebig(title, icon: "callouts/blue_questionmark_icon.svg", colour: purple)}
#let thebig_info(title) = {thebig(title, icon: "callouts/quarto-info.svg", colour: blue)}
#let thebig_idea(title) = {thebig(title, icon: "callouts/quarto-lightbulb.svg", colour: green)}
#let thebig_important(title) = {thebig(title, icon: "callouts/quarto-important.svg", colour: red)}
#let thebig_warning(title) = {thebig(title, icon: "callouts/quarto-warning.svg", colour: orange)}
#let thebig_caution(title) = {thebig(title, icon: "callouts/quarto-caution.svg", colour: rgb("#f0ad4e"))}