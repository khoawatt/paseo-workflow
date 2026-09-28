import { mkdir, readFile, rm } from "node:fs/promises";
import { resolve } from "node:path";
import { parseArgs } from "node:util";
import { commandExists, runCommand } from "../core/process.ts";
import { makeTempDirectory, pathExists, readJson, stableJson, writePrivateFile } from "../core/filesystem.ts";
import { requireWslUbuntu } from "../core/platform.ts";
import { missingSkills } from "../core/skills.ts";
import { parseJson, providerAuthAction, providerDiagnosticState, providerInstallAction, runPaseo, selectExistingTarget, type PaseoTarget } from "../core/paseo-client.ts";
import { validateProfilesPolicy, validateProviderPolicy } from "../config/policy.ts";
import { reconcileConfig } from "../config/reconcile.ts";
import { configPolicyValid } from "../config/validate.ts";
import { applyConfigTransaction, ConfigTransactionError } from "../config/transaction.ts";
import { renderVerificationHuman, verify } from "./verify.ts";
import { CliError, type ProfilesPolicy, type ProviderFamily, type ProviderPolicy } from "../domain/types.ts";

const PASEO_VERSION = "0.9.1";
const PASEO_PACKAGE = "@getpaseo/cli";

function versionParts(value: string): number[] { return value.replace(/^v/, "").split(".").map((part) => Number.parseInt(part, 10) || 0); }
function versionIsNewer(current: string, pinned: string): boolean {
  const left = versionParts(current); const right = versionParts(pinned);
  for (let index = 0; index < Math.max(left.length, right.length); index++) {
    if ((left[index] ?? 0) !== (right[index] ?? 0)) return (left[index] ?? 0) > (right[index] ?? 0);
  }
  return false;
}

async function ensureDependencies(env: NodeJS.ProcessEnv): Promise<void> {
  if (env.PASEO_WORKFLOW_SKIP_DEPENDENCY_CHECK === "1") return;
  const required = ["git", "node", "npm"];
  const missing = (await Promise.all(required.map(async (name) => [name, await commandExists(name, env)] as const))).filter(([, found]) => !found).map(([name]) => name);
  if (missing.length > 0) throw new CliError(`missing required host dependencies: ${missing.join(", ")}. Install them on WSL2 Ubuntu, then rerun the bootstrap.`);
}

async function paseoVersion(env: NodeJS.ProcessEnv): Promise<string | undefined> {
  const result = await runPaseo(["--version"], { env });
  return result.code === 0 && result.stdout.trim() ? result.stdout.trim() : undefined;
}

async function ensurePaseo(env: NodeJS.ProcessEnv): Promise<void> {
  let current = await paseoVersion(env);
  if (!current) {
    process.stdout.write(`==> Installing ${PASEO_PACKAGE}@${PASEO_VERSION}\n`);
    const installed = await runCommand({ command: "npm", args: ["install", "-g", `${PASEO_PACKAGE}@${PASEO_VERSION}`], env });
    if (installed.code !== 0) throw new CliError(`Paseo installation failed: ${installed.stderr.trim()}`);
    current = await paseoVersion(env);
  } else if (versionIsNewer(current, PASEO_VERSION)) {
    throw new CliError(`installed Paseo ${current} is newer than pinned ${PASEO_VERSION}; automatic downgrade is disabled`);
  } else if (current !== PASEO_VERSION) {
    process.stdout.write(`==> Upgrading Paseo from ${current} to ${PASEO_VERSION}\n`);
    const installed = await runCommand({ command: "npm", args: ["install", "-g", `${PASEO_PACKAGE}@${PASEO_VERSION}`], env });
    if (installed.code !== 0) throw new CliError(`Paseo upgrade failed: ${installed.stderr.trim()}`);
    current = await paseoVersion(env);
  }
  if (current !== PASEO_VERSION) throw new CliError(`Paseo version check failed after install: ${current ?? "missing"}`);
}

