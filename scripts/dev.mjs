import { createServer } from "node:http";
import { existsSync, readFileSync, statSync, watch } from "node:fs";
import { extname, join, normalize, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "./build.mjs";

const rootDir = join(dirname(fileURLToPath(import.meta.url)), "..");
const distDir = join(rootDir, "dist");
const port = Number(process.env.PORT || 4321);
const mime = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".xml", "application/xml; charset=utf-8"],
  [".txt", "text/plain; charset=utf-8"],
  [".svg", "image/svg+xml"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".webp", "image/webp"],
]);

let timer;
const watchers = [];
let server;
let stdinWasRaw = false;

function restoreStdin() {
  if (process.stdin.isTTY && stdinWasRaw) {
    try { process.stdin.setRawMode(false); } catch {}
    stdinWasRaw = false;
  }
}

function enableKeyboardStop() {
  if (!process.stdin.isTTY || process.env.CI) return;
  try {
    stdinWasRaw = process.stdin.isRaw;
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", chunk => {
      if (chunk.includes("\u0003") || chunk.toLowerCase() === "q") shutdown("keyboard");
    });
  } catch {}
}

function shutdown(signal) {
  restoreStdin();
  clearTimeout(timer);
  for (const watcher of watchers) {
    try { watcher.close(); } catch {}
  }
  if (server) {
    server.close(() => {
      console.log(`\n[dev] stopped${signal ? ` by ${signal}` : ""}`);
      process.exit(0);
    });
    setTimeout(() => process.exit(0), 250).unref();
  } else {
    process.exit(0);
  }
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("exit", restoreStdin);

enableKeyboardStop();

function rebuild() {
  clearTimeout(timer);
  timer = setTimeout(async () => {
    try { console.log("\n[dev] rebuild"); await build(); }
    catch (error) { console.error(error.message || error); }
  }, 120);
}

function servePath(urlPath) {
  let clean = decodeURIComponent(urlPath.split("?")[0]);
  if (clean.endsWith("/")) clean += "index.html";
  if (!extname(clean)) clean += "/index.html";
  const path = normalize(join(distDir, clean));
  if (!path.startsWith(normalize(distDir))) return join(distDir, "404.html");
  if (existsSync(path) && statSync(path).isFile()) return path;
  return join(distDir, "404.html");
}

try { await build(); } catch (error) { console.error(error.message || error); }

for (const dir of ["content", "assets", "scripts", "site.typ", "main.typ"]) {
  try {
    const watcher = watch(join(rootDir, dir), { recursive: true }, (_event, filename) => {
      const rel = String(filename || "").split("\\").join("/");
      if (dir === "content" && (rel === "_generated.typ" || rel.startsWith("_build/"))) return;
      rebuild();
    });
    watchers.push(watcher);
  } catch {}
}

server = createServer((req, res) => {
  const file = servePath(req.url || "/");
  const ext = extname(file);
  try {
    res.writeHead(file.endsWith("404.html") && !(req.url || "").includes("404") ? 404 : 200, { "content-type": mime.get(ext) || "application/octet-stream" });
    res.end(readFileSync(file));
  } catch {
    res.writeHead(500, { "content-type": "text/plain; charset=utf-8" });
    res.end("Internal server error");
  }
}).listen(port, () => console.log(`[dev] http://localhost:${port}  (press Ctrl+C or q to stop)`));
