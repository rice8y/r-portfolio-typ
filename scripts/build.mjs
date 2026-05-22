import { spawnSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = join(dirname(fileURLToPath(import.meta.url)), "..");
const distDir = join(rootDir, "dist");
const publicDir = join(rootDir, "public");
const contentDir = join(rootDir, "content");
const generatedContentDir = join(contentDir, "_build");
const siteUrl = (process.env.SITE_URL || "").replace(/\/$/, "");
const localTypst = join(rootDir, ".bin", process.platform === "win32" ? "typst.exe" : "typst");
const typstCommand = process.env.TYPST || (existsSync(localTypst) ? localTypst : "typst");

function copyPublic() {
  if (!existsSync(publicDir)) return;
  for (const name of readdirSync(publicDir)) {
    cpSync(join(publicDir, name), join(distDir, name), { recursive: true });
  }
}

function walk(dir) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const name of readdirSync(dir)) {
    if (name === "_build" || name === "_templates") continue;
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) out.push(...walk(path));
    else out.push(path);
  }
  return out;
}

function toPosix(path) {
  return path.split(sep).join("/");
}

function slugForIndex(collection, file) {
  const rel = toPosix(relative(join(contentDir, collection), dirname(file)));
  return rel === "" ? "index" : rel;
}

function safeName(prefix, slug) {
  return `${prefix}_${slug}`.replace(/[^A-Za-z0-9_]/g, "_").replace(/^([0-9])/, "_$1");
}

function decodeTypString(raw) {
  try { return JSON.parse(`"${raw}"`); }
  catch { return raw.replace(/\\"/g, '"').replace(/\\\\/g, "\\"); }
}

function readMeta(file) {
  const src = readFileSync(file, "utf8");
  const get = (key) => {
    const m = src.match(new RegExp(`${key}:\\s*"((?:\\\\.|[^"\\\\])*)"`));
    return m ? decodeTypString(m[1]) : "";
  };
  return { title: get("title"), description: get("description"), published: get("published") };
}

function dateKey(value) {
  const [y = "0", m = "0", d = "0"] = String(value || "").split("/");
  return `${y.padStart(4, "0")}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
}

function scanCollection(collection) {
  return walk(join(contentDir, collection))
    .filter(file => file.endsWith(`${sep}index.typ`) || file.endsWith(`/index.typ`))
    .sort((a, b) => a.localeCompare(b))
    .map(file => ({ collection, slug: slugForIndex(collection, file), file, ...readMeta(file) }))
    .sort((a, b) => dateKey(b.published).localeCompare(dateKey(a.published)) || a.slug.localeCompare(b.slug));
}

function scanPage(name) {
  const file = join(contentDir, name, "index.typ");
  if (!existsSync(file)) throw new Error(`Missing content page: content/${name}/index.typ`);
  return { name, file, ...readMeta(file) };
}

function typString(value) {
  return JSON.stringify(String(value));
}

function protectInlineCode(line) {
  const codes = [];
  const text = line.replace(/`[^`]*`/g, (match) => {
    const token = `@@RPORTFOLIOCODE${codes.length}@@`;
    codes.push(match);
    return token;
  });
  return { text, codes };
}

function restoreInlineCode(line, codes) {
  return line.replace(/@@RPORTFOLIOCODE(\d+)@@/g, (_m, index) => codes[Number(index)] ?? _m);
}

function protectTypStrings(line) {
  const strings = [];
  const text = line.replace(/"(?:\\.|[^"\\])*"/g, (match) => {
    const token = `@@RPORTFOLIOSTR${strings.length}@@`;
    strings.push(match);
    return token;
  });
  return { text, strings };
}

function restoreTypStrings(line, strings) {
  return line.replace(/@@RPORTFOLIOSTR(\d+)@@/g, (_m, index) => strings[Number(index)] ?? _m);
}

function protectTypMath(line) {
  const maths = [];
  const text = line.replace(/\$(?:\\.|[^$\\])+\$/g, (match) => {
    const token = `@@RPORTFOLIOMATH${maths.length}@@`;
    maths.push(match);
    return token;
  });
  return { text, maths };
}