async function ensureNativeSkills(env: NodeJS.ProcessEnv): Promise<void> {
  if (env.PASEO_WORKFLOW_SKIP_SKILLS === "1" || (await missingSkills(env)).length === 0) return;
  process.stdout.write("==> Installing native Paseo orchestration skills through the upstream Paseo flow\n");
  process.stderr.write("WARN: current Paseo docs expose no reproducible skill-version pin; selected skills may refresh on host startup\n");
  const installed = await runCommand({ command: "npx", args: ["--yes", "skills", "add", "getpaseo/paseo"], env });
  if (installed.code !== 0 || (await missingSkills(env)).length > 0) throw new CliError("native Paseo skill installation did not provide all required skills");
}

async function selectOrStartTarget(home: string, env: NodeJS.ProcessEnv): Promise<PaseoTarget> {
  const selected = await selectExistingTarget(home, env);
  if (selected.target) return selected.target;
  process.stdout.write("==> Starting the selected Paseo daemon for provider preflight\n");
  const target: PaseoTarget = { kind: "home", value: home };
  const started = await runPaseo(["daemon", "start", "--home", home], { env });
  if (started.code !== 0) throw new CliError(`Paseo daemon could not start. Run: paseo daemon status --json --home "${home}"`);
  return target;
}

async function preflightProvider(provider: ProviderFamily, target: PaseoTarget, env: NodeJS.ProcessEnv): Promise<unknown> {
  const diagnostic = await runPaseo(["provider", "diagnostic", provider, "--json"], { target, env });
  const state = providerDiagnosticState(parseJson(diagnostic.stdout));
  if (state === "missing") throw new CliError(`provider runtime ${provider} is missing. ${providerInstallAction(provider)}`);
  if (state === "auth_required") throw new CliError(`provider runtime ${provider} requires authentication. ${providerAuthAction(provider)}`, 2);
  if (state !== "ready") throw new CliError(provider === "opencode" ? "provider runtime opencode diagnostic is not ready. Run `paseo provider diagnostic opencode --json`; for protocol/version errors follow docs/OPENCODE_COMPATIBILITY.md. paseo-workflow will not install or replace OpenCode." : "provider runtime codex diagnostic is not ready. Run `paseo provider diagnostic codex --json`, correct the user-managed Codex runtime, and rerun.");
  const models = await runPaseo(["provider", "models", provider, "--thinking", "--json"], { target, env });
  if (models.code !== 0) throw new CliError(provider === "opencode" ? "OpenCode model discovery failed after a ready diagnostic. Inspect `paseo provider diagnostic opencode --json` and use docs/OPENCODE_COMPATIBILITY.md only when a protocol/version mismatch is confirmed." : "Codex model discovery failed after a ready diagnostic. Inspect `paseo provider diagnostic codex --json` and correct the external runtime or authentication.");
  const parsed = parseJson(models.stdout);
  if (parsed === undefined) throw new CliError(`${provider} model discovery returned invalid JSON`);
  return parsed;
}

async function reload(target: PaseoTarget, env: NodeJS.ProcessEnv): Promise<void> {
  const result = await runPaseo(["reload", "--json"], { target, env });
  if (result.code !== 0) throw new Error("reload failed");
}

