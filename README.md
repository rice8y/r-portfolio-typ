# r-Portfolio

A Typst HTML exporter implementation of [`r-portfolio`](https://github.com/rice8y/r-portfolio). It keeps the source content in Typst, generates static multi-page HTML, and deploys as ordinary static files.

## What this repository does

- Uses Typst `0.14.x` experimental HTML export for page rendering.
- Builds clean URLs such as `/blog/<slug>/` and `/projects/<slug>/`.
- Keeps content authoring simple with one `index.typ` per entry.
- Supports implementation-language badges and filtering on the Projects page.
- Supports light, dark, and system themes.
- Ships as static assets in `dist/`, suitable for Vercel and other static hosts.

## Requirements

- Node.js `20` or newer
- Typst `0.14.2` or newer

The build can install the official Typst CLI into `.bin/` when `typst` is not available on `PATH`. This is used by Vercel builds as well.

## Commands

```bash
just build
just dev
```

Without `just`:

```bash
npm run build
npm run dev
```

`just dev` serves `dist/` at `http://localhost:4321`. Press `Ctrl+C` or `q` to stop. The wrapper script temporarily disables terminal `ISIG` so `Ctrl+C` is handled inside the dev server instead of being reported by `just` as an interrupted recipe.

Dev builds include entries marked `draft: true` so unfinished content can be previewed locally. Normal `just build` / Vercel builds exclude drafts.

## Build pipeline

The build is intentionally static and deterministic:

1. `scripts/build.mjs` scans content entries under `content/blog`, `content/projects`, and `content/favorites`.
2. Source entries are normalized into `content/_build/**/index.typ`.
3. `content/_generated.typ` imports all generated entries and exposes route data to `main.typ`.
4. Each route is compiled with Typst:

   ```bash
   typst compile --features html --format html --input page=<route> main.typ dist/<route>/index.html
   ```

5. `public/` is copied to `dist/`.
6. If `SITE_URL` is set, `sitemap.xml`, `robots.txt`, and RSS feeds are generated.

Generated files are ignored by Git:

```txt
content/_build/
content/_generated.typ
dist/
.bin/
```

## Content structure

Each page-like content item is a Typst file:

```txt
content/
  profile.typ
  prelude.typ
  blog/<slug>/index.typ
  projects/<slug>/index.typ
  favorites/<slug>/index.typ
  awards/index.typ
  publications/index.typ
```

The slug is derived from the directory path. For example:

```txt
content/projects/molchemist/index.typ
→ /projects/molchemist/
```

A blog post looks like this:

````typ
#import "/content/prelude.typ": *

#let entry = post(
  title: "My new post",
  description: "Short card and meta description.",
  published: "2026/05/22",
  draft: false,
)[
  Write ordinary Typst markup here.

  == Section

  - Typst lists work.
  - Inline `code` works.
  - Typst strong text uses *stars*.

  ```typ
  #let x = 1
  ```
]
````

A project entry looks like this:

```typ
#import "/content/prelude.typ": *

#let entry = project(
  title: "my-project",
  description: "Project description.",
  languages: ("Typst", "Rust"),
  published: "2026/05/22",
  draft: false,
  repo-url: "https://github.com/user/repo",
  links: (
    (label: "Docs", url: "https://example.com"),
  ),
)[
  Project body.

  #img("/images/projects/my-project/screenshot.png", alt: "Screenshot")
]
```

`languages` accepts multiple values and is used for the Projects page filter and language badges on project cards. Badges are rendered as Shields.io SVGs with official Simple Icons logos where available. When omitted or empty, the project is treated as `Other`.


## Draft entries

Posts, projects, and favorites can be marked as drafts:

```typ
#let entry = post(
  title: "Work in progress",
  description: "Draft-only preview content.",
  published: "2026/05/23",
  draft: true,
)[
  This page is visible in dev builds only.
]
```

Draft behavior:

- `just dev` includes drafts and shows a `Draft` badge on cards and article pages.
- `just build` excludes drafts from generated routes, lists, sitemap, and RSS feeds.
- `RPORTFOLIO_INCLUDE_DRAFTS=1 just build` can be used when a static preview build should include drafts.
- Blog drafts do not load Giscus comments, even when previewed locally.

