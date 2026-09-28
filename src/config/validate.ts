import type { JsonObject, ProfilesPolicy, ProviderPolicy } from "../domain/types.ts";

const object = (value: unknown): JsonObject | undefined => value !== null && typeof value === "object" && !Array.isArray(value) ? value as JsonObject : undefined;

function deepEqual(left: unknown, right: unknown): boolean {
  return JSON.stringify(left) === JSON.stringify(right);
}

export function configPolicyValid(configValue: unknown, providersPolicy: ProviderPolicy, profilesPolicy: ProfilesPolicy): boolean {
  const config = object(configValue);
  const daemon = object(config?.daemon);
  const mcp = object(daemon?.mcp);
  const agents = object(config?.agents);
  const providers = object(agents?.providers);
  if (!config || !daemon || !mcp || !providers || mcp.enabled !== true || mcp.injectIntoAgents !== true) return false;
  for (const [id, requiredValue] of Object.entries(providersPolicy)) {
    const actual = object(providers[id]);
    if (!actual) return false;
    for (const [field, expected] of Object.entries(requiredValue)) if (!deepEqual(actual[field], expected)) return false;
  }
  if (Object.hasOwn(object(providers["codex-lead"]) ?? {}, "paseoTools")) return false;
  const profiles = Array.isArray(daemon.agentProfiles) ? daemon.agentProfiles.map(object).filter((profile): profile is JsonObject => profile !== undefined) : [];
  for (const required of profilesPolicy.profiles) {
    const matches = profiles.filter((profile) => profile.id === required.id);
    if (matches.length !== 1 || matches[0].name !== required.name || matches[0].notes !== required.notes || typeof matches[0].provider !== "string" || !required.allowedProviders.includes(matches[0].provider)) return false;
  }
  return true;
}

export function validPaseoProjectConfig(value: unknown): boolean {
  const root = object(value);
  if (!root) return false;
  const worktree = root.worktree == null ? {} : object(root.worktree);
  const scripts = root.scripts == null ? {} : object(root.scripts);
  if (!worktree || !scripts) return false;
  for (const field of ["setup", "teardown"] as const) {
    const entry = worktree[field];
    if (entry != null && typeof entry !== "string" && (!Array.isArray(entry) || !entry.every((item) => typeof item === "string"))) return false;
  }
  for (const rawScript of Object.values(scripts)) {
    const script = object(rawScript);
    if (!script || typeof script.command !== "string" || script.command.length === 0) return false;
    if (script.type != null && script.type !== "script" && script.type !== "service") return false;
    if (script.port != null && (typeof script.port !== "number" || script.port < 1 || script.port > 65535)) return false;
  }
  return true;
}
