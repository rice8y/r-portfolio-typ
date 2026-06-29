# r-Portfolio

A Typage-powered implementation of `r-portfolio`. The site keeps articles and project pages in Typst, renders them with Typst HTML export, and publishes the generated static files from `dist/`.

## Requirements

- Rust and Cargo
- Typst `0.15.0` or newer
- Typage `0.24.2` or newer

Install Typage with:

```bash
cargo install typage --locked
```

## Commands

```bash
typage build --force --jobs 0
typage serve --live-reload --jobs 0
typage doctor
typage clean
```

`typage serve --live-reload --jobs 0` builds the site, serves it at `http://127.0.0.1:1111`, watches source files, and injects live reload into served HTML.

The Vercel build uses the same static output model:

```bash
typage build --force --jobs 0
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
- `templates/` contains the Typage templates and the r-Portfolio visual system.
- `static/` contains files copied as-is into the generated site.
- `scripts/import-r-portfolio.mjs` imports content from the previous Typst-native implementation.
- `dist/` is generated output for local preview and static deployment.

## Content

Each content file uses TOML front matter followed by Typst markup:

```typ
---
title = "Example"
description = "Short description."
date = "2026-05-23"
section = "blog"
toc = false

[extra]
kind = "post"
reading_time = "1 min read"
published_raw = "2026/05/23"
---

#import "/content/_prelude.typ": *

Write Typst content here.
```

Project entries use `section = "projects"` and can provide project-specific metadata through `[extra]`, including `languages`, `links`, `published_raw`, and `updated_raw`.

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

Generated files and local-only files are ignored by Git:

```txt
.typage/
dist/
.vercel/
push.sh
```
