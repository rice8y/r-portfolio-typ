import assert from "node:assert/strict";
import { aggregate, repositoriesFrom } from "./build-project-languages.mjs";

assert.deepEqual(repositoriesFrom([
  "https://github.com/owner/repo/tree/main", "https://github.com/OWNER/repo.git",
  "https://example.com/owner/repo", "https://github.com/owner", "invalid",
]), ["owner/repo"]);
assert.deepEqual(aggregate([{ Rust: 300, Typst: 100 }, { Typst: 600 }]), [
  { language: "Typst", bytes: 700, percentage: 70 },
  { language: "Rust", bytes: 300, percentage: 30 },
]);
assert.deepEqual(aggregate([{}]), []);
assert.deepEqual(aggregate([{ Z: 1, A: 1 }]).map(row => row.language), ["A", "Z"]);
assert.throws(() => aggregate([{ message: "rate limited" }]));
assert.throws(() => aggregate([{ Rust: -1 }]));
console.log("PASS: repository normalization, byte weighting, sorting, empty and invalid responses");
