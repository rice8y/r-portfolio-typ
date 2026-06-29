#import "rportfolio.typ": render-page

#let render(site: (:), page: (:), pages: (), taxonomies: (:), body) = {
  render-page(site: site, page: page, pages: pages, taxonomies: taxonomies, body)
}
