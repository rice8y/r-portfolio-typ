// r-portfolio Typst HTML port
// This file implements the Astro layout/components with Typst's HTML exporter.

#let site-css = read("assets/site.css")
#let site-js = read("assets/site.js")
#let giscus-js = read("assets/giscus.js")

#let elem(tag, attrs: (:), body) = html.elem(tag, attrs: attrs, body)
#let void(tag, attrs: (:)) = html.elem(tag, attrs: attrs)

#let site-path(path) = if path == "" { "/" } else { "/" + path + "/" }
#let entry-path(collection, slug) = "/" + collection + "/" + slug + "/"
#let post-path(post) = entry-path("blog", post.slug)
#let project-path(project) = entry-path("projects", project.slug)
#let favorite-path(favorite) = entry-path("favorites", favorite.slug)

#let full-title(profile, title) = if title == "Home" { profile.site_title } else { title + " | " + profile.site_title }

#let as-array(value) = if type(value) == dictionary { (value,) } else { value }

#let nav-link(item, current) = {
  let attrs = if item.key == current {
    (href: item.href, "aria-current": "page")
  } else {
    (href: item.href)
  }
  elem("a", attrs: attrs)[#item.label]
}

#let link(href, external: false, underline: true, body) = {
  let cls = if underline { "link" } else { "link no-underline" }
  let attrs = if external {
    (href: href, class: cls, target: "_blank", rel: "noreferrer")
  } else {
    (href: href, class: cls)
  }
  elem("a", attrs: attrs)[#body]
}

#let rss-link(href, label: "RSS") = elem("a", attrs: (href: href, class: "rss-link", type: "application/rss+xml"))[#label]

#let icon-arrow-right(class: "card-arrow") = elem("svg", attrs: (
  xmlns: "http://www.w3.org/2000/svg",
  viewBox: "0 0 24 24",
  class: class,
  "stroke-width": "2",
  "stroke-linecap": "round",
  "stroke-linejoin": "round",
))[#void("line", attrs: (x1: "5", y1: "12", x2: "19", y2: "12", class: "card-arrow-line"))#void("polyline", attrs: (points: "12 5 19 12 12 19", class: "card-arrow-head"))]

#let icon-arrow-left() = elem("svg", attrs: (
  xmlns: "http://www.w3.org/2000/svg",
  viewBox: "0 0 24 24",
  "stroke-width": "2",
  "stroke-linecap": "round",
  "stroke-linejoin": "round",
))[#void("line", attrs: (x1: "5", y1: "12", x2: "19", y2: "12", class: "arrow-line"))#void("polyline", attrs: (points: "12 5 5 12 12 19", class: "arrow-head"))]

#let sun-icon() = elem("svg", attrs: (xmlns: "http://www.w3.org/2000/svg", width: "18", height: "18", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round"))[#void("circle", attrs: (cx: "12", cy: "12", r: "5"))#void("line", attrs: (x1: "12", y1: "1", x2: "12", y2: "3"))#void("line", attrs: (x1: "12", y1: "21", x2: "12", y2: "23"))#void("line", attrs: (x1: "4.22", y1: "4.22", x2: "5.64", y2: "5.64"))#void("line", attrs: (x1: "18.36", y1: "18.36", x2: "19.78", y2: "19.78"))#void("line", attrs: (x1: "1", y1: "12", x2: "3", y2: "12"))#void("line", attrs: (x1: "21", y1: "12", x2: "23", y2: "12"))#void("line", attrs: (x1: "4.22", y1: "19.78", x2: "5.64", y2: "18.36"))#void("line", attrs: (x1: "18.36", y1: "5.64", x2: "19.78", y2: "4.22"))]
#let moon-icon() = elem("svg", attrs: (xmlns: "http://www.w3.org/2000/svg", width: "18", height: "18", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round"))[#void("path", attrs: (d: "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"))]
#let system-icon() = elem("svg", attrs: (xmlns: "http://www.w3.org/2000/svg", width: "18", height: "18", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round"))[#void("rect", attrs: (x: "2", y: "3", width: "20", height: "14", rx: "2", ry: "2"))#void("line", attrs: (x1: "8", y1: "21", x2: "16", y2: "21"))#void("line", attrs: (x1: "12", y1: "17", x2: "12", y2: "21"))]

#let theme-button(id, label, icon) = elem("button", attrs: (id: id, class: "theme-button", "aria-label": label))[#icon]

#let header(profile, current) = elem("header")[
  #elem("div", attrs: (class: "container header-container"))[
    #elem("div", attrs: (class: "header-row"))[
      #elem("a", attrs: (href: "/", class: "site-title"))[#profile.site_title]
      #elem("nav", attrs: (class: "primary", "aria-label": "Primary"))[
        #let last = profile.nav.len() - 1
        #for pair in profile.nav.enumerate() {
          nav-link(pair.at(1), current)
          if pair.at(0) < last { elem("span", attrs: ("aria-hidden": "true"))[/] }
        }
      ]
    ]
  ]
]

