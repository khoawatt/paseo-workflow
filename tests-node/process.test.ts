import test from "node:test";
import assert from "node:assert/strict";
import { runCommand } from "../src/core/process.ts";

test("process adapter preserves argument boundaries without a shell", async () => {
  const payload = "$(printf injected); value with spaces";
  const result = await runCommand({ command: "printf", args: ["%s", payload] });
  assert.equal(result.code, 0); assert.equal(result.stdout, payload);
});

test("missing command returns structured status", async () => {
  const result = await runCommand({ command: "definitely-not-a-real-paseo-command" });
  assert.equal(result.code, 127); assert.match(result.stderr, /ENOENT/);
});

test("abort signal stops a running command", async () => {
  const controller = new AbortController();
  const pending = runCommand({ command: "sleep", args: ["5"], signal: controller.signal });
  controller.abort();
  await assert.rejects(pending, /aborted/i);
});
