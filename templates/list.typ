#import "rportfolio.typ": render-list

#let render(site: (:), page: (:), pages: (), taxonomies: (:), body) = {
  render-list(site: site, page: page, pages: pages, taxonomies: taxonomies, body)
}
