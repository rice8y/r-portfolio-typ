#show: page.with(
  title: "Home",
  description: "A personal portfolio and blog for sharing research, projects, publications, and notes.",
  section: "pages",
  toc: false,
)

#let _publication-bibliography-deps = (
  read("publications/domestic.bib"),
  read("publications/international.bib"),
)
