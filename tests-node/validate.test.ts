import test from "node:test";
import assert from "node:assert/strict";
import { configPolicyValid } from "../src/config/validate.ts";
import type { ProfilesPolicy, ProviderPolicy } from "../src/domain/types.ts";

test("policy validation compares owned objects independent of key order", () => {
  const providers: ProviderPolicy = {
    "codex-lead": { extends: "codex", label: "Codex Lead" },
    "codex-worker": { extends: "codex", label: "Codex Worker", paseoTools: { enabled: false, futureFlag: true } },
    "opencode-worker": { extends: "opencode", label: "OpenCode Worker", paseoTools: { enabled: false } },
  };
  const profiles: ProfilesPolicy = { version: "0.2", profiles: [] };
  const config = {
    daemon: { mcp: { enabled: true, injectIntoAgents: true }, agentProfiles: [] },
    agents: { providers: {
      "codex-lead": { label: "Codex Lead", extends: "codex" },
      "codex-worker": { label: "Codex Worker", extends: "codex", paseoTools: { futureFlag: true, enabled: false } },
      "opencode-worker": { label: "OpenCode Worker", extends: "opencode", paseoTools: { enabled: false } },
    } },
  };
  assert.equal(configPolicyValid(config, providers, profiles), true);
});
