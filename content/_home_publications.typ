#import "/content/_prelude.typ": *

#let publications(group: body => body) = {
  for section in (
    (title: "Domestic Conferences", name: "domestic", lang: "ja"),
    (title: "International Conferences", name: "international", lang: "en"),
  ) {
    heading(level: 3, section.title)
    let base = "/content/publications/" + section.name
    group[
      #set text(lang: section.lang)
      #bibliography(base + ".bib", style: base + ".csl", title: none, full: true)
    ]
  }
}

#publications()
