#let collections = (
  projects: collection.with(schema: (
    languages: array(str),
    links: array(object((label: str, url: url))),
    has_math: optional(bool),
  )),
  favorites: collection.with(schema: (
    links: optional(array(object((label: str, url: url)))),
    plain_body: optional(str),
  )),
)
