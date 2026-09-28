#import "_prelude.typ": experience-group
#import "_home_publications.typ": publications

#let subsections(body) = {
  show heading.where(level: 3): it => block(above: 16pt, below: 7pt, sticky: true)[
    #text(size: 9pt, weight: "semibold", fill: luma(90))[#upper(it.body)]
  ]
  body
}

== Affiliation

*愛媛大学大学院理工学研究科*

理工学専攻 数理情報プログラム 自然言語処理研究室 / 修士1年

== Experience

#subsections[
  #include "_home_experience.typ"
]

== Awards

#include "_home_awards.typ"

== Publications

#subsections[
  #publications(group: experience-group)
]
