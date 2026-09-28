#show: page.with(
  title: "Home",
  description: "A personal portfolio and blog for sharing research, projects, publications, and notes.",
  section: "pages",
  toc: false,
)

#let _publication-bibliography-deps = (
  read("publications/domestic.bib"),
  read("publications/international.bib"),
  read("_home_publications.typ"),
  read("publications/domestic.csl"),
  read("publications/international.csl"),
)

// Track the partial and helper used by the home template for incremental builds.
#let _experience-deps = (
  read("_home_experience.typ"),
  read("_prelude.typ"),
)
