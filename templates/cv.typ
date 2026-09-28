#import "@preview/basic-resume:0.2.9": resume, project, dates-helper

#let project-start-date(value) = {
  let parts = value.split("-")
  assert(parts.len() == 3, message: "Project start_date must use YYYY-MM-DD")
  datetime(year: int(parts.at(0)), month: int(parts.at(1)), day: int(parts.at(2)))
    .display("[month repr:short] [year]")
}

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

  let projects = pages.filter(entry => entry.section == "projects").sorted(key: entry => entry.start_date).rev()
  if projects.len() > 0 [
    #pagebreak()
    == Projects

    #for entry in projects {
      let links = entry.at("links", default: ())
      let repository = links.find(item => item.url.starts-with("https://github.com/"))
      let url = if repository != none { repository.url } else if links.len() > 0 { links.first().url } else { "" }
      let details = ()
      if entry.description != none and entry.description != "" {
        details.push([#entry.description])
      }
      let languages = entry.at("languages", default: ())
      if languages.len() > 0 {
        details.push([Built with #languages.join(", ", last: " and ").])
      }
      block(breakable: false, above: 10pt, below: 10pt)[
        #set par(spacing: 4pt, leading: 0.4em)
        #project(
          name: if url == "" { entry.title } else { link(url)[#entry.title] },
          role: "Maintainer",
          dates: dates-helper(start-date: project-start-date(entry.start_date), end-date: "Present"),
        )
        #if details.len() > 0 [
          #v(3pt)
          #text(size: 9.5pt, lang: "en")[
            #list(indent: 4pt, body-indent: 6pt, tight: true, ..details)
          ]
        ]
      ]
    }
  ]
}