#let back-to-top() = elem("button", attrs: (id: "back-to-top", class: "back-link"))[#icon-arrow-left()#elem("div", attrs: (class: "back-link-text"))[Back to top]]
#let back-to-prev(href, label) = elem("a", attrs: (id: "back-to-prev", href: href, class: "back-link"))[#icon-arrow-left()#elem("div", attrs: (class: "back-link-text"))[#label]]

#let footer(profile) = elem("footer", attrs: (class: "animate"))[
  #elem("div", attrs: (class: "container"))[
    #elem("div", attrs: (class: "footer-inner"))[
      #elem("div", attrs: (class: "back-to-top-wrap"))[#back-to-top()]
    ]
    #elem("div", attrs: (class: "footer-row"))[
      #elem("div", attrs: (class: "footer-copy"))[© #profile.copyright_year | #elem("span", attrs: (id: "collapse-trigger"))[#profile.site_title] | #rss-link("/rss.xml")]
      #elem("div", attrs: (class: "theme-buttons collapse-target"))[
        #theme-button("light-theme-button", "Light theme", sun-icon())
        #theme-button("dark-theme-button", "Dark theme", moon-icon())
        #theme-button("system-theme-button", "System theme", system-icon())
      ]
    ]
  ]
  #elem("script", attrs: (src: "https://cdnjs.cloudflare.com/ajax/libs/matter-js/0.19.0/matter.min.js"))[]
]

#let is-absolute-url(value) = {
  let s = str(value)
  s.starts-with("http://") or s.starts-with("https://")
}

#let absolute-url(site-url, value) = {
  let s = str(value)
  if s == "" {
    ""
  } else if is-absolute-url(s) {
    s
  } else if site-url == "" {
    s
  } else if s.starts-with("/") {
    site-url + s
  } else {
    site-url + "/" + s
  }
}

#let head(profile, title, description, path, site-url: "", image: none, kind: "website") = {
  let page-title = full-title(profile, title)
  let page-image = if image == none { profile.at("image", default: "/astro-nano.png") } else { image }
  let og-image = if page-image == none { none } else { absolute-url(site-url, page-image) }
  let twitter-card = if og-image == none { "summary" } else { "summary_large_image" }
  let page-url = if site-url == "" { none } else { site-url + site-path(path) }

  elem("head")[
    #void("meta", attrs: (charset: "utf-8"))
    #void("meta", attrs: (name: "viewport", content: "width=device-width, initial-scale=1"))
    #void("meta", attrs: (name: "description", content: description))
    #void("meta", attrs: (name: "generator", content: "Typst HTML exporter"))
    #void("meta", attrs: (name: "color-scheme", content: "light dark"))
    #void("link", attrs: (rel: "preconnect", href: "https://fonts.googleapis.com"))
    #void("link", attrs: (rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: "anonymous"))
    #void("link", attrs: (rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Inter:wght@400;600&family=Lora:wght@400;600&display=swap"))
    #void("link", attrs: (id: "site-favicon", rel: "icon", type: "image/svg+xml", href: "/favicon-light.svg"))
    #void("meta", attrs: (name: "theme-color", content: "#f5f5f4", media: "(prefers-color-scheme: light)"))
    #void("meta", attrs: (name: "theme-color", content: "#1c1917", media: "(prefers-color-scheme: dark)"))
    #if page-url != none {
      void("link", attrs: (rel: "canonical", href: page-url))
      void("meta", attrs: (property: "og:url", content: page-url))
      void("meta", attrs: (property: "twitter:url", content: page-url))
    }
    #elem("title")[#page-title]
    #void("meta", attrs: (name: "title", content: page-title))
    #void("meta", attrs: (property: "og:site_name", content: profile.site_title))
    #void("meta", attrs: (property: "og:type", content: kind))
    #void("meta", attrs: (property: "og:title", content: page-title))
    #void("meta", attrs: (property: "og:description", content: description))
    #void("meta", attrs: (property: "twitter:card", content: twitter-card))
    #void("meta", attrs: (property: "twitter:title", content: page-title))
    #void("meta", attrs: (property: "twitter:description", content: description))
    #if og-image != none {
      void("meta", attrs: (property: "og:image", content: og-image))
      void("meta", attrs: (property: "twitter:image", content: og-image))
    }
    #void("link", attrs: (rel: "alternate", type: "application/rss+xml", title: profile.site_title + " Feed", href: "/rss.xml"))
    #void("link", attrs: (rel: "alternate", type: "application/rss+xml", title: profile.site_title + " Blog Feed", href: "/blog/rss.xml"))
    #void("link", attrs: (rel: "alternate", type: "application/rss+xml", title: profile.site_title + " Projects Feed", href: "/projects/rss.xml"))
    #elem("script")[#site-js]
    #elem("style")[#site-css]
  ]
}

