import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { applyConfigTransaction } from "../src/config/transaction.ts";
import { writePrivateFile } from "../src/core/filesystem.ts";

async function fixture(): Promise<{ path: string; original: string }> {
  const directory = await mkdtemp(resolve(tmpdir(), "paseo-transaction-test-"));
  const path = resolve(directory, "config.json"); const original = "{\"before\":true}\n";
  await writePrivateFile(path, original); return { path, original };
}

test("successful transaction writes private config and backup", async () => {
  const { path, original } = await fixture();
  const result = await applyConfigTransaction({ livePath: path, candidate: "{\"after\":true}\n", validateCandidate: async () => {}, applyRuntime: async () => {}, verifyAppliedState: async () => "READY", now: () => new Date("2026-09-28T00:00:00Z") });
  assert.equal(result.changed, true); assert.equal(await readFile(path, "utf8"), "{\"after\":true}\n"); assert.equal((await stat(path)).mode & 0o777, 0o600);
  if (result.changed) assert.equal(await readFile(result.backupPath!, "utf8"), original);
});

test("validation failure does not write or back up", async () => {
  const { path, original } = await fixture();
  await assert.rejects(applyConfigTransaction({ livePath: path, candidate: "{}\n", validateCandidate: async () => { throw new Error("invalid"); }, applyRuntime: async () => {}, verifyAppliedState: async () => "READY" }), /invalid/);
  assert.equal(await readFile(path, "utf8"), original);
});

for (const [name, applyRuntime, verifyAppliedState] of [
  ["reload failure", async () => { throw new Error("reload"); }, async () => "READY" as const],
  ["verification failure", async () => {}, async () => "BLOCKED" as const],
] as const) {
  test(`${name} restores exact original`, async () => {
    const { path, original } = await fixture();
    await assert.rejects(applyConfigTransaction({ livePath: path, candidate: "{\"after\":true}\n", validateCandidate: async () => {}, applyRuntime, verifyAppliedState }));
    assert.equal(await readFile(path, "utf8"), original); assert.equal((await stat(path)).mode & 0o777, 0o600);
  });
}

test("write failure restores exact original", async () => {
  const { path, original } = await fixture();
  await assert.rejects(applyConfigTransaction({ livePath: path, candidate: "{\"after\":true}\n", validateCandidate: async () => {}, writeLive: async (livePath) => { await writePrivateFile(livePath, "partial"); throw new Error("disk failure"); }, applyRuntime: async () => {}, verifyAppliedState: async () => "READY" }), /live config write failed/);
  assert.equal(await readFile(path, "utf8"), original);
});

test("failed first install leaves no live config", async () => {
  const directory = await mkdtemp(resolve(tmpdir(), "paseo-transaction-test-")); const path = resolve(directory, "config.json");
  await assert.rejects(applyConfigTransaction({ livePath: path, candidate: "{}\n", validateCandidate: async () => {}, applyRuntime: async () => { throw new Error("reload"); }, verifyAppliedState: async () => "READY" }));
  await assert.rejects(readFile(path, "utf8"), /ENOENT/);
});

test("converged transaction performs no callbacks or backup", async () => {
  const { path, original } = await fixture(); let called = false;
  const result = await applyConfigTransaction({ livePath: path, candidate: original, validateCandidate: async () => { called = true; }, applyRuntime: async () => { called = true; }, verifyAppliedState: async () => { called = true; return "READY"; } });
  assert.deepEqual(result, { changed: false }); assert.equal(called, false);
});
