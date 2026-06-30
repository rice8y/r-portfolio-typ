#show: project.with(
  title: "CaleTZ",
  description: "A Typst package for visualizing Calabi-Yau manifolds using CeTZ 3D drawing primitives.",
  date: "2025-10-22",
  section: "projects",
  toc: false,
  languages: ("Typst", "Rust"),
  links: (
    (label: "GitHub", url: "https://github.com/rice8y/caletz"),
    (label: "Typst Universe", url: "https://typst.app/universe/package/caletz"),
  ),
)

#import "/content/_prelude.typ": *

#strong[CaleTZ] is a Typst package for visualizing #strong[Calabi-Yau manifolds] using #strong[CeTZ] 3D drawing primitives.
It generates colorful, smooth 3D surfaces with adjustable parameters, making it easy to explore complex geometries directly in Typst.

#image-row((
  (src: "/images/projects/caletz/for_readme01.png", alt: "for_readme01"),
  (src: "/images/projects/caletz/for_readme02.png", alt: "for_readme02"),
  (src: "/images/projects/caletz/for_readme03.png", alt: "for_readme03"),
))

== Installation

=== Using `just`

First, install `just` if you don’t have it yet:

```bash
cargo install just
```

Then, install the CaleTZ package:

```bash
git clone https://github.com/rice8y/caletz.git
cd caletz
just install
```

This installs the package locally to Typst’s package directory.

=== Using `typkg`

First, install #link("https://github.com/rice8y/typkg")[`typkg`] if you don’t have it yet:

```bash
cargo install --git https://github.com/rice8y/typkg.git
```

Then, install the CaleTZ package:

```bash
typkg install https://github.com/rice8y/caletz.git
```

This will also install the package locally for Typst usage.

== Usage Example

```typ
#import "@local/caletz:0.2.0": calabi-yau

#set page(width: auto, height: auto, margin: 1cm)
#calabi-yau(
  power: 3,
  angle: 0.4,
  subdivisions: 20
)
```

=== Parameters

- `power`: Degree of the manifold (e.g., 3). Must be a positive integer.
- `angle`: Adjusts the combination of z-coordinates; smaller values flatten the surface.
- `subdivisions`: Controls mesh density; higher values give smoother surfaces.
- `colormap`: Optional, default `"jet"`. Can be `"viridis"`, `"plasma"`, `"cool"`, or `"hot"`.
- `scale-factor`: Optional, default `3.0`. Scales the entire mesh.
- `rotation`: Optional, default `(30deg, 45deg, 0deg)`. Rotates the 3D view.

#blockquote[For best results, use a high `subdivisions` value, but note it increases computation.]

== License

This project is distributed under the MIT License. See #link("https://raw.githubusercontent.com/rice8y/caletz/main/LICENSE")[LICENSE].
