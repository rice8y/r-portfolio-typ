import { readFile, writeFile, rename } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import { pathToFileURL } from "node:url";

export function repositoriesFrom(links) {
  return [...new Set(links.flatMap((link) => {
    try {
      const url = new URL(link);
      const [owner, name] = url.pathname.split("/").filter(Boolean);
      const repo = name?.replace(/\.git$/, "");
      return url.hostname === "github.com" && /^[\w.-]+$/.test(owner || "") && /^[\w.-]+$/.test(repo || "")
        ? [`${owner}/${repo}`.toLowerCase()] : [];
    } catch { return []; }
  }))];
}

export function aggregate(responses) {
  const totals = new Map();
  for (const data of responses) {
    if (!data || typeof data !== "object" || Array.isArray(data)
      || !Object.values(data).every((bytes) => Number.isSafeInteger(bytes) && bytes >= 0)) {
      throw new Error("Invalid GitHub language response");
    }
    for (const [language, bytes] of Object.entries(data)) totals.set(language, (totals.get(language) || 0) + bytes);
  }
  const total = [...totals.values()].reduce((a, b) => a + b, 0);
  return [...totals].filter(([, bytes]) => bytes > 0)
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
    .map(([language, bytes]) => ({ language, bytes, percentage: bytes / total * 100 }));
}

const escape = (value) => String(value).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]);

async function build() {
  // Query freshly generated Typage metadata, so links are evaluated by Typst.
  const query = ".typage/project-language-links.typ";
  await writeFile(query, '#import "site.typ": pages\n#metadata(pages.filter(p => p.section == "projects").map(p => p.at("links", default: ()).map(l => l.url)).flatten()) <project-links>\n');
  const links = JSON.parse(execFileSync("typst", ["query", "--root", ".", query, "<project-links>", "--field", "value", "--one"], { encoding: "utf8" }));
  const repositories = repositoriesFrom(links);
  const responses = [];
  const unavailable = [];
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  for (const repo of repositories) {
    const response = await fetch(`https://api.github.com/repos/${repo}/languages`, {
      headers: { Accept: "application/vnd.github+json", ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      signal: AbortSignal.timeout(30000),
    });
    if (response.status === 404) {
      unavailable.push(repo);
      console.warn(`Skipping unavailable repository: ${repo} (404)`);
      continue;
    }
    if (!response.ok) throw new Error(`${repo}: GitHub HTTP ${response.status}; language chart build aborted`);
    responses.push(await response.json());
  }
  const rows = aggregate(responses);
  const bars = rows.map(({ language, bytes, percentage }) =>
    `<li title="${escape(language)}: ${bytes} bytes"><span class="language-chart-label">${escape(language)}</span><span class="language-chart-track" aria-hidden="true"><span style="width:${percentage}%"></span></span><span class="language-chart-value">${percentage < 0.1 ? "&lt;0.1" : percentage.toFixed(1)}%</span></li>`).join("");
  const note = unavailable.length ? ` Unavailable repositories excluded: ${unavailable.map(escape).join(", ")}.` : "";
  const chart = `<section id="project-language-chart" aria-labelledby="project-language-title"><h2 id="project-language-title" class="section-title">Languages</h2><p class="language-chart-status">${rows.length ? `Share of code bytes across ${responses.length} GitHub repositories.` : "No GitHub language data available."}${note}</p><ol class="language-chart-bars" aria-label="Language share by code bytes">${bars}</ol></section>`;
  const path = "dist/projects/index.html";
  const html = await readFile(path, "utf8");
  const pattern = /<section\b[^>]*\bid="project-language-chart"[^>]*>[\s\S]*?<\/section>/;
  if (!pattern.test(html)) throw new Error("Project language chart placeholder not found");
  await writeFile(`${path}.tmp`, html.replace(pattern, () => chart));
  await rename(`${path}.tmp`, path);
  console.log(`Built language chart: ${responses.length} repositories, ${rows.length} languages, ${unavailable.length} unavailable`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  build().catch((error) => { console.error(error.message); process.exitCode = 1; });
}