#let layout(profile, current, title, description, path, site-url: "", image: none, kind: "website", body) = elem("html", attrs: (lang: profile.lang))[
  #head(profile, title, description, path, site-url: site-url, image: image, kind: kind)
  #elem("body")[
    #header(profile, current)
    #elem("main")[
      #elem("div", attrs: (class: "container"))[#body]
    ]
    #footer(profile)
  ]
]

#let section-title(title, href: none, label: none) = elem("div", attrs: (class: "section-head"))[
  #elem("h5", attrs: (class: "section-title"))[#title]
  #if href != none {
    link(href)[#if label == none { "See all" } else { label }]
  }
]

#let page-head(title, rss-href: none, rss-label: "RSS") = elem("div", attrs: (class: "page-head"))[
  #elem("div", attrs: (class: "animate page-title"))[#title]
  #if rss-href != none { rss-link(rss-href, label: rss-label) }
]

#let card-meta(entry) = elem("div", attrs: (class: "card-meta"))[
  #if entry.published_date != none { elem("span")[Published: #entry.published_date] }
  #if entry.updated_date != none { elem("span")[Updated: #entry.updated_date] }
]

#let language-shield-src(language) = {
  let shields = (
    "All": "https://img.shields.io/badge/All-6b7280?style=flat",
    "Typst": "https://img.shields.io/badge/Typst-239dad?style=flat&logo=typst&logoColor=white",
    "Rust": "https://img.shields.io/badge/Rust-000000?style=flat&logo=rust&logoColor=white",
    "Python": "https://img.shields.io/badge/Python-3776ab?style=flat&logo=python&logoColor=white",
    "Perl": "https://img.shields.io/badge/Perl-39457e?style=flat&logo=perl&logoColor=white",
    "Shell": "https://img.shields.io/badge/Shell-4eaa25?style=flat&logo=gnubash&logoColor=white",
    "TeX": "https://img.shields.io/badge/TeX-008080?style=flat&logo=latex&logoColor=white",
    "Lua": "https://img.shields.io/badge/Lua-2c2d72?style=flat&logo=lua&logoColor=white",
    "Julia": "https://img.shields.io/badge/Julia-9558b2?style=flat&logo=julia&logoColor=white",
    "JavaScript": "https://img.shields.io/badge/JavaScript-f7df1e?style=flat&logo=javascript&logoColor=000000",
    "TypeScript": "https://img.shields.io/badge/TypeScript-3178c6?style=flat&logo=typescript&logoColor=white",
    "HTML": "https://img.shields.io/badge/HTML-e34f26?style=flat&logo=html5&logoColor=white",
    "CSS": "https://img.shields.io/badge/CSS-663399?style=flat&logo=css&logoColor=white",
    "C": "https://img.shields.io/badge/C-659ad2?style=flat&logo=c&logoColor=white",
    "C++": "https://img.shields.io/badge/C%2B%2B-00599c?style=flat&logo=cplusplus&logoColor=white",
    "C#": "https://img.shields.io/badge/C%23-512bd4?style=flat&logo=sharp&logoColor=white",
    "Go": "https://img.shields.io/badge/Go-00add8?style=flat&logo=go&logoColor=white",
    "Java": "https://img.shields.io/badge/Java-e76f00?style=flat&logo=openjdk&logoColor=white",
    "Kotlin": "https://img.shields.io/badge/Kotlin-7f52ff?style=flat&logo=kotlin&logoColor=white",
    "Swift": "https://img.shields.io/badge/Swift-f05138?style=flat&logo=swift&logoColor=white",
    "Ruby": "https://img.shields.io/badge/Ruby-cc342d?style=flat&logo=ruby&logoColor=white",
    "R": "https://img.shields.io/badge/R-276dc3?style=flat&logo=r&logoColor=white",
    "Dart": "https://img.shields.io/badge/Dart-0175c2?style=flat&logo=dart&logoColor=white",
    "Scala": "https://img.shields.io/badge/Scala-dc322f?style=flat&logo=scala&logoColor=white",
    "OCaml": "https://img.shields.io/badge/OCaml-ec6813?style=flat&logo=ocaml&logoColor=white",
    "Node.js": "https://img.shields.io/badge/Node.js-5fa04e?style=flat&logo=nodedotjs&logoColor=white",
    "Astro": "https://img.shields.io/badge/Astro-bc52ee?style=flat&logo=astro&logoColor=white",
    "Other": "https://img.shields.io/badge/Other-6b7280?style=flat",
  )
  shields.at(str(language), default: "https://img.shields.io/badge/Other-6b7280?style=flat")
}

