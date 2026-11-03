import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, beforeEach, mock, test } from "node:test";
import handler from "../api/github-stars.mjs";

let directory;
let savedTokens;
beforeEach(async () => {
  directory = await mkdtemp(join(tmpdir(), "portfolio-stars-"));
  await mkdir(join(directory, "generated"));
  await writeFile(join(directory, "generated/project-repositories.json"), JSON.stringify([
    "owner/zero", "owner/popular", "owner/missing",
  ]));
  mock.method(process, "cwd", () => directory);
  savedTokens = [process.env.GITHUB_TOKEN, process.env.GH_TOKEN];
  delete process.env.GITHUB_TOKEN;
  delete process.env.GH_TOKEN;
});
afterEach(async () => {
  mock.restoreAll();
  ["GITHUB_TOKEN", "GH_TOKEN"].forEach((key, index) => {
    if (savedTokens[index] === undefined) delete process.env[key];
    else process.env[key] = savedTokens[index];
  });
  await rm(directory, { recursive: true, force: true });
});

test("returns counts including zero and caches successful responses for five minutes", async () => {
  process.env.GITHUB_TOKEN = "test-token";
  const fetchMock = mock.method(globalThis, "fetch", async (url, options) => {
    assert.equal(options.headers.Authorization, "Bearer test-token");
    if (url.endsWith("/missing")) return new Response(null, { status: 404 });
    return Response.json({ stargazers_count: url.endsWith("/zero") ? 0 : 12345 });
  });
  const response = await handler.fetch(new Request("https://portfolio.test/api/github-stars"));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("Cache-Control"), "public, max-age=0, s-maxage=300");
  assert.deepEqual(await response.json(), { stars: { "owner/zero": 0, "owner/popular": 12345, "owner/missing": null } });
  assert.deepEqual(fetchMock.mock.calls.map(call => call.arguments[0]).sort(), [
    "https://api.github.com/repos/owner/missing", "https://api.github.com/repos/owner/popular", "https://api.github.com/repos/owner/zero",
  ]);
});

test("uses GH_TOKEN as a fallback and keeps private repositories hidden", async () => {
  process.env.GH_TOKEN = "fallback-token";
  mock.method(globalThis, "fetch", async (_, options) => {
    assert.equal(options.headers.Authorization, "Bearer fallback-token");
    return Response.json({ private: true, stargazers_count: 10 });
  });
  const response = await handler.fetch(new Request("https://portfolio.test/api/github-stars"));
  assert.ok(Object.values((await response.json()).stars).every(count => count === null));
});

test("supports HEAD without a response body", async () => {
  mock.method(globalThis, "fetch", async (_, options) => {
    assert.equal(options.headers.Authorization, undefined);
    return Response.json({ stargazers_count: 1 });
  });
  const response = await handler.fetch(new Request("https://portfolio.test/api/github-stars", { method: "HEAD" }));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("Cache-Control"), "public, max-age=0, s-maxage=300");
  assert.equal(await response.text(), "");
});

test("rejects methods and query parameters before requesting GitHub", async () => {
  const fetchMock = mock.method(globalThis, "fetch", () => { throw new Error("Unexpected fetch"); });
  const post = await handler.fetch(new Request("https://portfolio.test/api/github-stars", { method: "POST" }));
  assert.equal(post.status, 405);
  assert.equal(post.headers.get("Allow"), "GET, HEAD");
  const query = await handler.fetch(new Request("https://portfolio.test/api/github-stars?repo=other/repo"));
  assert.equal(query.status, 400);
  assert.equal(query.headers.get("Cache-Control"), "no-store");
  assert.equal(fetchMock.mock.callCount(), 0);
});

test("does not cache rate limits, invalid counts, or network failures", async () => {
  for (const result of [
    () => new Response(null, { status: 429 }),
    () => Response.json({ stargazers_count: -1 }),
    () => Response.json({ stargazers_count: "5" }),
    () => { throw new Error("Network unavailable"); },
  ]) {
    mock.method(globalThis, "fetch", async () => result());
    const response = await handler.fetch(new Request("https://portfolio.test/api/github-stars"));
    assert.equal(response.status, 503);
    assert.equal(response.headers.get("Cache-Control"), "no-store");
    assert.deepEqual(await response.json(), { error: "GitHub stars are temporarily unavailable" });
  }
});
