import type { JsonObject, ProfilePolicyEntry, ProfilesPolicy, ProviderPolicy } from "../domain/types.ts";

function isObject(value: unknown): value is JsonObject {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function validateProviderPolicy(value: unknown): asserts value is ProviderPolicy {
  if (!isObject(value) || JSON.stringify(Object.keys(value).sort()) !== JSON.stringify(["codex-lead", "codex-worker", "opencode-worker"])) throw new Error("invalid providers policy");
  if (!isObject(value["codex-lead"]) || value["codex-lead"].extends !== "codex") throw new Error("invalid providers policy");
  for (const id of ["codex-worker", "opencode-worker"]) {
    const provider = value[id];
    if (!isObject(provider) || !isObject(provider.paseoTools) || provider.paseoTools.enabled !== false) throw new Error("invalid providers policy");
  }
}

export function validateProfilesPolicy(value: unknown): asserts value is ProfilesPolicy {
  if (!isObject(value) || value.version !== "0.2" || !Array.isArray(value.profiles) || value.profiles.length !== 5) throw new Error("invalid profiles policy");
  for (const raw of value.profiles) {
    if (!isObject(raw)) throw new Error("invalid profiles policy");
    const profile = raw as unknown as ProfilePolicyEntry;
    if (typeof profile.id !== "string" || !profile.id || typeof profile.name !== "string" || !profile.name || typeof profile.notes !== "string" || !profile.notes || !Array.isArray(profile.allowedProviders) || profile.allowedProviders.length === 0) throw new Error("invalid profiles policy");
  }
}
