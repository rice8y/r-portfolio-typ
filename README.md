# r-Portfolio

A personal portfolio built with [Typage](https://github.com/rice8y/typage) and Typst.

## Setup

Requires Rust 1.92+, Node.js 22+, and Noto Serif CJK JP for Japanese PDFs. Typage 0.2.1 includes Typst 0.15.1.

```bash
cargo install typage --version 0.2.1 --locked
```

## Commands

```bash
typage serve --live-reload --jobs 0  # Preview at http://127.0.0.1:1111
typage build --jobs 0               # Build into dist/
typage doctor                      # Validate configuration and content
```

Builds generate HTML, per-page PDFs, `print.pdf`, and `cv.pdf`. Add `--force` for a full rebuild.

## Editing

| Content | Location |
| --- | --- |
| Site settings, navigation, contact details | `config.toml` |
| Blog and project pages | `content/blog/`, `content/projects/` |
| Publications | `content/publications/*.bib` |
| Experience and awards | `content/_home_experience.typ`, `content/_home_awards.typ` |
| CV content and layout | `content/_cv.typ`, `templates/cv.typ` |
| Shared helpers and schemas | `content/_prelude.typ`, `content/config.typ` |
| Static assets | `static/` |

Use existing pages as examples. Projects require a manually maintained `start_date: "YYYY-MM-DD"` in addition to their publication date.

For Experience, use level-three category headings and wrap entries in `#experience-group[...]`. Each `experience` requires `period` and `title`; `department` and `description` are optional. Experience, awards, and publications are shared with the CV.

## Deployment

Vercel uses `scripts/vercel-install.sh` and `vercel.json` to install Typage and fonts, build the site, and publish `dist/`.

Each build fetches GitHub language data for the Projects chart, weighted by code bytes. Set `GITHUB_TOKEN` or `GH_TOKEN` for authenticated API limits. Repositories returning 404 are excluded; other API errors fail the build.

## License

This project is distributed under the [MIT License](LICENSE). See [third-party notices](THIRD_PARTY_NOTICES.md) for dependencies and attribution.
