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
      #elem("div", attrs: (class: "footer-copy"))[© #profile.copyright_year | #elem("span", attrs: (id: "collapse-trigger"))[#profile.site_title]]
      #elem("div", attrs: (class: "theme-buttons collapse-target"))[
        #theme-button("light-theme-button", "Light theme", sun-icon())
        #theme-button("dark-theme-button", "Dark theme", moon-icon())
        #theme-button("system-theme-button", "System theme", system-icon())
      ]
    ]
  ]
  #elem("script", attrs: (src: "https://cdnjs.cloudflare.com/ajax/libs/matter-js/0.19.0/matter.min.js"))[]
]

#let head(profile, title, description, path, site-url: "", image: "/astro-nano.png") = elem("head")[
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
  #if site-url != "" {
    let canonical = site-url + site-path(path)
    void("link", attrs: (rel: "canonical", href: canonical))
    void("meta", attrs: (property: "og:url", content: canonical))
    void("meta", attrs: (property: "twitter:url", content: canonical))
    void("meta", attrs: (property: "og:image", content: site-url + image))
    void("meta", attrs: (property: "twitter:image", content: site-url + image))
  }
  #elem("title")[#full-title(profile, title)]
  #void("meta", attrs: (name: "title", content: full-title(profile, title)))
  #void("meta", attrs: (property: "og:type", content: "website"))
  #void("meta", attrs: (property: "og:title", content: full-title(profile, title)))
  #void("meta", attrs: (property: "og:description", content: description))
  #void("meta", attrs: (property: "twitter:card", content: "summary_large_image"))
  #void("meta", attrs: (property: "twitter:title", content: full-title(profile, title)))
  #void("meta", attrs: (property: "twitter:description", content: description))
  #void("link", attrs: (rel: "alternate", type: "application/rss+xml", title: profile.site_title, href: "/rss.xml"))
  #elem("script")[#site-js]
  #elem("style")[#site-css]
]

#let layout(profile, current, title, description, path, site-url: "", body) = elem("html", attrs: (lang: profile.lang))[
  #head(profile, title, description, path, site-url: site-url)
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

#let card-meta(entry) = elem("div", attrs: (class: "card-meta"))[
  #if entry.published_date != none { elem("span")[Published: #entry.published_date] }
  #if entry.updated_date != none { elem("span")[Updated: #entry.updated_date] }
]

#let card(entry, href) = elem("a", attrs: (href: href, class: "card", title: entry.description))[
  #elem("div", attrs: (class: "card-body"))[
    #elem("div", attrs: (class: "card-title"))[#entry.title]
    #card-meta(entry)
    #elem("div", attrs: (class: "card-summary", title: entry.description))[#entry.description]
  ]
  #icon-arrow-right()
]

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

#let article-page(profile, current, back-href, back-label, entry, collection, site-url: "") = layout(profile, current, entry.title, entry.description, collection + "/" + entry.slug, site-url: site-url)[
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
    #elem("section", attrs: (class: "animate stack-6"))[
      #section-title("Awards")
      #elem("article", attrs: (class: "prose"))[#awards-body]
    ]
    #elem("section", attrs: (class: "animate stack-6"))[
      #section-title("Publications")
      #elem("article", attrs: (class: "prose"))[#publications-body]
    ]
    #elem("section", attrs: (class: "animate stack-4"))[
      #elem("h5", attrs: (class: "section-title"))[Contact]
      #elem("ul", attrs: (class: "contact-list"))[
        #for social in profile.socials {
          elem("li")[#link(social.href, external: true)[#social.name] /]
        }
        #elem("li")[#elem("span", attrs: (class: "email-no-copy", "data-email": profile.email, "aria-label": "Email address hidden from copy"))[]]
      ]
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
    #elem("div", attrs: (class: "animate page-title"))[Blog]
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
    list-page(profile, "projects", "Projects", profile.projects_description, projects, "projects", site-url: site-url)
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