function restoreTypMath(line, maths) {
  return line.replace(/@@RPORTFOLIOMATH(\d+)@@/g, (_m, index) => maths[Number(index)] ?? _m);
}

function normalizeInlineMarkdown(line) {
  const protectedCode = protectInlineCode(line);
  let part = protectedCode.text;

  // Markdown image/link conveniences. Keep content files close to MDX while
  // emitting Typst expressions that the HTML exporter can compile.
  part = part.replace(/!\[([^\]]*)\]\(([^\s)]+)\)/g, (_m, alt, src) => `#img(${typString(src)}, alt: ${typString(alt)})`);
  part = part.replace(/(?<!!)\[([^\]]+)\]\(([^\s)]+)\)/g, (_m, text, url) => `#link(${typString(url)})[${text}]`);

  // Protect Typst string literals after the image/link expansion above.
  // This prevents filename/URL strings from being touched by inline markup
  // normalization.
  const protectedStrings = protectTypStrings(part);
  part = protectedStrings.text;

  const protectedMath = protectTypMath(part);
  part = protectedMath.text;

  // Convert Markdown/Typst-style star emphasis to explicit Typst strong.
  // The content files are intended to feel close to Typst markup, where
  // `*text*` means strong text. We also accept Markdown-style `**text**`
  // for authors coming from MDX. Inline code spans are protected first so
  // patterns such as `*`foo`* / *`bar`*` stay valid after conversion.
  part = part.replace(/\*\*([^\n]+?)\*\*/g, (_m, body) => `#strong[${body}]`);
  part = part.replace(/(^|[^*])\*([^*\n]+?)\*(?!\*)/g, (_m, pre, body) => `${pre}#strong[${body}]`);

  part = restoreTypMath(part, protectedMath.maths);
  part = restoreTypStrings(part, protectedStrings.strings);

  // A single Markdown-style shell variable such as $HOME or $BibCopMode is
  // not math. If the line has an odd number of unescaped dollars, protect
  // variable-looking occurrences as raw inline code.
  const dollars = part.match(/(^|[^\\])\$/g)?.length ?? 0;
  if (dollars % 2 === 1) {
    part = part.replace(/(^|[^\\])\$([A-Za-z_][A-Za-z0-9_]*)/g, (_m, pre, name) => `${pre}` + '`' + `$${name}` + '`');
  }

  return restoreInlineCode(part, protectedCode.codes);
}

function isMarkdownTableLine(line) {
  return /^\s*\|.*\|\s*$/.test(line);
}

function parseTableRow(line) {
  return line.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map(cell => cell.trim());
}

function isSeparatorRow(cells) {
  return cells.length > 0 && cells.every(cell => /^:?-{3,}:?$/.test(cell.trim()));
}

function tableCell(content) {
  return `[${normalizeInlineMarkdown(content)}]`;
}

function flushMarkdownTable(out, rows) {
  if (rows.length === 0) return;
  const parsed = rows.map(parseTableRow);
  if (parsed.length >= 2 && isSeparatorRow(parsed[1])) {
    const headers = parsed[0].map(tableCell).join(", ");
    const bodyRows = parsed.slice(2).map(row => `    (${row.map(tableCell).join(", ")},)`).join(",\n");
    out.push("#data-table(");
    out.push(`  headers: (${headers},),`);
    out.push("  rows: (");
    if (bodyRows) out.push(bodyRows + ",");
    out.push("  ),");
    out.push(")");
  } else {
    out.push(...rows.map(normalizeInlineMarkdown));
  }
}

