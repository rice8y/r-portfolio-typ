// Writer-facing content helpers.
// Content files should import this module and write ordinary Typst markup.
// Use these small components only when HTML-specific behavior is needed.

#let _elem(tag, attrs: (:), body) = html.elem(tag, attrs: attrs, body)
#let _void(tag, attrs: (:)) = html.elem(tag, attrs: attrs)

#let _pdf-src(src) = if type(src) == str and src.starts-with("/") { "/static" + src } else { src }

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
  body,
) = make-entry(
  title: title,
  description: description,
  published: published,
  updated: updated,
  image: image,
  draft: draft,
  links: links,
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
  body,
) = make-entry(
  title: title,
  description: description,
  published: published,
  updated: updated,
  image: image,
  draft: draft,
  links: links,
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

#let bibtex-entry-data(bib-path, filename: "publication.bib") = context {
  if target() == "html" {
    let bib-source = read(bib-path)
    _elem("div", attrs: (
      class: "publication-bib-data",
      "data-bib-tools": "true",
      "data-bib-filename": filename,
    ))[
      #_elem("script", attrs: (type: "application/x-bibtex", class: "publication-bib-source"))[#bib-source]
    ]
  }
}

#let img(src, alt: "", caption: none, class: "") = {
  context {
    if target() == "html" {
      let attrs = if class == "" {
        (src: src, alt: alt)
      } else {
        (src: src, alt: alt, class: class)
      }
      let image = _void("img", attrs: attrs)
      if caption == none {
        image
      } else {
        _elem("figure")[#image #_elem("figcaption")[#caption]]
      }
    } else if type(src) == str and src.starts-with("http") {
      if alt == "" { link(src)[#src] } else { link(src)[#alt] }
    } else if caption == none {
      image(_pdf-src(src), width: 100%)
    } else {
      figure(image(_pdf-src(src), width: 100%), caption: caption)
    }
  }
}

#let link-preview(title: none, description: "", link: none, image: none) = context {
  if target() == "html" {
    _elem("a", attrs: (
      class: if image == none { "link-preview" } else { "link-preview has-image" },
      href: link,
      target: "_blank",
      rel: "noreferrer",
      title: link,
    ))[
      #if image != none {
        _elem("span", attrs: (class: "link-preview-thumb"))[
          #_void("img", attrs: (
            src: image,
            alt: "",
            onerror: "this.closest('.link-preview')?.classList.remove('has-image'); this.closest('.link-preview-thumb')?.remove();",
          ))
        ]
      }
      #_elem("span", attrs: (class: "link-preview-copy"))[
        #_elem("span", attrs: (class: "link-preview-title"))[#title]
        #_elem("span", attrs: (class: "link-preview-desc"))[#description]
        #_elem("span", attrs: (class: "link-preview-url"))[#link]
      ]
    ]
  } else {
    block(inset: 8pt, stroke: luma(190))[
      #if title != none { strong[#title] }
      #if description != "" [
        #linebreak()
        #description
      ]
      #if link != none [
        #linebreak()
        #link
      ]
    ]
  }
}

#let instagram(url) = context {
  if target() == "html" {
    [
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
  } else {
    link(url)[Instagram]
  }
}

#let data-table(headers: (), rows: ()) = context {
  if target() == "html" {
    _elem("div", attrs: (class: "table-scroll"))[
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
  } else {
    let cols = if headers.len() > 0 { headers.len() } else if rows.len() > 0 { rows.first().len() } else { 1 }
    let cells = ()
    if headers.len() > 0 {
      cells.push(table.header(..headers.map(head => strong(head))))
    }
    for row in rows {
      for cell in row {
        cells.push(cell)
      }
    }
    table(columns: cols, ..cells)
  }
}

#let image-row(images) = context {
  if target() == "html" {
    _elem("div", attrs: (class: "image-row"))[
      #for item in images {
        _void("img", attrs: (src: item.src, alt: item.at("alt", default: "")))
      }
    ]
  } else if images.len() > 0 {
    grid(
      columns: images.len(),
      gutter: 0.75em,
      ..images.map(item => image(_pdf-src(item.src), width: 100%)),
    )
  }
}

#let details(summary: "Details", body) = context {
  if target() == "html" {
    _elem("details")[
      #_elem("summary")[#summary]
      #body
    ]
  } else {
    block(inset: 8pt, stroke: luma(190))[
      #strong[#summary]
      #linebreak()
      #body
    ]
  }
}

#let blockquote(body) = context {
  if target() == "html" {
    _elem("blockquote")[#body]
  } else {
    block(inset: 8pt, stroke: luma(190))[#body]
  }
}
