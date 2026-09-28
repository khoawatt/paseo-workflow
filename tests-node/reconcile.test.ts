import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { reconcileConfig } from "../src/config/reconcile.ts";
import { validateProfilesPolicy, validateProviderPolicy } from "../src/config/policy.ts";
import type { ProfilesPolicy, ProviderPolicy } from "../src/domain/types.ts";

const root = resolve(import.meta.dirname, "..");
const json = async (path: string): Promise<unknown> => JSON.parse(await readFile(resolve(root, path), "utf8"));

test("fresh reconciliation creates the required capability boundary and routing", async () => {
  const providerPolicy = await json("policy/providers.json"); const profilePolicy = await json("policy/profiles.json");
  validateProviderPolicy(providerPolicy); validateProfilesPolicy(profilePolicy);
  const result = reconcileConfig({ currentConfig: {}, providerPolicy, profilePolicy, codexModels: await json("tests/fixtures/models/codex.json"), opencodeModels: await json("tests/fixtures/models/opencode.json") });
  assert.equal(result.status, "RECONCILED");
  if (result.status !== "RECONCILED") return;
  const config = result.config as any;
  assert.deepEqual(Object.keys(config.agents.providers).sort(), ["codex-lead", "codex-worker", "opencode-worker"]);
  assert.deepEqual(config.daemon.agentProfiles.map((profile: any) => profile.provider), ["codex-lead", "opencode-worker", "codex-worker", "opencode-worker", "codex-worker"]);
  assert.equal("paseoTools" in config.agents.providers["codex-lead"], false);
});

test("reconciliation preserves user-owned fields and is idempotent", async () => {
  const providerPolicy = await json("policy/providers.json") as ProviderPolicy; const profilePolicy = await json("policy/profiles.json") as ProfilesPolicy;
  const input = await json("tests/fixtures/config/existing.json"); const codexModels = await json("tests/fixtures/models/codex.json"); const opencodeModels = await json("tests/fixtures/models/opencode.json");
  const first = reconcileConfig({ currentConfig: input, providerPolicy, profilePolicy, codexModels, opencodeModels });
  assert.equal(first.status, "RECONCILED"); if (first.status !== "RECONCILED") return;
  assert.deepEqual((first.config as any).unknownRoot, { nested: [1, 2, 3] });
  assert.equal((first.config as any).agents.providers["codex-worker"].env.EXAMPLE_TOKEN, "fixture-private-value");
  const second = reconcileConfig({ currentConfig: first.config, providerPolicy, profilePolicy, codexModels, opencodeModels });
  assert.equal(second.status, "RECONCILED"); if (second.status === "RECONCILED") assert.equal(second.changed, false);
});

test("incompatible preferences produce a model/provider blocker without config", async () => {
  const result = reconcileConfig({
    currentConfig: await json("tests/fixtures/config/incompatible-model.json"),
    providerPolicy: await json("policy/providers.json") as ProviderPolicy,
    profilePolicy: await json("policy/profiles.json") as ProfilesPolicy,
    codexModels: await json("tests/fixtures/models/codex.json"), opencodeModels: await json("tests/fixtures/models/opencode.json"),
  });
  assert.equal(result.status, "BLOCKED"); if (result.status === "BLOCKED") assert.deepEqual(result.blockers.map((item) => item.profileId), ["design-agent-planning-research-v02"]);
});
