import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = process.argv[2] || "/Users/yoneyama/workspace/github/r-portfolio-typ";
const sourceContent = join(sourceRoot, "content");
const targetContent = join(projectRoot, "content");
const targetStatic = join(projectRoot, "static");
const targetTemplateAssets = join(projectRoot, "templates", "assets");
const typstHtmlCss = `/* Alignment */
mtable.right-align mtd,
mtable mtd.right-align,
mtable.left-align mtd.right-align,
mtable.aligned mtd:nth-child(odd) {
  justify-items: end;
  text-align: right;
}
mtable.cases mtd,
mtable.left-align mtd,
mtable mtd.left-align,
mtable.aligned mtd:nth-child(even),
math:is(:not([display])) > mtable.multiline-equation mtd {
  justify-items: start;
  text-align: left;
}
mtable.cases mtd,
mtable.aligned mtd,
mtable mtd.flushed,
mtable mtd.left-flush {
  padding-left: 0;
}
mtable.cases mtd,
mtable.aligned mtd,
mtable mtd.flushed,
mtable mtd.right-flush {
  padding-right: 0;
}

/* Tables */
mtable {
  math-style: inherit;
}
mtd {
  math-depth: auto-add;
  math-style: compact;
  math-shift: compact;
}

/* Equations */
mtable.multiline-equation mtd {
  math-depth: inherit;
  math-style: inherit;
  math-shift: inherit;
  padding: 0;
}
math > mtable.multiline-equation mtr:not(:last-child) mtd {
  padding-bottom: 0.5em;
}

/* Fractions */
mfrac {
  padding-inline: 0;
  margin-inline: 0.1em;
}

/* Accents */
mover[accent="true" i] > :first-child {
  font-feature-settings: "dtls";
}
mover.dotted[accent="true" i] > :first-child {
  font-feature-settings: "dtls" 0;
}

/* Other rules for scriptlevel, displaystyle and math-shift */
munder > :nth-child(2),
munderover > :nth-child(2) {
  math-shift: compact
}
munder[accentunder="true" i] > :not(:first-child),
mover[accent="true" i] > :not(:first-child) {
  math-depth: inherit;
  math-style: inherit;
  math-shift: inherit;
}
`;

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

function decodeTypString(raw) {
  try {
    return JSON.parse(`"${raw}"`);
  } catch {
    return raw.replace(/\\"/g, '"').replace(/\\\\/g, "\\");
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
    if (ch === '"') inString = true;
    else if (ch === "(") depth++;
    else if (ch === ")") {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function argValue(args, key) {
  const re = new RegExp(`(?:^|[,\\s])${key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\s*:`, "m");
  const match = re.exec(args);
  if (!match) return "";
  let i = match.index + match[0].length;
  let depth = 0;
  let inString = false;
  let escaped = false;
  let out = "";
  for (; i < args.length; i++) {
    const ch = args[i];
    if (inString) {
      out += ch;
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') {
      inString = true;
      out += ch;
    } else if (ch === "(" || ch === "[" || ch === "{") {
      depth++;
      out += ch;
    } else if (ch === ")" || ch === "]" || ch === "}") {
      if (depth === 0) break;
      depth--;
      out += ch;
    } else if (ch === "," && depth === 0) {
      break;
    } else {
      out += ch;
    }
  }
  return out.trim();
}

function stringArg(args, key) {
  const value = argValue(args, key);
  const match = value.match(/^"((?:\\.|[^"\\])*)"$/s);
  return match ? decodeTypString(match[1]) : "";
}

function boolArg(args, key) {
  return argValue(args, key) === "true";
}

function tupleStrings(value) {
  const out = [];
  for (const match of value.matchAll(/"((?:\\.|[^"\\])*)"/g)) {
    out.push(decodeTypString(match[1]));
  }
  return out;
}

