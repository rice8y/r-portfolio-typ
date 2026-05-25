#import "/content/prelude.typ": *

#let entry = post(
  title: "New post",
  description: "Short summary shown in cards and metadata.",
  published: "2026/05/22",
  image: "/images/og/default.png",
  draft: false,
)[
Write naturally, almost like MDX/Markdown.

== Section

* Markdown-style bullet
* **Bold** and *italic* are normalized during build
* [External link](https://example.com)

> Blockquote text
]
