# r-Portfolio

A Typage-powered implementation of `r-portfolio`. The site keeps articles and project pages in Typst, renders them with Typst HTML export, and publishes the generated static files from `dist/`.

## Requirements

- Rust `1.92` or newer and Cargo
- Typst `0.15.0` or newer
- Typage `0.1.3`

Install Typage from crates.io:

```bash
cargo install typage --version 0.1.3 --locked
```

For Typage development, you can still point the build at a local checkout:

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

By default, Vercel installs Typage `0.1.3` from crates.io. For testing an unreleased Typage change, point the install step at a source checkout or branch:

```bash
TYPAGE_PATH=../typage bash scripts/vercel-install.sh
TYPAGE_GIT=https://github.com/rice8y/typage.git TYPAGE_BRANCH=main bash scripts/vercel-install.sh
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

The Projects root page displays a descending language bar chart above the footer. The `post_build` hook runs `scripts/build-project-languages.mjs` (Node.js 22+) to read freshly generated Typage metadata, fetch the GitHub languages API for each unique project repository, and embed the chart in `dist/projects/index.html`. Percentages use summed code bytes, not repository averages. The browser makes no API requests and needs no JavaScript to display the chart. Every build fetches fresh data; repositories returning 404 are excluded with a visible note, while other failed or rate-limited requests fail the build. Set `GITHUB_TOKEN` or `GH_TOKEN` in the build environment for authenticated API limits; tokens are never included in the output. Run `node scripts/test-project-languages.mjs` to check aggregation.

Publications are registered in `content/publications/domestic.bib` and `content/publications/international.bib`. Domestic entries use the ENLP-inspired CSL, international entries use the ACL/Blinky-derived CSL, and the publications page exposes per-entry BibTeX clipboard copy and `.bib` download controls.

The home-only Experience section is maintained in `content/_home_experience.typ`. Add categories with `=== Internship`, `=== Teaching Assistant`, or other level-three headings, then add `experience` entries beneath them. This partial does not generate a dedicated page. `period` and `title` are required; `department` and `description` are optional. Text or Typst content (including links) can be used for each field.

For PDF output, `experience` uses `basic-resume`'s `work` component: `title` maps to `title`, `period` to `dates`, and `department` to `company`. Optional descriptions follow the entry. HTML retains the responsive layout with a vertical divider.

Wrap each category's entries in `#experience-group[...]` beneath its heading. The CV renders the group with a subtle left rule and indentation; the heading stays outside the rule. HTML renders the entries without an additional wrapper.

```typ
#experience(
  period: "2026.08 - 2026.09",
  title: "Company name or assistant role",
  department: "Research team",
  description: [Research and development.],
)
```

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

The footer's CV link opens `/cv.pdf`, generated by Typage's `pdf_documents` configuration on each applicable build. `templates/cv.typ` uses `@preview/basic-resume:0.2.9`; edit `content/_cv.typ` for the CV structure and affiliation. Experience, awards, and publications reuse the home partials, and interests and email come from `config.toml`. No separate HTML CV page is generated. The `[extra].cv_path` setting controls the footer link. Local builds need Noto Serif CJK JP for Japanese text. Vercel installs the Regular and Bold fonts from Noto CJK's pinned `Serif2.003` release and supplies them through `TYPST_FONT_PATHS`.

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
