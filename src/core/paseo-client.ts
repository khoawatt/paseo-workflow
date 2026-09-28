import { runCommand } from "./process.ts";
import type { CommandResult, JsonObject, ProviderDiagnosticState, ProviderFamily } from "../domain/types.ts";

export type PaseoTarget = { kind: "home"; value: string } | { kind: "host"; value: string };

function targetArgs(target: PaseoTarget): string[] {
  return target.kind === "home" ? ["--home", target.value] : ["--host", target.value];
}

export async function runPaseo(args: string[], options: { target?: PaseoTarget; env?: NodeJS.ProcessEnv } = {}): Promise<CommandResult> {
  return await runCommand({ command: "paseo", args: [...(options.target ? targetArgs(options.target) : []), ...args], env: options.env });
}

export function parseJson(text: string): unknown {
  try { return JSON.parse(text); } catch { return undefined; }
}

export function providerDiagnosticState(value: unknown): ProviderDiagnosticState {
  const diagnostic = typeof (value as JsonObject | undefined)?.diagnostic === "string" ? (value as JsonObject).diagnostic as string : "";
  const normalized = diagnostic.toLowerCase();
  if (!diagnostic) return "error";
  if (/resolved\s+path:\s*(not\s+found|missing)/.test(normalized) || /status:\s*(not\s+installed|missing)/.test(normalized) || normalized.includes("command not found")) return "missing";
  if (normalized.includes("status: ready")) return "ready";
  if (["authentication required", "not authenticated", "login required", "unauthorized", "missing credential"].some((phrase) => normalized.includes(phrase))) return "auth_required";
  return "error";
}

export function providerInstallAction(provider: ProviderFamily): string {
  return provider === "codex"
    ? "Install the Codex CLI on the Paseo daemon host, run `codex login`, ensure `codex` is on the daemon PATH, then rerun the bootstrap."
    : "Install OpenCode on the Paseo daemon host, complete its provider authentication, ensure `opencode` is on the daemon PATH, then rerun the bootstrap.";
}

export function providerAuthAction(provider: ProviderFamily): string {
  return provider === "codex"
    ? "Run `codex login` interactively on the Paseo daemon host, then rerun verification."
    : "Complete OpenCode provider authentication interactively on the Paseo daemon host, then rerun verification.";
}

export async function daemonStatus(home: string, env = process.env): Promise<JsonObject> {
  const response = await runPaseo(["daemon", "status", "--json"], { target: { kind: "home", value: home }, env });
  return (parseJson(response.stdout) ?? {}) as JsonObject;
}

export async function healthAvailable(listen: string, env = process.env): Promise<boolean> {
  if (env.FAKE_ROOT && env.FAKE_HEALTHY !== undefined) return env.FAKE_HEALTHY === "1";
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2_000);
    try { return (await fetch(`http://${listen}/api/health`, { signal: controller.signal })).ok; }
    finally { clearTimeout(timeout); }
  } catch { return false; }
}

export async function selectExistingTarget(home: string, env = process.env): Promise<{ target?: PaseoTarget; listen: string; localDaemon: string }> {
  const status = await daemonStatus(home, env);
  const localDaemon = typeof status.localDaemon === "string" ? status.localDaemon : "unknown";
  const listen = typeof status.configuredListen === "string" ? status.configuredListen : "127.0.0.1:6767";
  if (localDaemon === "running" || localDaemon === "ready") return { target: { kind: "home", value: home }, listen, localDaemon };
  if (await healthAvailable(listen, env)) return { target: { kind: "host", value: listen }, listen, localDaemon };
  return { listen, localDaemon };
}
