// Writer-facing content helpers.
// Content files should import this module and write ordinary Typst markup.
// Use these small components only when HTML-specific behavior is needed.

#let _elem(tag, attrs: (:), body) = html.elem(tag, attrs: attrs, body)
#let _void(tag, attrs: (:)) = html.elem(tag, attrs: attrs)

#let _pad2(value) = {
  let s = str(value)
  if s.len() == 1 { "0" + s } else { s }
}

#let display-date(value) = {
  if value == none {
    none
  } else {
    let parts = str(value).split("/")
    if parts.len() < 3 {
      str(value)
    } else {
      let months = (
        "01": "Jan", "02": "Feb", "03": "Mar", "04": "Apr",
        "05": "May", "06": "Jun", "07": "Jul", "08": "Aug",
        "09": "Sep", "10": "Oct", "11": "Nov", "12": "Dec",
      )
      let year = parts.at(0)
      let month = months.at(_pad2(parts.at(1)), default: parts.at(1))
      let day = _pad2(parts.at(2))
      month + " " + day + ", " + year
    }
  }
}

#let make-entry(
  title: none,
  description: "",
  published: none,
  updated: none,
  image: none,
  draft: false,
  links: (),
  reading-time: "1 min read",
  body,
) = (
  title: title,
  description: description,
  published: published,
  updated: updated,
  image: image,
  draft: draft,
  published_date: display-date(published),
  updated_date: display-date(updated),
  reading_time: reading-time,
  links: links,
  body: body,
)

#let with-route(entry, collection, slug) = entry + (collection: collection, slug: slug)

#let post(
  title: none,
  description: "",
  published: none,
  updated: none,
  image: none,
  draft: false,
  links: (),
  reading-time: "1 min read",
  body,
) = make-entry(
  title: title,
  description: description,
  published: published,
  updated: updated,
  image: image,
  draft: draft,
  links: links,
  reading-time: reading-time,
  body,
)

#let project(
  title: none,
  description: "",
  published: none,
  updated: none,
  image: none,
  draft: false,
  languages: (),
  repo-url: none,
  links: (),
  reading-time: "1 min read",
  body,
) = {
  let all-links = if repo-url == none { links } else { ((label: "GitHub", url: repo-url),) + links }
  make-entry(
    title: title,
    description: description,
    published: published,
    updated: updated,
    image: image,
    draft: draft,
    links: all-links,
    reading-time: reading-time,
    body,
  ) + (languages: languages)
}

#let favorite(
  title: none,
  description: "",
  published: none,
  updated: none,
  image: none,
  draft: false,
  links: (),
  reading-time: "1 min read",
  body,
) = make-entry(
  title: title,
  description: description,
  published: published,
  updated: updated,
  image: image,
  draft: draft,
  links: links,
  reading-time: reading-time,
  body,
)

#let page(
  title: none,
  description: "",
  image: none,
  draft: false,
  body,
) = (
  title: title,
  description: description,
  image: image,
  draft: draft,
  body: body,
)

#let img(src, alt: "", caption: none) = {
  let image = _void("img", attrs: (src: src, alt: alt))
  if caption == none {
    image
  } else {
    _elem("figure")[#image #_elem("figcaption")[#caption]]
  }
}

#let link-preview(title: none, description: "", link: none, image: none) = _elem("a", attrs: (
  class: if image == none { "link-preview" } else { "link-preview has-image" },
  href: link,
  target: "_blank",
  rel: "noreferrer",
  title: link,
))[
  #if image != none {
    _elem("span", attrs: (class: "link-preview-thumb"))[
      #_void("img", attrs: (src: image, alt: ""))
    ]
  }
  #_elem("span", attrs: (class: "link-preview-copy"))[
    #_elem("span", attrs: (class: "link-preview-title"))[#title]
    #_elem("span", attrs: (class: "link-preview-desc"))[#description]
    #_elem("span", attrs: (class: "link-preview-url"))[#link]
  ]
]

#let instagram(url) = [
  #_elem("blockquote", attrs: (
    class: "instagram-media instagram-lite",
    "data-instgrm-permalink": url,
    "data-instgrm-version": "14",
  ))[
    #_elem("p")[Instagram embed]
    #_elem("a", attrs: (href: url, target: "_blank", rel: "noreferrer"))[View this post on Instagram]
  ]
  #_elem("script", attrs: (async: "true", src: "//www.instagram.com/embed.js"))[]
]

#let data-table(headers: (), rows: ()) = _elem("div", attrs: (class: "table-scroll"))[
  #_elem("table")[
    #if headers.len() > 0 {
      _elem("thead")[
        #_elem("tr")[
          #for head in headers { _elem("th")[#head] }
        ]
      ]
    }
    #_elem("tbody")[
      #for row in rows {
        _elem("tr")[
          #for cell in row { _elem("td")[#cell] }
        ]
      }
    ]
  ]
]

#let image-row(images) = _elem("div", attrs: (class: "image-row"))[
  #for item in images {
    _void("img", attrs: (src: item.src, alt: item.at("alt", default: "")))
  }
]

#let details(summary: "Details", body) = _elem("details")[
  #_elem("summary")[#summary]
  #body
]

#let blockquote(body) = _elem("blockquote")[#body]
