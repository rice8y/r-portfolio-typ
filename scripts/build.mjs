import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
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
const ogpCacheFile = join(rootDir, ".cache", "ogp.json");
const enableOgpFetch = process.env.OGP_FETCH !== "0";
const ogpFetchTimeoutMs = Number(process.env.OGP_FETCH_TIMEOUT_MS || 8000);
const includeDrafts = process.env.RPORTFOLIO_INCLUDE_DRAFTS === "1" || process.env.INCLUDE_DRAFTS === "1";


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

function scanPublicAssets() {
  return walk(publicDir)
    .filter(file => statSync(file).isFile())
    .map(file => {
      const rel = toPosix(relative(publicDir, file));
      return { out: rel, source: `/public/${rel}` };
    })
    .sort((a, b) => a.out.localeCompare(b.out));
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

function entryArgsSource(src) {
  const start = src.indexOf("#let entry");
  if (start === -1) return src;
  const open = src.indexOf("(", start);
  if (open === -1) return src.slice(start);
  const close = findMatchingParen(src, open);
  return close === -1 ? src.slice(start) : src.slice(open + 1, close);
}

function readMeta(file) {
  const src = readFileSync(file, "utf8");
  const metaSrc = entryArgsSource(src);
  const get = (key) => {
    const m = metaSrc.match(new RegExp(`${key}:\\s*"((?:\\\\.|[^"\\\\])*)"`));
    return m ? decodeTypString(m[1]) : "";
  };
  const getBool = (key) => {
    const m = metaSrc.match(new RegExp(`${key}:\\s*(true|false)`));
    return m ? m[1] === "true" : false;
  };
  return {
    title: get("title"),
    description: get("description"),
    published: get("published"),
    image: get("image"),
    draft: getBool("draft"),
  };
}

function dateKey(value) {
  const [y = "0", m = "0", d = "0"] = String(value || "").split("/");
  return `${y.padStart(4, "0")}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
}

function scanCollection(collection) {
  const entries = walk(join(contentDir, collection))
    .filter(file => file.endsWith(`${sep}index.typ`) || file.endsWith(`/index.typ`))
    .sort((a, b) => a.localeCompare(b))
    .map(file => ({ collection, slug: slugForIndex(collection, file), file, ...readMeta(file) }))
    .filter(entry => includeDrafts || !entry.draft)
    .sort((a, b) => dateKey(b.published).localeCompare(dateKey(a.published)) || a.slug.localeCompare(b.slug));
  return entries;
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

function readJsonFile(path, fallback) {
  try { return JSON.parse(readFileSync(path, "utf8")); }
  catch { return fallback; }
}

let ogpCache = null;
function getOgpCache() {
  if (ogpCache === null) ogpCache = readJsonFile(ogpCacheFile, {});
  return ogpCache;
}

function saveOgpCache() {
  if (ogpCache === null) return;
  mkdirSync(dirname(ogpCacheFile), { recursive: true });
  writeFileSync(ogpCacheFile, JSON.stringify(ogpCache, null, 2) + "\n");
}

function decodeHtmlEntity(value) {
  return String(value)
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

function parseHtmlAttributes(tag) {
  const attrs = {};
  const re = /([A-Za-z_:][-A-Za-z0-9_:.]*)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>`]+)))?/g;
  let m;
  while ((m = re.exec(tag))) {
    const key = m[1].toLowerCase();
    if (key === "meta" || key === "link") continue;
    attrs[key] = decodeHtmlEntity(m[2] ?? m[3] ?? m[4] ?? "");
  }
  return attrs;
}

function absolutizeUrl(value, baseUrl) {
  if (!value) return "";
  try { return new URL(decodeHtmlEntity(value).trim(), baseUrl).toString(); }
  catch { return decodeHtmlEntity(value).trim(); }
}

function extractOgp(html, baseUrl) {
  const meta = new Map();
  for (const match of html.matchAll(/<meta\s+[^>]*>/gi)) {
    const attrs = parseHtmlAttributes(match[0]);
    const key = (attrs.property || attrs.name || "").toLowerCase();
    if (!key || attrs.content == null) continue;
    if (!meta.has(key)) meta.set(key, attrs.content.trim());
  }

  let icon = "";
  for (const match of html.matchAll(/<link\s+[^>]*>/gi)) {
    const attrs = parseHtmlAttributes(match[0]);
    const rel = String(attrs.rel || "").toLowerCase();
    if (!icon && rel.includes("image_src") && attrs.href) icon = attrs.href;
  }

  const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  const title = meta.get("og:title") || meta.get("twitter:title") || (titleMatch ? titleMatch[1].replace(/\s+/g, " ").trim() : "");
  const description = meta.get("og:description") || meta.get("twitter:description") || meta.get("description") || "";
  const image = meta.get("og:image") || meta.get("og:image:url") || meta.get("twitter:image") || meta.get("twitter:image:src") || icon || "";

  return {
    title: decodeHtmlEntity(title),
    description: decodeHtmlEntity(description),
    image: image ? absolutizeUrl(image, baseUrl) : "",
  };
}

function isHttpUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

async function fetchOgpMetadata(url) {
  if (!enableOgpFetch || !isHttpUrl(url)) return {};
  const cache = getOgpCache();
  if (Object.hasOwn(cache, url)) return cache[url] || {};

  try {
    const res = await fetch(url, {
      redirect: "follow",
      signal: AbortSignal.timeout(ogpFetchTimeoutMs),
      headers: {
        "user-agent": "r-portfolio-ogp-fetcher/1.0 (+https://typst.app)",
        "accept": "text/html,application/xhtml+xml",
      },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const contentType = res.headers.get("content-type") || "";
    if (contentType && !contentType.includes("text/html") && !contentType.includes("application/xhtml")) {
      throw new Error(`unsupported content-type: ${contentType}`);
    }
    const html = await res.text();
    const metadata = extractOgp(html.slice(0, 512_000), res.url || url);
    if (metadata.title || metadata.description || metadata.image) {
      cache[url] = metadata;
      saveOgpCache();
    }
    return metadata;
  } catch (error) {
    if (process.env.OGP_VERBOSE === "1") console.warn(`[ogp] ${url}: ${error.message || error}`);
    return {};
  }
}

function findMatchingParen(source, openIndex) {
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = openIndex; i < source.length; i++) {
    const ch = source[i];
    if (inString) {
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') {
      inString = true;
      continue;
    }
    if (ch === "(") depth++;
    else if (ch === ")") {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function stringArg(args, key) {
  const match = args.match(new RegExp(`(?:^|[,\\s])${key}\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"`));
  return match ? decodeTypString(match[1]) : "";
}

function hasArg(args, key) {
  return new RegExp(`(?:^|[,\\s])${key}\\s*:`).test(args);
}

function missingOrEmptyStringArg(args, key) {
  if (!hasArg(args, key)) return true;
  const value = stringArg(args, key);
  return value === "" && new RegExp(`(?:^|[,\\s])${key}\\s*:\\s*""`).test(args);
}

function addNamedArgs(args, additions) {
  const clean = args.replace(/\s*$/, "");
  const comma = clean.trim().length > 0 && !clean.trim().endsWith(",") ? "," : "";
  return `${clean}${comma}\n  ${additions.join(",\n  ")},\n`;
}

async function enrichLinkPreviews(source) {
  let out = "";
  let cursor = 0;
  const needle = "#link-preview(";

  while (true) {
    const start = source.indexOf(needle, cursor);
    if (start === -1) {
      out += source.slice(cursor);
      break;
    }
    const open = start + needle.length - 1;
    const close = findMatchingParen(source, open);
    if (close === -1) {
      out += source.slice(cursor);
      break;
    }

    out += source.slice(cursor, start);
    const args = source.slice(open + 1, close);
    const link = stringArg(args, "link");
    const additions = [];

    if (link) {
      const metadata = await fetchOgpMetadata(link);
      if (!hasArg(args, "image") && metadata.image) additions.push(`image: ${typString(metadata.image)}`);
      if (missingOrEmptyStringArg(args, "title") && metadata.title) additions.push(`title: ${typString(metadata.title)}`);
      if (missingOrEmptyStringArg(args, "description") && metadata.description) additions.push(`description: ${typString(metadata.description)}`);
    }

    if (additions.length > 0) out += needle + addNamedArgs(args, additions) + ")";
    else out += source.slice(start, close + 1);
    cursor = close + 1;
  }

  return out;
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

async function materializeEntry(entry) {
  const rel = entry.collection ? join(entry.collection, ...entry.slug.split("/"), "index.typ") : join(entry.name, "index.typ");
  const out = join(generatedContentDir, rel);
  mkdirSync(dirname(out), { recursive: true });
  const source = readFileSync(entry.file, "utf8");
  const enriched = await enrichLinkPreviews(source);
  writeFileSync(out, normalizeTypContent(enriched));
}

async function materializeContent(content) {
  if (existsSync(generatedContentDir)) rmSync(generatedContentDir, { recursive: true, force: true });
  mkdirSync(generatedContentDir, { recursive: true });
  for (const entry of [...content.posts, ...content.projects, ...content.favorites, content.awards, content.publications]) {
    await materializeEntry(entry);
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
  lines.push("#let public-assets = (");
  for (const item of scanPublicAssets()) {
    lines.push(`  (out: ${typString(item.out)}, source: ${typString(item.source)}),`);
  }
  lines.push(")", "");

  writeFileSync(join(contentDir, "_generated.typ"), lines.join("\n"));
}

async function contentManifest() {
  const content = {
    posts: scanCollection("blog"),
    projects: scanCollection("projects"),
    favorites: scanCollection("favorites"),
    awards: scanPage("awards"),
    publications: scanPage("publications"),
  };
  await materializeContent(content);
  generateContentManifest(content);
  return content;
}

function compileBundle() {
  const args = [
    "compile",
    "--features", "html,bundle",
    "--format", "bundle",
    "--input", `site_url=${siteUrl}`,
    "main.typ",
    distDir,
  ];
  const res = spawnSync(typstCommand, args, { cwd: rootDir, stdio: "inherit" });
  if (res.error) throw res.error;
  if (res.status !== 0) throw new Error("typst bundle compile failed");
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

function rfc822Date(value) {
  const [y, m = "1", d = "1"] = String(value || "").split("/").map(Number);
  if (!y || !m || !d) return "";
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0)).toUTCString();
}

function rssItemUrl(entry) {
  return `${siteUrl}/${entry.collection}/${entry.slug}/`;
}

function makeRssFeed({ output, title, description, linkPath, entries }) {
  if (!siteUrl) return;

  const feedUrl = `${siteUrl}/${output}`;
  const channelUrl = `${siteUrl}${linkPath}`;
  const items = entries.map(entry => {
    const url = rssItemUrl(entry);
    const pubDate = rfc822Date(entry.published);
    return [
      "  <item>",
      `    <title>${xmlEscape(entry.title)}</title>`,
      `    <link>${xmlEscape(url)}</link>`,
      `    <guid isPermaLink="true">${xmlEscape(url)}</guid>`,
      `    <description>${xmlEscape(entry.description)}</description>`,
      pubDate ? `    <pubDate>${xmlEscape(pubDate)}</pubDate>` : "",
      "  </item>",
    ].filter(Boolean).join("\n");
  }).join("\n");

  const lastBuildDate = new Date().toUTCString();
  writeText(output, `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
  <title>${xmlEscape(title)}</title>
  <link>${xmlEscape(channelUrl)}</link>
  <description>${xmlEscape(description)}</description>
  <atom:link href="${xmlEscape(feedUrl)}" rel="self" type="application/rss+xml" />
  <lastBuildDate>${xmlEscape(lastBuildDate)}</lastBuildDate>
${items}
</channel>
</rss>
`);
}

function makeRss(content) {
  if (!siteUrl) return;

  const posts = content.posts.filter(entry => !entry.draft).map(entry => ({ ...entry, collection: "blog" }));
  const projects = content.projects.filter(entry => !entry.draft).map(entry => ({ ...entry, collection: "projects" }));
  const all = [...posts, ...projects]
    .sort((a, b) => dateKey(b.published).localeCompare(dateKey(a.published)) || a.slug.localeCompare(b.slug));

  makeRssFeed({
    output: "rss.xml",
    title: "r-Portfolio",
    description: "Blog posts and projects from r-Portfolio.",
    linkPath: "/",
    entries: all,
  });
  makeRssFeed({
    output: "blog/rss.xml",
    title: "r-Portfolio Blog",
    description: "Blog posts from r-Portfolio.",
    linkPath: "/blog/",
    entries: posts,
  });
  makeRssFeed({
    output: "projects/rss.xml",
    title: "r-Portfolio Projects",
    description: "Projects from r-Portfolio.",
    linkPath: "/projects/",
    entries: projects,
  });
}

export async function build() {
  if (existsSync(distDir)) rmSync(distDir, { recursive: true, force: true });
  mkdirSync(distDir, { recursive: true });
  const content = await contentManifest();

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

  compileBundle();
  makeSitemap(routes);
  makeRss(content);
  console.log(`\nGenerated ${routes.length} HTML pages as a Typst bundle in dist/`);
  if (includeDrafts) console.log("Draft entries are included because RPORTFOLIO_INCLUDE_DRAFTS=1.");
  if (!siteUrl) console.log("Set SITE_URL=https://example.com to emit sitemap.xml, robots.txt, and RSS feeds.");
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { await build(); }
  catch (error) { console.error(error.message || error); process.exit(1); }
}
