#let conf(
  title: none,
  date: "Hilary Term 2026",
  authors: (),
  doc,
) = {
  show link: set text(fill: rgb(0, 0, 255), weight: "bold")
  show link: it => underline(it)
  // Set and show rules from before.

  {{set align(center)
  text(23pt, title, weight: "bold")
  text("\n")
  v(0.5em)
image("microbit.png", height: 10.0em)
  text(date)
  }

  for a in authors [
    #a.name #h(1fr) #a.role \
  ]
  }

  set par(justify: true)

  show raw.where(block: true): it => {
  pad(left: 2em, it)
  }

  set list(indent: 0.5em)
  set enum(indent: 0.5em)

  outline()

  // set heading(numbering: (..counter) => [#{counter.pos().enumerate().map(a => {if a.at(0) == 0 {a.at(1) - 1} else {a.at(1)}}).map(str).join(".") + "."}])
  // counter(heading).update(0)
  set heading(numbering: "1.1.")

  doc

  // set align(justify)
  // columns(2, doc)
}