#let entry-languages(entry) = {
  let languages = entry.at("languages", default: ())
  if languages == none or languages.len() == 0 {
    ("Other",)
  } else {
    languages
  }
}

#let join-languages(languages) = {
  let out = ""
  for pair in languages.enumerate() {
    if pair.at(0) > 0 { out += "||" }
    out += str(pair.at(1))
  }
  out
}

#let language-badge(language) = elem("span", attrs: (class: "language-badge", "data-language": str(language), "aria-label": str(language)))[
  #void("img", attrs: (class: "language-shield", src: language-shield-src(language), alt: str(language), loading: "lazy", decoding: "async"))
]

#let language-badges(entry) = {
  let languages = entry-languages(entry)
  if languages.len() > 0 {
    elem("span", attrs: (class: "language-badges", "aria-label": "Implementation languages"))[
      #for language in languages { language-badge(language) }
    ]
  }
}

#let project-languages(projects) = {
  let out = ()
  for project in as-array(projects) {
    for language in entry-languages(project) {
      if not (language in out) { out.push(language) }
    }
  }
  out
}

#let project-filter(projects) = {
  let languages = project-languages(projects)
  if languages.len() > 0 {
    elem("div", attrs: (class: "project-filter animate", "aria-label": "Filter projects by implementation language"))[
      #elem("button", attrs: ("type": "button", class: "project-filter-button is-active", "data-language-filter": "all"))[#language-badge("All")]
      #for language in languages {
        elem("button", attrs: ("type": "button", class: "project-filter-button", "data-language-filter": str(language)))[#language-badge(language)]
      }
    ]
  }
}

#let card(entry, href) = {
  let is-project = entry.at("collection", default: "") == "projects"
  let languages = if is-project { entry-languages(entry) } else { () }
  let attrs = if is-project {
    (href: href, class: "card", title: entry.description, "data-project-card": "true", "data-languages": join-languages(languages))
  } else {
    (href: href, class: "card", title: entry.description)
  }
  elem("a", attrs: attrs)[
    #elem("div", attrs: (class: "card-body"))[
      #elem("div", attrs: (class: "card-title-row"))[
        #elem("div", attrs: (class: "card-title"))[#entry.title]
        #if is-project { language-badges(entry) }
      ]
      #card-meta(entry)
      #elem("div", attrs: (class: "card-summary", title: entry.description))[#entry.description]
    ]
    #icon-arrow-right()
  ]
}

#let card-list(entries, collection, limit: none) = {
  let items = as-array(entries)
  let shown = if limit == none { items } else { items.slice(0, calc.min(limit, items.len())) }
  elem("ul", attrs: (class: "card-list"))[
    #if shown.len() == 0 { elem("li")[No entries yet.] }
    #for entry in shown {
      elem("li")[#card(entry, entry-path(collection, entry.slug))]
    }
  ]
}

#let entry-year(entry) = entry.published.split("/").at(0)

#let group-posts(posts) = {
  let entries = as-array(posts)
  let years = ()
  for post in entries {
    let year = entry-year(post)
    if not (year in years) {
      years.push(year)
    }
  }

  let groups = ()
  for year in years {
    let items = ()
    for post in entries {
      if entry-year(post) == year {
        items.push(post)
      }
    }
    groups.push((year: year, items: items))
  }
  groups
}

