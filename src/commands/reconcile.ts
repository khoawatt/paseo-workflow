import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { chmod, mkdir, readFile, rename, rm } from "node:fs/promises";
import { parseArgs } from "node:util";
import { readJson, stableJson } from "../core/filesystem.ts";
import { validateProfilesPolicy, validateProviderPolicy } from "../config/policy.ts";
import { reconcileConfig } from "../config/reconcile.ts";
import type { ProfilesPolicy, ProviderPolicy } from "../domain/types.ts";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

export async function reconcileCommand(args: string[], env = process.env): Promise<number> {
  let values: ReturnType<typeof parseArgs>["values"];
  try {
    ({ values } = parseArgs({ args, strict: true, options: {
      input: { type: "string" }, empty: { type: "boolean" }, output: { type: "string" },
      "codex-models": { type: "string" }, "opencode-models": { type: "string" },
    } }));
  } catch {
    process.stderr.write("Usage: paseo-workflow reconcile (--input PATH | --empty) --output PATH --codex-models PATH --opencode-models PATH\n");
    return 2;
  }
  if (!values.output || !values["codex-models"] || !values["opencode-models"] || Boolean(values.empty) === Boolean(values.input)) {
    process.stderr.write("Usage: paseo-workflow reconcile (--input PATH | --empty) --output PATH --codex-models PATH --opencode-models PATH\n");
    return 2;
  }
  const providersPath = env.PASEO_WORKFLOW_PROVIDERS_POLICY ?? resolve(ROOT, "policy/providers.json");
  const profilesPath = env.PASEO_WORKFLOW_PROFILES_POLICY ?? resolve(ROOT, "policy/profiles.json");
  let providers: unknown;
  let profiles: unknown;
  let current: unknown;
  let codexModels: unknown;
  let opencodeModels: unknown;
  try {
    [providers, profiles, current, codexModels, opencodeModels] = await Promise.all([
      readJson(providersPath), readJson(profilesPath), values.empty ? Promise.resolve({}) : readJson(values.input as string),
      readJson(values["codex-models"] as string), readJson(values["opencode-models"] as string),
    ]);
    validateProviderPolicy(providers);
    validateProfilesPolicy(profiles);
  } catch (error) {
    const message = error instanceof Error && /^invalid (providers|profiles) policy$/.test(error.message) ? error.message : "required JSON missing or invalid";
    process.stderr.write(`${message}\n`);
    return 2;
  }
  const result = reconcileConfig({ currentConfig: current, providerPolicy: providers as ProviderPolicy, profilePolicy: profiles as ProfilesPolicy, codexModels, opencodeModels });
  if (result.status === "BLOCKED") {
    process.stderr.write(`status=BLOCKED classification=MODEL/PROVIDER GAP profiles=${result.blockers.map((blocker) => blocker.profileId).join(",")}\n`);
    return 3;
  }
  const output = values.output as string;
  const content = stableJson(result.config);
  const oldContent = values.empty ? stableJson({}) : stableJson(JSON.parse(await readFile(values.input as string, "utf8")));
  await mkdir(dirname(output), { recursive: true });
  const temporary = `${output}.tmp-${process.pid}-${Date.now()}`;
  try {
    await import("node:fs/promises").then(({ writeFile }) => writeFile(temporary, content, { mode: 0o600 }));
    await chmod(temporary, 0o600);
    await rename(temporary, output);
    await chmod(output, 0o600);
  } finally {
    await rm(temporary, { force: true });
  }
  process.stdout.write(`status=RECONCILED changed=${oldContent !== content} providers=codex-lead,codex-worker,opencode-worker profiles=design-agent-lead-v02,design-agent-planning-research-v02,design-agent-implementation-v02,design-agent-review-v02,design-agent-specialist-v02\n`);
  return 0;
}
