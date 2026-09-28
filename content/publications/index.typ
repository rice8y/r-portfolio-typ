#import "/content/_prelude.typ": *

#show: page.with(
  title: "Publications",
  description: "A showcase of my publications and research work.",
  section: "pages",
  toc: false,
)

#let _publication-bibliography-deps = (
  read("domestic.bib"),
  read("international.bib"),
  read("domestic.csl"),
  read("international.csl"),
  read("/content/_prelude.typ"),
)

=== Domestic Conferences

#bibtex-entry-data(
  "/content/publications/domestic.bib",
  filename: "r-portfolio-domestic-publications.bib",
)

#bibliography(
  "/content/publications/domestic.bib",
  style: "/content/publications/domestic.csl",
  title: none,
  full: true,
)

=== International Conferences

#bibtex-entry-data(
  "/content/publications/international.bib",
  filename: "r-portfolio-international-publications.bib",
)

#text(lang: "en")[
  #bibliography(
    "/content/publications/international.bib",
    style: "/content/publications/international.csl",
    title: none,
    full: true,
  )
]
