#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const src = fs.readFileSync(path.join(repoDir, "herdr-app/mods/switch/main.js"), "utf8");
const helpers = src.replace(/^import .*$/gm, "").split("export default class")[0];
const { shortPath, scoreRow } = new Function(`${helpers}; return { shortPath, scoreRow };`)();

const H = "/Users/brad.robinson";
const items = [
  { kind: "space", name: "herdr-app", folder: `${H}/Documents/code/herdr-app` },
  { kind: "space", name: "documents-test", folder: `${H}/Documents/documents-test` },
  { kind: "space", name: "work", folder: `${H}/Documents/code/acme-api` },
  { kind: "folder", name: ".dotfiles", path: `${H}/.dotfiles` },
  { kind: "folder", name: "code", path: `${H}/Documents/code` },
  { kind: "folder", name: "js-lib-monorepo", path: `${H}/Documents/code/js-lib-monorepo` },
  { kind: "folder", name: "my_app", path: `${H}/Documents/code/my_app` },
  { kind: "folder", name: "my-app", path: `${H}/Documents/code/my-app` },
  { kind: "folder", name: "myapp", path: `${H}/Documents/code/myapp` },
  { kind: "folder", name: "my-other-app", path: `${H}/Documents/code/my-other-app` },
  { kind: "folder", name: "my-cool-app", path: `${H}/Documents/code/my-cool-app` },
  { kind: "folder", name: "mycoolapp", path: `${H}/Documents/code/mycoolapp` },
  { kind: "folder", name: "2026-04-02-herdr-test", path: `${H}/Documents/code/tries/2026-04-02-herdr-test` },
  { kind: "folder", name: "HerdrPlugin", path: `${H}/Documents/code/HerdrPlugin` },
  { kind: "folder", name: "foo.bar", path: `${H}/Documents/code/foo.bar` },
];

const rank = (q) => {
  const tokens = q.trim().toLowerCase().split(/\s+/).filter(Boolean);
  return items
    .map((r) => ({ name: r.name, score: scoreRow(tokens, r, H) }))
    .filter((x) => x.score !== null)
    .sort((a, b) => b.score - a.score)
    .map((x) => x.name);
};

assert.equal(rank("herdrapp")[0], "herdr-app");
assert.equal(rank("jslib")[0], "js-lib-monorepo");
assert.equal(rank("dot")[0], ".dotfiles");
assert.equal(rank("foobar")[0], "foo.bar");
assert.equal(rank("herdr app")[0], "herdr-app");
assert.equal(rank("app herdr")[0], "herdr-app");
assert.equal(rank("tries herdr")[0], "2026-04-02-herdr-test");
assert.equal(rank("tries/herdr")[0], "2026-04-02-herdr-test");
assert.equal(rank("work acme")[0], "work");
assert.equal(rank("workacme")[0], "work");
assert.equal(rank("code")[0], "code");

assert.deepEqual(rank("my-app").slice(0, 5), ["my-app", "myapp", "my_app", "my-cool-app", "my-other-app"]);
assert.deepEqual(rank("my-cool-app").slice(0, 2), ["my-cool-app", "mycoolapp"]);
assert.ok(rank("foo-bar").includes("foo.bar"));
assert.ok(rank("herdr-plugin").includes("HerdrPlugin"));

assert.deepEqual(rank("brad"), []);
assert.deepEqual(rank("."), [".dotfiles", "foo.bar"]);
assert.equal(shortPath(H, H), "~");
assert.equal(shortPath(`${H}/.dotfiles`, H), "~/.dotfiles");
assert.equal(shortPath(`${H}2/foo`, H), `${H}2/foo`);
assert.equal(shortPath(undefined, H), "");
assert.ok(scoreRow(["scratch"], { kind: "space", name: "scratch", folder: undefined }, H) !== null);

console.log("PASS: herdr switch fuzzy matcher");
