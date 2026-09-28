#import "@preview/basic-resume:0.2.9": resume

#let render(site: (:), document: (:), pages: (), body) = {
  set page(numbering: "1 / 1", number-align: right)
  show: resume.with(
    author: "Eito Yoneyama",
    email: site.extra.at("email", default: ""),
    github: "github.com/rice8y",
    paper: "a4",
    font: ("New Computer Modern", "Noto Serif CJK JP"),
    font-size: 10pt,
    accent-color: "#222222",
    lang: "ja",
  )
  set std.document(title: document.title)
  set par(justify: false, leading: 0.55em)
  set heading(numbering: none)
  show heading.where(level: 3): set text(size: 10pt, weight: "bold")

  include "/content/_cv.typ"

  let interests = site.extra.at("interests", default: ())
  if interests.len() > 0 [
    == Interests
    #interests.join(" / ")
  ]

}