function normalizeTypContent(src) {
  const lines = src.split(/\r?\n/);
  const out = [];
  const table = [];
  let fenceTicks = null;

  const flushTable = () => {
    flushMarkdownTable(out, table.splice(0, table.length));
  };

  const processContentLine = (original) => {
    if (isMarkdownTableLine(original)) {
      table.push(original);
      return;
    }

    flushTable();

    let line = original;

    // Markdown unordered lists are accepted in content files and materialized
    // as Typst lists in the generated import target.
    line = line.replace(/^(\s*)\*\s+/, "$1- ");

    // Markdown blockquotes become a small writer-facing component.
    const quote = line.match(/^\s*>\s?(.*)$/);
    if (quote) {
      out.push(`#blockquote[${normalizeInlineMarkdown(quote[1])}]`);
      return;
    }

    out.push(normalizeInlineMarkdown(line));
  };

  for (const original of lines) {
    const indent = original.match(/^\s*/)?.[0] ?? "";
    const trimmed = original.slice(indent.length);

    if (fenceTicks !== null) {
      const close = "`".repeat(fenceTicks);
      if (trimmed.startsWith(close)) {
        flushTable();
        out.push(indent + close);
        fenceTicks = null;

        // Some converted MDX files had lines like ```+ item. Split them into
        // a fence close followed by the intended list item.
        const rest = trimmed.slice(close.length);
        if (rest.trim().length > 0) processContentLine(indent + rest);
      } else {
        out.push(original);
      }
      continue;
    }

    const fenceOpen = trimmed.match(/^(`{3,})(.*)$/);
    if (fenceOpen) {
      flushTable();
      fenceTicks = fenceOpen[1].length;
      out.push(original);
      continue;
    }

    processContentLine(original);
  }

  flushTable();
  return out.join("\n");
}

function generatedImportPath(entry) {
  if (entry.collection) return `/content/_build/${entry.collection}/${entry.slug}/index.typ`;
  return `/content/_build/${entry.name}/index.typ`;
}

function materializeEntry(entry) {
  const rel = entry.collection ? join(entry.collection, ...entry.slug.split("/"), "index.typ") : join(entry.name, "index.typ");
  const out = join(generatedContentDir, rel);
  mkdirSync(dirname(out), { recursive: true });
  const source = readFileSync(entry.file, "utf8");
  writeFileSync(out, normalizeTypContent(source));
}

function materializeContent(content) {
  if (existsSync(generatedContentDir)) rmSync(generatedContentDir, { recursive: true, force: true });
  mkdirSync(generatedContentDir, { recursive: true });
  for (const entry of [...content.posts, ...content.projects, ...content.favorites, content.awards, content.publications]) {
    materializeEntry(entry);
  }
}

function generateContentManifest(content) {
  const lines = [
    "// Generated by scripts/build.mjs. Do not edit by hand.",
    "#import \"/content/prelude.typ\": with-route",
    "#import \"/content/profile.typ\": profile",
    "",
  ];

  const imports = [];
  for (const [prefix, entries] of [["blog", content.posts], ["project", content.projects], ["favorite", content.favorites]]) {
    for (const entry of entries) {
      const alias = safeName(prefix, entry.slug);
      entry.alias = alias;
      imports.push(`#import ${JSON.stringify(generatedImportPath(entry))} as ${alias}`);
    }
  }
  const pages = { awards: content.awards, publications: content.publications };
  for (const [name, page] of Object.entries(pages)) {
    const alias = `${name}_page`;
    page.alias = alias;
    imports.push(`#import ${JSON.stringify(generatedImportPath(page))} as ${alias}`);
  }
  lines.push(...imports, "");

  function tuple(name, entries, collectionName) {
    lines.push(`#let ${name} = (`);
    for (const entry of entries) {
      lines.push(`  with-route(${entry.alias}.entry, ${JSON.stringify(collectionName)}, ${JSON.stringify(entry.slug)}),`);
    }
    lines.push(")", "");
  }

  tuple("posts", content.posts, "blog");
  tuple("projects", content.projects, "projects");
  tuple("favorite-sections", content.favorites.filter(entry => !entry.slug.includes("/")), "favorites");
  tuple("favorites", content.favorites, "favorites");
  lines.push("#let awards-body = awards_page.entry.body");
  lines.push("#let publications-body = publications_page.entry.body");
  lines.push("");

  writeFileSync(join(contentDir, "_generated.typ"), lines.join("\n"));
}

function contentManifest() {
  const content = {
    posts: scanCollection("blog"),
    projects: scanCollection("projects"),
    favorites: scanCollection("favorites"),
    awards: scanPage("awards"),
    publications: scanPage("publications"),
  };
  materializeContent(content);
  generateContentManifest(content);
  return content;
}

function compile(route) {
  const output = join(distDir, route.out);
  mkdirSync(dirname(output), { recursive: true });
  const args = [
    "compile",
    "--features", "html",
    "--format", "html",
    "--input", `page=${route.page}`,
    "--input", `site_url=${siteUrl}`,
  ];
  if (route.slug) args.push("--input", `slug=${route.slug}`);
  args.push("main.typ", output);
  const res = spawnSync(typstCommand, args, { cwd: rootDir, stdio: "inherit" });
  if (res.error) throw res.error;
  if (res.status !== 0) throw new Error(`typst compile failed for ${route.out}`);
}

function writeText(path, body) {
  const out = join(distDir, path);
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, body);
}

