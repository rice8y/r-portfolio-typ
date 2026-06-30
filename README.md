# r-Portfolio

A Typage-powered implementation of `r-portfolio`. The site keeps articles and project pages in Typst, renders them with Typst HTML export, and publishes the generated static files from `dist/`.

## Requirements

- Rust `1.92` or newer and Cargo
- Typst `0.15.0` or newer
- Typage `0.1.2`

This site uses the combined PDF export added after the published `0.1.2` release.
Until that update is available on crates.io, build or install Typage from the local checkout:

```bash
cargo build --manifest-path ../typage/Cargo.toml
PATH="../typage/target/debug:$PATH" typage build --force --jobs 0
```

To install the local checkout into Cargo's bin directory:

```bash
cargo install --path ../typage --locked
```

## Commands

```bash
typage build --force --jobs 0
typage serve --live-reload --jobs 0
typage doctor
typage clean
```

`typage serve --live-reload --jobs 0` builds the site, serves it at `http://127.0.0.1:1111`, watches source files, and injects live reload into served HTML.
`typage build --force --jobs 0` also writes the combined print PDF to `dist/print.pdf` and page-level PDFs as `index.pdf` next to each content page.

The Vercel build uses the same static output model:

```bash
typage build --force --jobs 0
```

While the PDF-capable Typage build is unpublished, point the install step at an updated source checkout or branch:

```bash
TYPAGE_PATH=../typage bash scripts/vercel-install.sh
TYPAGE_GIT=https://github.com/rice8y/typage.git TYPAGE_BRANCH=feat/print-pdf bash scripts/vercel-install.sh
```

## Project Structure

```txt
config.toml
content/
templates/
static/
scripts/
dist/
```

- `config.toml` defines Typage settings, site metadata, navigation, feeds, and deployment scripts.
- `content/` contains Typst source pages and entries.
- `templates/` contains the Typage templates, the print PDF template, and the r-Portfolio visual system.
- `static/` contains files copied as-is into the generated site.
- `dist/` is generated output for local preview and static deployment.

## Content

Each content file uses Typst-native metadata followed by Typst markup:

```typ
#import "/content/_prelude.typ": *

#show: page.with(
  title: "Example",
  description: "Short description.",
  date: "2026-05-23",
  section: "blog",
  toc: false,
)

Write Typst content here.
```

Project entries use `#show: project.with(...)`, keep `section: "projects"` for the flat project listing, and declare project fields such as `languages` and `links` directly. Collection schemas live in `content/config.typ`.

Writer-facing helpers live in `content/_prelude.typ`, including:

```typ
#img("/path/to/image.png", alt: "Alt text")
#link-preview(
  title: "Title",
  description: "Description",
  link: "https://example.com",
  image: "/image.png",
)
#instagram("https://www.instagram.com/p/...")
#data-table(headers: ([Name], [Description]), rows: (([foo], [bar]),))
#details(summary: "Details")[...]
#image-row(((src: "/a.png", alt: "A"), (src: "/b.png", alt: "B")))
```

## Rendering

Typage reads `config.toml`, routes the files in `content/`, applies templates from `templates/`, copies `static/`, and writes the final site to `dist/`. The templates preserve the existing r-Portfolio experience, including theme switching, RSS links, project cards, article layouts, link previews, and Giscus theme synchronization.

`[[pdf_documents]]` in `config.toml` defines `print.pdf`. It combines Awards, Publications, Blog, and Projects in that order; Blog entries are listed explicitly so they are not interleaved with Projects by date, while `section_headings` keeps Blog and Projects as top-level PDF sections. `build_pdf = true` enables per-page PDFs, and the HTML footer exposes a compact PDF menu with full-site and current-page choices. HTML-only writing helpers in `content/_prelude.typ` provide PDF fallbacks so the same content can be used for both targets.

Generated files and local-only files are ignored by Git:

```txt
.typage/
dist/
.vercel/
push.sh
```

## License

This project is distributed under the MIT License. See `LICENSE` for details.

Third-party attribution and license notes are documented in `THIRD_PARTY_NOTICES.md`.
