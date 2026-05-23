#import "/content/prelude.typ": *

#let entry = project(
  title: "new-project",
  description: "Short project description.",
  published: "2026/05/22",
  languages: ("Typst", "Rust"),
  repo-url: "https://github.com/user/repo",
  links: (
    (label: "Docs", url: "https://example.com"),
  ),
)[
Project body.

#img("/images/projects/new-project/screenshot.png", alt: "Screenshot")

| Feature | Status |
| --- | --- |
| Typst content | supported |
]