#let blog-groups-list(posts) = elem("div", attrs: (class: "stack-4"))[
  #for group in group-posts(posts) {
    elem("section", attrs: (class: "animate stack-4"))[
      #elem("div", attrs: (class: "section-title"))[#group.year]
      #card-list(group.items, "blog")
    ]
  }
]

#let giscus-block() = elem("div", attrs: (class: "animate", style: "margin-top: 3.5rem;"))[
  #elem("script", attrs: (
    src: "https://giscus.app/client.js",
    "data-repo": "rice8y/r-portfolio",
    "data-repo-id": "R_kgDOPmTTJw",
    "data-category": "Announcements",
    "data-category-id": "DIC_kwDOPmTTJ84C25yk",
    "data-mapping": "pathname",
    "data-strict": "0",
    "data-reactions-enabled": "1",
    "data-emit-metadata": "0",
    "data-input-position": "bottom",
    "data-theme": "light",
    "data-lang": "ja",
    crossorigin: "anonymous",
    async: "true",
  ))[]
  #elem("script")[#giscus-js]
]

#let entry-links(entry) = {
  if entry.links.len() > 0 {
    elem("nav", attrs: (class: "animate entry-links"))[
      #let last = entry.links.len() - 1
      #for pair in entry.links.enumerate() {
        link(pair.at(1).url, external: true)[#pair.at(1).label]
        if pair.at(0) < last { elem("span")[/] }
      }
    ]
  }
}

#let article-page(profile, current, back-href, back-label, entry, collection, site-url: "") = layout(profile, current, entry.title, entry.description, collection + "/" + entry.slug, site-url: site-url, image: entry.at("image", default: none), kind: "article")[
  #elem("div", attrs: (class: "animate"))[#back-to-prev(back-href, back-label)]
  #elem("div", attrs: (class: "article-header stack-1"))[
    #elem("div", attrs: (class: "animate article-meta-line"))[
      #if entry.published_date != none { elem("span")[Published: #entry.published_date] }
      #if entry.updated_date != none { elem("span")[Updated: #entry.updated_date] }
      #if entry.reading_time != none {
        elem("span", attrs: (class: "article-meta-dot", "aria-hidden": "true"))[•]
        elem("span")[#entry.reading_time]
      }
    ]
    #elem("div", attrs: (class: "animate article-title"))[#entry.title]
    #entry-links(entry)
  ]
  #elem("article", attrs: (class: "animate prose"))[#entry.body]
  #if collection == "blog" {
    giscus-block()
  }
]

#let find-by-slug(entries, slug) = {
  let found = none
  for entry in as-array(entries) {
    if entry.slug == slug { found = entry }
  }
  found
}

#let home-page(profile, posts, projects, awards-body, publications-body, site-url: "") = layout(profile, "", "Home", profile.description, "", site-url: site-url)[
  #elem("h2", attrs: (class: "animate page-title home-title"))[About me]
  #elem("div", attrs: (class: "stack-16 home-stack"))[
    #elem("section", attrs: (class: "about-section"))[
      #elem("article", attrs: (class: "about-text stack-4"))[
        #elem("p", attrs: (class: "animate lang-ja block"))[#elem("b")[氏名:] 米山 瑛人#void("br")#elem("b")[所属:] 愛媛大学大学院理工学研究科理工学専攻数理情報プログラム 自然言語処理研究室#void("br")#elem("b")[学年:] 修士1年]
        #elem("p", attrs: (class: "animate lang-en hidden"))[#elem("b")[Name:] Eito Yoneyama#void("br")#elem("b")[Affiliation:] Natural Language Processing Lab, Mathematical and Information Science Program, Graduate School of Science and Engineering, Ehime University#void("br")#elem("b")[Grade:] Master’s Student (M1)]
      ]
    ]
    #elem("section", attrs: (class: "animate stack-6"))[
      #section-title("Latest posts", href: "/blog/", label: "See all posts")
      #card-list(posts, "blog", limit: profile.num_posts_on_homepage)
    ]
    #elem("section", attrs: (class: "animate stack-6"))[
      #section-title("Recent projects", href: "/projects/", label: "See all projects")
      #card-list(projects, "projects", limit: profile.num_projects_on_homepage)
    ]
    #elem("section", attrs: (class: "animate stack-4"))[
      #section-title("Awards")
      #elem("article", attrs: (class: "prose home-compact-prose"))[#awards-body]
    ]
    #elem("section", attrs: (class: "animate stack-4"))[
      #section-title("Publications")
      #elem("article", attrs: (class: "prose home-compact-prose"))[#publications-body]
    ]
    #elem("section", attrs: (class: "animate stack-4"))[
      #elem("h5", attrs: (class: "section-title"))[Contact]
      #elem("ul", attrs: (class: "contact-list"))[
        #for social in profile.socials {
          elem("li")[#link(social.href, external: true)[#social.name] /]
        }
        #elem("li")[#rss-link("/rss.xml") /]
        #elem("li")[#elem("span", attrs: (class: "email-no-copy", "data-email": profile.email, "aria-label": "Email address hidden from copy"))[]]
      ]
    ]
  ]
]

