#import "/content/_prelude.typ": *

#show: page.with(
  title: "Publications",
  description: "A showcase of my publications and research work.",
  section: "pages",
  toc: false,
)

#bibtex-export(
  "/content/publications/publications.bib",
  filename: "r-portfolio-publications.bib",
)

#text(lang: "en")[
  #bibliography(
    "/content/publications/publications.bib",
    style: "/content/publications/association-for-computational-linguistics-blinky.csl",
    title: none,
    full: true,
  )
]
