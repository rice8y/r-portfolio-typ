import { createWriteStream, existsSync, mkdirSync, chmodSync, copyFileSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { get } from "node:https";

const rootDir = join(dirname(fileURLToPath(import.meta.url)), "..");
const version = process.env.TYPST_VERSION || "0.15.0";
const binDir = join(rootDir, ".bin");
const cacheDir = join(rootDir, ".cache", "typst", `v${version}`);
const localBin = join(binDir, process.platform === "win32" ? "typst.exe" : "typst");

function commandWorks(command) {
  const res = spawnSync(command, ["--version"], { stdio: "ignore" });
  return res.status === 0;
}

if (process.env.TYPST) {
  if (!commandWorks(process.env.TYPST)) {
    console.error(`TYPST is set to ${process.env.TYPST}, but it is not executable.`);
    process.exit(1);
  }
  process.exit(0);
}

if (commandWorks("typst") || commandWorks(localBin)) {
  process.exit(0);
}

function archiveTarget() {
  const arch = process.arch;
  const platform = process.platform;
  if (platform === "linux" && arch === "x64") return "x86_64-unknown-linux-musl";
  if (platform === "linux" && arch === "arm64") return "aarch64-unknown-linux-musl";
  if (platform === "darwin" && arch === "x64") return "x86_64-apple-darwin";
  if (platform === "darwin" && arch === "arm64") return "aarch64-apple-darwin";
  if (platform === "win32" && arch === "x64") return "x86_64-pc-windows-msvc";
  throw new Error(`Unsupported platform for automatic Typst install: ${platform}/${arch}`);
}

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const request = get(url, response => {
      if ([301, 302, 303, 307, 308].includes(response.statusCode) && response.headers.location) {
        response.resume();
        download(response.headers.location, dest).then(resolve, reject);
        return;
      }
      if (response.statusCode !== 200) {
        reject(new Error(`Failed to download ${url}: HTTP ${response.statusCode}`));
        response.resume();
        return;
      }
      const out = createWriteStream(dest);
      response.pipe(out);
      out.on("finish", () => out.close(resolve));
      out.on("error", reject);
    });
    request.on("error", reject);
  });
}

const target = archiveTarget();
const ext = process.platform === "win32" ? "zip" : "tar.xz";
const archiveName = `typst-${target}.${ext}`;
const url = `https://github.com/typst/typst/releases/download/v${version}/${archiveName}`;
const archivePath = join(cacheDir, archiveName);

mkdirSync(cacheDir, { recursive: true });
mkdirSync(binDir, { recursive: true });

console.log(`[setup] installing Typst ${version} for ${target}`);
await download(url, archivePath);

if (process.platform === "win32") {
  const res = spawnSync("powershell", ["-NoProfile", "-Command", `Expand-Archive -Force ${JSON.stringify(archivePath)} ${JSON.stringify(cacheDir)}`], { stdio: "inherit" });
  if (res.status !== 0) process.exit(res.status ?? 1);
  copyFileSync(join(cacheDir, `typst-${target}`, "typst.exe"), localBin);
} else {
  const extractDir = join(cacheDir, "extract");
  rmSync(extractDir, { recursive: true, force: true });
  mkdirSync(extractDir, { recursive: true });
  const res = spawnSync("tar", ["-xJf", archivePath, "-C", extractDir], { stdio: "inherit" });
  if (res.status !== 0) process.exit(res.status ?? 1);
  copyFileSync(join(extractDir, `typst-${target}`, "typst"), localBin);
  chmodSync(localBin, 0o755);
}

if (!commandWorks(localBin)) {
  console.error("Typst installation failed: local binary is not executable.");
  process.exit(1);
}
console.log(`[setup] Typst installed at ${localBin}`);
