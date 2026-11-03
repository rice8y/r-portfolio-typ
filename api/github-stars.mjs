import { readFile } from "node:fs/promises";
import { join } from "node:path";

export default {
  async fetch(request) {
    const noCache = { "Cache-Control": "no-store" };
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response(null, { status: 405, headers: { ...noCache, Allow: "GET, HEAD" } });
    }
    if (new URL(request.url).search) {
      return Response.json({ error: "Query parameters are not supported" }, { status: 400, headers: noCache });
    }

    try {
      const repositories = JSON.parse(await readFile(join(process.cwd(), "generated/project-repositories.json"), "utf8"));
      const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
      const headers = {
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2026-03-10",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      };
      const entries = await Promise.all(repositories.map(async (repo) => {
        const response = await fetch(`https://api.github.com/repos/${repo}`, {
          headers,
          signal: AbortSignal.timeout(8000),
        });
        if (response.status === 404) return [repo, null];
        if (!response.ok) throw new Error(`GitHub HTTP ${response.status}`);
        const data = await response.json();
        if (data.private) return [repo, null];
        if (!Number.isSafeInteger(data.stargazers_count) || data.stargazers_count < 0) {
          throw new Error("Invalid GitHub star count");
        }
        return [repo, data.stargazers_count];
      }));
      const cache = { "Cache-Control": "public, max-age=0, s-maxage=300" };
      if (request.method === "HEAD") return new Response(null, { headers: cache });
      return Response.json({ stars: Object.fromEntries(entries) }, { headers: cache });
    } catch {
      return Response.json({ error: "GitHub stars are temporarily unavailable" }, { status: 503, headers: noCache });
    }
  },
};
