#import "/content/_prelude.typ": *

=== 国内会議

#bibliography(
  "/content/publications/domestic.bib",
  style: "/content/publications/enlp-domestic.csl",
  title: none,
  full: true,
)

=== 国際会議

#text(lang: "en")[
  #bibliography(
    "/content/publications/international.bib",
    style: "/content/publications/association-for-computational-linguistics-blinky.csl",
    title: none,
    full: true,
  )
]