export async function installCommand(args: string[], root: string, env = process.env): Promise<number> {
  let values: ReturnType<typeof parseArgs>["values"];
  try { ({ values } = parseArgs({ args, strict: true, options: { home: { type: "string" }, "dry-run": { type: "boolean" } } })); }
  catch { process.stderr.write("Usage: paseo-workflow install [--home PATH] [--dry-run]\n"); return 2; }
  await requireWslUbuntu(env);
  const dryRun = values["dry-run"] === true;
  await ensureDependencies(env);
  if (!dryRun) { await ensurePaseo(env); await ensureNativeSkills(env); }
  const home = (values.home ?? env.PASEO_HOME ?? resolve(env.HOME ?? "", ".paseo")) as string;
  if (!dryRun) await mkdir(home, { recursive: true });
  const selected = await selectExistingTarget(home, env);
  const target = selected.target ?? (dryRun ? undefined : await selectOrStartTarget(home, env));
  if (!target) throw new CliError(`dry-run cannot inspect providers because the Paseo daemon is not reachable at ${selected.listen}; no host state was changed`);
  const [codexModels, opencodeModels, providersRaw, profilesRaw] = await Promise.all([
    preflightProvider("codex", target, env), preflightProvider("opencode", target, env),
    readJson(resolve(root, "policy/providers.json")), readJson(resolve(root, "policy/profiles.json")),
  ]);
  validateProviderPolicy(providersRaw); validateProfilesPolicy(profilesRaw);
  const configPath = resolve(home, "config.json");
  const current = await pathExists(configPath) ? await readJson(configPath) : {};
  const reconciled = reconcileConfig({ currentConfig: current, providerPolicy: providersRaw as ProviderPolicy, profilePolicy: profilesRaw as ProfilesPolicy, codexModels, opencodeModels });
  if (reconciled.status === "BLOCKED") { process.stderr.write(`status=BLOCKED classification=MODEL/PROVIDER GAP profiles=${reconciled.blockers.map((item) => item.profileId).join(",")}\n`); return 3; }
  process.stdout.write(`status=RECONCILED changed=${reconciled.changed} providers=codex-lead,codex-worker,opencode-worker profiles=design-agent-lead-v02,design-agent-planning-research-v02,design-agent-implementation-v02,design-agent-review-v02,design-agent-specialist-v02\n`);
  const candidate = stableJson(reconciled.config);
  if ((await pathExists(configPath)) && (await readFile(configPath, "utf8")) === candidate) {
    process.stdout.write("Configuration already converged; no backup or write required\n");
    const final = await verify(home, root, env);
    process.stdout.write(renderVerificationHuman(final));
    return final.bootstrapStatus === "READY" ? 0 : final.bootstrapStatus === "AUTH_REQUIRED" ? 2 : 1;
  }
  if (dryRun) { process.stdout.write("DRY_RUN: host configuration would change; no files were written\n"); return 0; }
  const work = await makeTempDirectory("paseo-bootstrap-");
  try {
    const validationHome = resolve(work, "validation-home");
    const transaction = await applyConfigTransaction({
      livePath: configPath, candidate,
      validateCandidate: async () => {
        await mkdir(validationHome, { recursive: true }); await writePrivateFile(resolve(validationHome, "config.json"), candidate);
        const checked = await runPaseo(["daemon", "config", "set", "version", "1"], { target: { kind: "home", value: validationHome }, env });
        if (checked.code !== 0) throw new CliError("native Paseo candidate validation failed");
      },
      applyRuntime: async () => { await reload(target, env); if (!configPolicyValid(await readJson(configPath), providersRaw as ProviderPolicy, profilesRaw as ProfilesPolicy)) throw new Error("policy verification failed"); },
      verifyAppliedState: async () => { const result = await verify(home, root, env); process.stdout.write(renderVerificationHuman(result)); return result.bootstrapStatus; },
      reapplyRuntimeAfterRollback: async () => { try { await reload(target, env); } catch { /* best effort */ } },
      onBackup: (path, sha256) => process.stdout.write(`backup=${path} sha256=${sha256}\n`),
    });
    if (transaction.changed && transaction.verification === "AUTH_REQUIRED") return 2;
    process.stdout.write(`READY: Paseo ${PASEO_VERSION} configuration reconciled, applied, and verified\n`);
    return 0;
  } catch (error) {
    if (error instanceof ConfigTransactionError) {
      process.stderr.write("WARN: apply verification failed; restored previous configuration\n");
      throw new CliError(error.message === "final verification returned BLOCKED" ? "configuration was restored after final verification returned BLOCKED" : "configuration was restored after reload or verification failure");
    }
    throw error;
  } finally { await rm(work, { recursive: true, force: true }); }
}
