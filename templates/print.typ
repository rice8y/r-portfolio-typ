// Print template for Typage combined PDF documents.

#let render(site: (:), document: (:), pages: (), body) = {
  set page(paper: "a4", margin: (x: 22mm, y: 24mm), numbering: "1")
  set text(size: 10pt, lang: site.lang)
  set par(justify: true, leading: 0.65em)

  show link: underline
  show heading.where(level: 1): it => [
    #pagebreak(weak: true)
    #block(above: 0pt, below: 1.1em)[
      #text(size: 18pt, weight: "bold")[#it.body]
    ]
  ]
  show heading.where(level: 2): set text(size: 14pt, weight: "bold")
  show heading.where(level: 3): set text(size: 12pt, weight: "bold")

  align(center)[
    #v(18%)
    #text(size: 28pt, weight: "bold")[#document.title]

    #if document.description != none [
      #v(1em)
      #text(size: 11pt)[#document.description]
    ]

    #v(1em)
    #text(size: 9pt)[#site.title]
  ]

  pagebreak()
  outline(title: [Contents])
  pagebreak()

  body
}
