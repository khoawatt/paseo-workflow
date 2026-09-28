import { resolve } from "node:path";
import { parseArgs } from "node:util";
import { readJson, pathExists } from "../core/filesystem.ts";
import { requireWslUbuntu } from "../core/platform.ts";
import { missingSkills } from "../core/skills.ts";
import { parseJson, providerAuthAction, providerDiagnosticState, providerInstallAction, runPaseo, selectExistingTarget } from "../core/paseo-client.ts";
import { validateProfilesPolicy, validateProviderPolicy } from "../config/policy.ts";
import { configPolicyValid } from "../config/validate.ts";
import type { BootstrapStatus, JsonObject, ProfilesPolicy, ProviderFamily, ProviderPolicy } from "../domain/types.ts";

export type VerificationResult = {
  paseoVersion: string;
  bootstrapStatus: BootstrapStatus;
  checks: {
    platform: "WSL2 Ubuntu";
    config: string;
    providers: string;
    profiles: string;
    skills: string;
    daemon: string;
    providerRuntimes: Record<ProviderFamily, string>;
  };
  runtime: { profileDiscovery: "not tested"; capabilityBoundary: "not tested" };
  blockers: string[];
  authRequired: string[];
  observedMismatches: string[];
};

function providerEntries(value: unknown): JsonObject[] {
  if (Array.isArray(value)) return value.filter((item): item is JsonObject => item !== null && typeof item === "object");
  const providers = (value as JsonObject | undefined)?.providers;
  return Array.isArray(providers) ? providers.filter((item): item is JsonObject => item !== null && typeof item === "object") : [];
}

export async function verify(home: string, root: string, env = process.env): Promise<VerificationResult> {
  await requireWslUbuntu(env);
  const blockers: string[] = [];
  const authRequired: string[] = [];
  let configStatus = "valid";
  let profilesStatus = "valid";
  let skillsStatus = "available";
  let providersStatus = "available";
  let daemonState = "available";
  const configPath = resolve(home, "config.json");
  try {
    const [config, providers, profiles] = await Promise.all([readJson(configPath), readJson(resolve(root, "policy/providers.json")), readJson(resolve(root, "policy/profiles.json"))]);
    validateProviderPolicy(providers); validateProfilesPolicy(profiles);
    if (!configPolicyValid(config, providers as ProviderPolicy, profiles as ProfilesPolicy)) { configStatus = "policy mismatch"; profilesStatus = "policy mismatch"; blockers.push("required provider/profile policy is not reconciled"); }
  } catch (error) {
    if (!(await pathExists(configPath))) { configStatus = "missing"; blockers.push("Paseo config is missing"); }
    else { configStatus = "invalid"; blockers.push("Paseo config is not valid JSON"); }
    profilesStatus = "not tested";
  }

  const missing = await missingSkills(env);
  if (missing.length > 0) { skillsStatus = "missing"; blockers.push(...missing.map((skill) => `native skill is missing: ${skill}`)); }

  const selection = await selectExistingTarget(home, env);
  if (!selection.target) { daemonState = "unreachable"; blockers.push(`Paseo daemon is not reachable at ${selection.listen}`); }
  const runtimeStates: Record<ProviderFamily, string> = { codex: "not tested", opencode: "not tested" };
  let providerList: unknown;
  if (selection.target) {
    for (const provider of ["codex", "opencode"] as const) {
      const diagnostic = await runPaseo(["provider", "diagnostic", provider, "--json"], { target: selection.target, env });
      const state = providerDiagnosticState(parseJson(diagnostic.stdout));
      runtimeStates[provider] = state;
      if (state === "missing") { providersStatus = "missing"; blockers.push(`provider runtime ${provider} is missing. ${providerInstallAction(provider)}`); }
      else if (state === "auth_required") { providersStatus = "authentication required"; authRequired.push(`provider runtime ${provider} requires authentication. ${providerAuthAction(provider)}`); }
      else if (state === "error") {
        providersStatus = "error";
        blockers.push(provider === "opencode" ? "provider runtime opencode diagnostic is not ready. Run: paseo provider diagnostic opencode --json. If it reports a protocol/version error, follow docs/OPENCODE_COMPATIBILITY.md; paseo-workflow will not replace the user-managed runtime." : "provider runtime codex diagnostic is not ready. Run: paseo provider diagnostic codex --json, correct the user-managed runtime, then rerun verification.");
      }
    }
    const listing = await runPaseo(["provider", "ls", "--json"], { target: selection.target, env });
    if (listing.code === 0 && listing.stdout.trim()) providerList = parseJson(listing.stdout);
    else { providersStatus = "not discoverable"; blockers.push("Paseo provider discovery failed"); }
  }
  if (providerList !== undefined) {
    for (const provider of ["codex-lead", "codex-worker", "opencode-worker"] as const) {
      const entry = providerEntries(providerList).find((candidate) => (candidate.provider ?? candidate.id) === provider);
      const state = typeof entry?.status === "string" ? entry.status : "missing";
      if (state === "available") continue;
      const family: ProviderFamily = provider === "opencode-worker" ? "opencode" : "codex";
      if (["auth_required", "missing", "error"].includes(runtimeStates[family])) continue;
      providersStatus = "unavailable";
      blockers.push(`required provider capability class ${provider} is ${state} even though its external runtime is ready; inspect Paseo provider policy and rerun verification`);
    }
  }
  const version = await runPaseo(["--version"], { env });
  const bootstrapStatus: BootstrapStatus = blockers.length > 0 ? "BLOCKED" : authRequired.length > 0 ? "AUTH_REQUIRED" : "READY";
  return {
    paseoVersion: version.code === 0 && version.stdout.trim() ? version.stdout.trim() : "unknown",
    bootstrapStatus,
    checks: { platform: "WSL2 Ubuntu", config: configStatus, providers: providersStatus, profiles: profilesStatus, skills: skillsStatus, daemon: daemonState, providerRuntimes: runtimeStates },
    runtime: { profileDiscovery: "not tested", capabilityBoundary: "not tested" }, blockers, authRequired,
    observedMismatches: ["Paseo 0.9.1 public config schema omits daemon.agentProfiles although the runtime consumes it"],
  };
}

export function renderVerificationHuman(result: VerificationResult): string {
  const checks = Object.entries(result.checks).map(([key, value]) => `${key}=${typeof value === "object" ? JSON.stringify(value) : value}`).join(", ");
  return [`Bootstrap status: ${result.bootstrapStatus}`, `Paseo version: ${result.paseoVersion}`, `Checks: ${checks}`, ...result.blockers.map((item) => `BLOCKED: ${item}`), ...result.authRequired.map((item) => `AUTH_REQUIRED: ${item}`)].join("\n") + "\n";
}

export async function verifyCommand(args: string[], root: string, env = process.env): Promise<number> {
  let values: ReturnType<typeof parseArgs>["values"];
  try { ({ values } = parseArgs({ args, strict: true, options: { home: { type: "string" }, json: { type: "boolean" } } })); }
  catch { process.stderr.write("Usage: paseo-workflow verify [--home PATH] [--json]\n"); return 2; }
  const home = values.home ?? env.PASEO_HOME ?? resolve(env.HOME ?? "", ".paseo");
  const result = await verify(home as string, root, env);
  process.stdout.write(values.json ? `${JSON.stringify(result, null, 2)}\n` : renderVerificationHuman(result));
  return result.bootstrapStatus === "READY" ? 0 : result.bootstrapStatus === "AUTH_REQUIRED" ? 2 : 1;
}
