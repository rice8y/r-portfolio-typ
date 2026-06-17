#import "site.typ": render-site
#import "content/_generated.typ": profile, posts, projects, favorite-sections, favorites, awards-body, publications-body, public-assets

#let site-url = sys.inputs.at("site_url", default: "")

#let emit-page(path, title, page, slug: "") = document(path, title: [#title])[
  #render-site(
    profile: profile,
    posts: posts,
    projects: projects,
    favorite-sections: favorite-sections,
    favorites: favorites,
    awards-body: awards-body,
    publications-body: publications-body,
    page: page,
    slug: slug,
    site-url: site-url,
  )
]

#let emit-asset(item) = asset(item.out, read(item.source, encoding: none))

#emit-page("index.html", "Home", "home")
#emit-page("blog/index.html", "Blog", "blog")
#emit-page("projects/index.html", "Projects", "projects")
#emit-page("awards/index.html", "Awards", "awards")
#emit-page("publications/index.html", "Publications", "publications")
#emit-page("favorites/index.html", "Favorites", "favorites")
#emit-page("404.html", "404", "not-found")

#for post in posts {
  emit-page("blog/" + post.slug + "/index.html", post.title, "post", slug: post.slug)
}

#for project in projects {
  emit-page("projects/" + project.slug + "/index.html", project.title, "project", slug: project.slug)
}

#for favorite in favorites {
  emit-page("favorites/" + favorite.slug + "/index.html", favorite.title, "favorite", slug: favorite.slug)
}

#for item in public-assets {
  emit-asset(item)
}