function linksArg(value) {
  const out = [];
  const re = /\(\s*label:\s*"((?:\\.|[^"\\])*)"\s*,\s*url:\s*"((?:\\.|[^"\\])*)"\s*,?\s*\)/g;
  for (const match of value.matchAll(re)) {
    out.push({ label: decodeTypString(match[1]), url: decodeTypString(match[2]) });
  }
  return out;
}

function hasRenderableMath(source) {
  let fence = null;
  for (const line of source.split(/\r?\n/)) {
    const match = line.match(/^\s*(`{3,}|~{3,})/);
    if (match && !fence) {
      fence = match[1];
      continue;
    }
    if (match && fence && match[1][0] === fence[0] && match[1].length >= fence.length) {
      fence = null;
      continue;
    }
    if (fence) continue;
    const withoutInlineCode = line.replace(/`(?:\\.|[^`\\])*`/g, "");
    if (/(^|[^\\])\$/.test(withoutInlineCode)) return true;
  }
  return false;
}

function normalizeDate(value) {
  if (!value) return "";
  const [y, m = "1", d = "1"] = String(value).split(/[/-]/);
  return `${y.padStart(4, "0")}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
}

function tomlString(value) {
  return JSON.stringify(String(value));
}

function tomlArray(values) {
  return `[${values.map(tomlString).join(", ")}]`;
}

function tomlLinks(links) {
  if (links.length === 0) return "[]";
  return `[${links.map(link => `{ label = ${tomlString(link.label)}, url = ${tomlString(link.url)} }`).join(", ")}]`;
}

function parseEntry(source) {
  const start = source.indexOf("#let entry");
  if (start === -1) return null;
  const head = source.slice(start).match(/^#let entry\s*=\s*([A-Za-z_][A-Za-z0-9_-]*)\s*\(/m);
  if (!head) return null;
  const kind = head[1];
  const open = source.indexOf("(", start + head.index);
  const close = findMatchingParen(source, open);
  if (close === -1) throw new Error("entry call has no closing parenthesis");
  const bodyOpen = source.indexOf("[", close);
  const bodyClose = source.lastIndexOf("]");
  if (bodyOpen === -1 || bodyClose <= bodyOpen) throw new Error("entry body has no bracket block");
  return {
    kind,
    prefix: source.slice(0, start).trimEnd(),
    args: source.slice(open + 1, close),
    body: source.slice(bodyOpen + 1, bodyClose).trim(),
  };
}

function sectionFor(rel, kind) {
  const parts = toPosix(rel).split("/");
  if (rel === "awards/index.typ" || rel === "publications/index.typ") return "pages";
  if (kind === "post") return "blog";
  if (kind === "project") return "projects";
  if (kind === "favorite") {
    return "favorites";
  }
  return "";
}

function writeEntry(rel, source) {
  const parsed = parseEntry(source);
  if (!parsed) return false;
  const args = parsed.args;
  const title = stringArg(args, "title") || rel.replace(/\/index\.typ$/, "");
  const description = stringArg(args, "description");
  const publishedRaw = stringArg(args, "published");
  const updatedRaw = stringArg(args, "updated");
  const date = normalizeDate(publishedRaw);
  const updated = normalizeDate(updatedRaw);
  const image = stringArg(args, "image");
  const readingTime = stringArg(args, "reading-time") || "1 min read";
  const draft = boolArg(args, "draft");
  const languages = tupleStrings(argValue(args, "languages"));
  const repoUrl = stringArg(args, "repo-url");
  const links = linksArg(argValue(args, "links"));
  if (repoUrl) links.unshift({ label: "GitHub", url: repoUrl });
  const section = sectionFor(rel, parsed.kind);

  const fm = [];
  fm.push("---");
  fm.push(`title = ${tomlString(title)}`);
  if (description) fm.push(`description = ${tomlString(description)}`);
  if (date) fm.push(`date = ${tomlString(date)}`);
  if (updated) fm.push(`updated = ${tomlString(updated)}`);
  if (draft) fm.push("draft = true");
  if (section) fm.push(`section = ${tomlString(section)}`);
  fm.push("toc = false");
  fm.push("");
  fm.push("[extra]");
  fm.push(`kind = ${tomlString(parsed.kind)}`);
  fm.push(`reading_time = ${tomlString(readingTime)}`);
  if (draft) fm.push("draft = true");
  if (image) fm.push(`image = ${tomlString(image)}`);
  if (hasRenderableMath(parsed.body)) fm.push("has_math = true");
  if (publishedRaw) fm.push(`published_raw = ${tomlString(publishedRaw)}`);
  if (updatedRaw) fm.push(`updated_raw = ${tomlString(updatedRaw)}`);
  if (parsed.body.trim() === "wip...") fm.push(`plain_body = ${tomlString("wip…")}`);
  if (languages.length > 0) fm.push(`languages = ${tomlArray(languages)}`);
  if (links.length > 0) fm.push(`links = ${tomlLinks(links)}`);
  fm.push("---");

  const bodyParts = [];
  if (parsed.prefix) bodyParts.push(parsed.prefix.replaceAll("/content/prelude.typ", "/content/_prelude.typ"));
  bodyParts.push(parsed.body);
  const out = `${fm.join("\n")}\n\n${bodyParts.join("\n\n")}\n`;
  const target = join(targetContent, rel);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, out);
  return true;
}

function writeSection(path, title, description, sortBy = "date_desc") {
  const body = [
    "---",
    `title = ${tomlString(title)}`,
    `description = ${tomlString(description)}`,
    `sort_by = ${tomlString(sortBy)}`,
    "---",
    "",
  ].join("\n");
  const target = join(targetContent, path);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, body);
}

function writeHome() {
  const body = `---
title = "Home"
description = "A personal portfolio and blog for sharing research, projects, publications, and notes."
section = "pages"
toc = false
---
`;
  writeFileSync(join(targetContent, "index.typ"), body);
}

function writeHomePartial(targetName, rel) {
  const built = join(sourceContent, "_build", rel);
  const source = readFileSync(existsSync(built) ? built : join(sourceContent, rel), "utf8");
  const parsed = parseEntry(source);
  if (!parsed) throw new Error(`failed to parse home partial ${rel}`);
  const bodyParts = [];
  if (parsed.prefix) bodyParts.push(parsed.prefix.replaceAll("/content/prelude.typ", "/content/_prelude.typ"));
  bodyParts.push(parsed.body);
  writeFileSync(join(targetContent, targetName), `${bodyParts.join("\n\n")}\n`);
}

rmSync(targetContent, { recursive: true, force: true });
rmSync(targetStatic, { recursive: true, force: true });
rmSync(targetTemplateAssets, { recursive: true, force: true });
mkdirSync(targetContent, { recursive: true });
mkdirSync(targetStatic, { recursive: true });
mkdirSync(targetTemplateAssets, { recursive: true });

cpSync(join(sourceRoot, "public"), targetStatic, { recursive: true });
cpSync(join(sourceRoot, "public", "images", "logo.png"), join(targetStatic, "logo.png"));
cpSync(join(sourceRoot, "assets", "site.css"), join(targetTemplateAssets, "site.css"));
cpSync(join(sourceRoot, "assets", "site.js"), join(targetTemplateAssets, "site.js"));
cpSync(join(sourceRoot, "assets", "giscus.js"), join(targetTemplateAssets, "giscus.js"));
writeFileSync(join(targetTemplateAssets, "typst-html.css"), typstHtmlCss.trimEnd());
if (existsSync(join(sourceRoot, "dist", "404.html"))) {
  cpSync(join(sourceRoot, "dist", "404.html"), join(targetStatic, "404.html"));
}
cpSync(join(sourceContent, "prelude.typ"), join(targetContent, "_prelude.typ"));

writeHome();
writeHomePartial("_home_awards.typ", "awards/index.typ");
writeHomePartial("_home_publications.typ", "publications/index.typ");
writeSection("blog/_index.typ", "Blog", "A collection of articles on topics I am passionate about.");
writeSection("projects/_index.typ", "Projects", "A collection of my projects, with links to repositories and demos.");
writeSection("favorites/_index.typ", "Favorites", "A collection of my favorites.");

let converted = 0;
for (const file of walk(sourceContent)) {
  const rel = toPosix(relative(sourceContent, file));
  if (rel === "prelude.typ" || rel === "profile.typ" || rel === "_generated.typ") continue;
  const built = join(sourceContent, "_build", rel);
  const source = readFileSync(existsSync(built) ? built : file, "utf8");
  if (writeEntry(rel, source)) converted++;
}

console.log(`converted ${converted} r-portfolio content files into Typage schema`);
