import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { inspectProject } from "../src/commands/project-inspect.ts";
import { runCommand } from "../src/core/process.ts";

test("project inspection preserves legacy null-as-absent semantics", async () => {
  const repository = await mkdtemp(resolve(tmpdir(), "paseo-project-test-"));
  assert.equal((await runCommand({ command: "git", args: ["-C", repository, "init", "-q"] })).code, 0);
  await writeFile(resolve(repository, "paseo.json"), JSON.stringify({ worktree: null, scripts: { test: { command: "npm test", type: null, port: null } } }));
  const inspection = await inspectProject(repository);
  assert.equal(inspection.status, "PROJECT_RUNTIME_READY");
  assert.deepEqual(inspection.observedCommands, ["npm test"]);
});

test("package scripts null remains a pending read-only assessment", async () => {
  const repository = await mkdtemp(resolve(tmpdir(), "paseo-project-test-"));
  assert.equal((await runCommand({ command: "git", args: ["-C", repository, "init", "-q"] })).code, 0);
  await writeFile(resolve(repository, "package.json"), JSON.stringify({ scripts: null }));
  const inspection = await inspectProject(repository);
  assert.equal(inspection.status, "PROJECT_RUNTIME_PENDING");
  assert.deepEqual(inspection.observedCommands, []);
});