function xmlEscape(s) {
  return String(s).replace(/[&<>\"]/g, ch => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch]));
}

function makeSitemap(routes) {
  if (!siteUrl) return;
  const entries = routes
    .filter(route => route.out !== "404.html")
    .map(route => route.out.replace(/index\.html$/, ""))
    .map(route => new URL(route, siteUrl.endsWith("/") ? siteUrl : siteUrl + "/").toString())
    .map(loc => `  <url><loc>${xmlEscape(loc.endsWith("/") ? loc : loc + "/")}</loc></url>`)
    .join("\n");
  writeText("sitemap.xml", `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${entries}\n</urlset>\n`);
  writeText("robots.txt", `User-agent: *\nAllow: /\nSitemap: ${siteUrl}/sitemap.xml\n`);
}

function makeRss(posts) {
  if (!siteUrl) return;
  const items = posts.map(post => {
    const url = `${siteUrl}/blog/${post.slug}/`;
    return `  <item>\n    <title>${xmlEscape(post.title)}</title>\n    <link>${xmlEscape(url)}</link>\n    <guid>${xmlEscape(url)}</guid>\n    <description>${xmlEscape(post.description)}</description>\n  </item>`;
  }).join("\n");
  writeText("rss.xml", `<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0">\n<channel>\n  <title>r-Portfolio</title>\n  <link>${xmlEscape(siteUrl)}</link>\n  <description>r-Portfolio posts</description>\n${items}\n</channel>\n</rss>\n`);
}

export function build() {
  if (existsSync(distDir)) rmSync(distDir, { recursive: true, force: true });
  mkdirSync(distDir, { recursive: true });
  const content = contentManifest();
  copyPublic();

  const routes = [
    { page: "home", out: "index.html" },
    { page: "blog", out: "blog/index.html" },
    { page: "projects", out: "projects/index.html" },
    { page: "awards", out: "awards/index.html" },
    { page: "publications", out: "publications/index.html" },
    { page: "favorites", out: "favorites/index.html" },
    { page: "not-found", out: "404.html" },
    ...content.posts.map(post => ({ page: "post", slug: post.slug, out: `blog/${post.slug}/index.html` })),
    ...content.projects.map(project => ({ page: "project", slug: project.slug, out: `projects/${project.slug}/index.html` })),
    ...content.favorites.map(favorite => ({ page: "favorite", slug: favorite.slug, out: `favorites/${favorite.slug}/index.html` })),
  ];

  for (const route of routes) compile(route);
  makeSitemap(routes);
  makeRss(content.posts);
  console.log(`\nGenerated ${routes.length} HTML pages in dist/`);
  if (!siteUrl) console.log("Set SITE_URL=https://example.com to emit sitemap.xml, robots.txt, and rss.xml.");
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { build(); }
  catch (error) { console.error(error.message || error); process.exit(1); }
}
