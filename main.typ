#import "site.typ": render-site
#import "content/_generated.typ": profile, posts, projects, favorite-sections, favorites, awards-body, publications-body

#let page = sys.inputs.at("page", default: "home")
#let slug = sys.inputs.at("slug", default: "")
#let site-url = sys.inputs.at("site_url", default: "")

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