## RSS feeds

When `SITE_URL` is set, the build generates RSS feeds for blog posts and projects:

```txt
dist/rss.xml
dist/blog/rss.xml
dist/projects/rss.xml
```

`rss.xml` is a combined feed for blog posts and projects. `blog/rss.xml` and `projects/rss.xml` are collection-specific feeds. Feed items are generated from the `title`, `description`, and `published` metadata in each entry.

The UI exposes RSS in two places:

- the global feed is linked from the footer;
- collection-specific feeds are linked from the Blog and Projects page headings.

## Writer-facing helpers

`content/prelude.typ` provides small components so article files do not need to call `html.elem(...)` directly:

```typ
#img("/path/to/image.png", alt: "Alt text")
#link-preview(
  title: "Title",
  description: "Description",
  link: "https://example.com",
  image: "/image.png",
)
#instagram("https://www.instagram.com/p/.../")
#data-table(headers: ("Name", "Description"), rows: (("foo", "bar"),))
#details(summary: "Details")[...]
#image-row(((src: "/a.png", alt: "A"), (src: "/b.png", alt: "B")))
```

## Rendering architecture

- `main.typ` is the Typst entry point. It receives the route through `--input page=...` and delegates to `site.typ`.
- `site.typ` contains the HTML layout functions, route switch, cards, project language badges/filter UI, article layout, header, footer, RSS links, and OGP/Twitter metadata.
- `assets/site.css` defines the visual system. It is inlined into every page through `read(...)`, so no CSS bundler is required.
- The visual system follows the Astro source: sans-serif UI text uses an Inter-first stack and article paragraphs use a Lora-first serif stack. Inter/Lora are self-hosted from `public/fonts/` and preloaded in `site.typ`, mirroring the original Astro build.
- Typst HTML export can attach font styles to generated leaf spans. `assets/site.css` resets those spans to inherit the component font so the final DOM keeps the Astro-like typography.
- Light-mode list cards use a white translucent surface over `bg-stone-100`, with `border-black/15`-like borders and a slightly brighter hover state.
- `assets/site.js` handles theme switching, favicon switching, reveal animation, code-copy buttons, language switching, back-to-top behavior, and the footer collapse animation.
- `assets/giscus.js` synchronizes the Giscus theme with the current site theme.

## Theme and favicon behavior

The site supports three theme modes:

- Light
- Dark
- System

Theme preference is stored in `localStorage`. The favicon is switched by `assets/site.js` between `favicon-light.svg` and `favicon-dark.svg`, so it follows the selected site theme rather than only the OS preference.

## Vercel deployment

This repository includes `vercel.json`:

```json
{
  "installCommand": "npm install",
  "buildCommand": "npm run vercel-build",
  "outputDirectory": "dist",
  "cleanUrls": true,
  "trailingSlash": true
}
```

Deploy steps:

1. Import the repository into Vercel.
2. Keep the framework preset as “Other” or “Static”.
3. Set the output directory to `dist` if Vercel does not read it automatically.
4. Set `SITE_URL` to your production URL to generate canonical URLs, sitemap, robots, and RSS feeds.

Example environment variable:

```bash
SITE_URL=https://portfolio.example.com
```

## Notes

- Typst HTML export is experimental. The build targets Typst `0.14.2` and avoids the unavailable `bundle` feature.
- Public assets, including self-hosted fonts in `public/fonts/`, are copied from `public/` to `dist/`.
- `content/_build/` and `content/_generated.typ` are implementation details and should not be edited directly.


## Fonts

The site uses Inter for UI and Lora for prose paragraphs, matching the original Astro theme. The fonts are requested through Google Fonts at runtime; no font binaries are committed to this repository.

## License

This project is licensed under the MIT License. See [`LICENSE`](./LICENSE).

This project is inspired by and partially ported from [Astro Nano](https://github.com/markhorn-dev/astro-nano), a portfolio and blog theme for Astro created by Mark Horn. Portions of the visual design, layout structure, theme-switching behavior, and interaction ideas are based on or derived from Astro Nano.

Astro Nano is licensed under the MIT License. See [`THIRD_PARTY_NOTICES.md`](./THIRD_PARTY_NOTICES.md) for details.