#let projects-page(profile, projects, site-url: "") = layout(profile, "projects", "Projects", profile.projects_description, "projects", site-url: site-url)[
  #elem("div", attrs: (class: "stack-10"))[
    #page-head("Projects", rss-href: "/projects/rss.xml")
    #elem("div", attrs: (class: "stack-4"))[
      #project-filter(projects)
      #card-list(projects, "projects")
      #elem("p", attrs: (class: "project-filter-empty hidden"))[No projects match this language.]
    ]
  ]
]

#let list-page(profile, current, title, description, entries, collection, site-url: "") = layout(profile, current, title, description, current, site-url: site-url)[
  #elem("div", attrs: (class: "stack-10"))[
    #elem("div", attrs: (class: "animate page-title"))[#title]
    #card-list(entries, collection)
  ]
]

#let blog-page(profile, posts, site-url: "") = layout(profile, "blog", "Blog", profile.blog_description, "blog", site-url: site-url)[
  #elem("div", attrs: (class: "stack-10"))[
    #page-head("Blog", rss-href: "/blog/rss.xml")
    #blog-groups-list(posts)
  ]
]

#let simple-body-page(profile, current, title, description, body, site-url: "") = layout(profile, current, title, description, current, site-url: site-url)[
  #elem("div", attrs: (class: "stack-10"))[
    #elem("div", attrs: (class: "animate page-title"))[#title]
    #elem("article", attrs: (class: "animate prose"))[#body]
  ]
]

#let not-found-page(profile, site-url: "") = layout(profile, "", "404", "Page not found", "404", site-url: site-url)[
  #elem("div", attrs: (class: "stack-4"))[
    #elem("h1", attrs: (class: "page-title"))[404]
    #elem("p")[Page not found.]
    #link("/")[Back home]
  ]
]

#let render-site(
  profile: none,
  posts: (),
  projects: (),
  favorite-sections: (),
  favorites: (),
  awards-body: [],
  publications-body: [],
  page: "home",
  slug: "",
  site-url: "",
) = {
  if page == "home" {
    home-page(profile, posts, projects, awards-body, publications-body, site-url: site-url)
  } else if page == "blog" {
    blog-page(profile, posts, site-url: site-url)
  } else if page == "post" {
    let post = find-by-slug(posts, slug)
    if post == none { not-found-page(profile, site-url: site-url) } else { article-page(profile, "blog", "/blog/", "Back to blog", post, "blog", site-url: site-url) }
  } else if page == "projects" {
    projects-page(profile, projects, site-url: site-url)
  } else if page == "project" {
    let project = find-by-slug(projects, slug)
    if project == none { not-found-page(profile, site-url: site-url) } else { article-page(profile, "projects", "/projects/", "Back to projects", project, "projects", site-url: site-url) }
  } else if page == "favorites" {
    list-page(profile, "favorites", "Favorites", profile.favorites_description, favorite-sections, "favorites", site-url: site-url)
  } else if page == "favorite" {
    let favorite = find-by-slug(favorites, slug)
    if favorite == none { not-found-page(profile, site-url: site-url) } else { article-page(profile, "favorites", "/favorites/", "Back to favorites", favorite, "favorites", site-url: site-url) }
  } else if page == "awards" {
    simple-body-page(profile, "awards", "Awards", profile.awards_description, awards-body, site-url: site-url)
  } else if page == "publications" {
    simple-body-page(profile, "publications", "Publications", profile.publications_description, publications-body, site-url: site-url)
  } else if page == "not-found" {
    not-found-page(profile, site-url: site-url)
  } else {
    not-found-page(profile, site-url: site-url)
  }
}
