import type { JsonObject, ModelEntry, ProfilePolicyEntry, ProfilesPolicy, ProviderPolicy, ReconcileBlocker, ReconcileResult } from "../domain/types.ts";
import { stableJson } from "../core/filesystem.ts";

const clone = <T>(value: T): T => structuredClone(value);
const object = (value: unknown): JsonObject => value !== null && typeof value === "object" && !Array.isArray(value) ? value as JsonObject : {};
const array = (value: unknown): unknown[] => Array.isArray(value) ? value : [];

export function providerFamily(provider: string): string {
  if (provider.startsWith("codex")) return "codex";
  if (provider.startsWith("opencode")) return "opencode";
  return provider;
}

function modelCatalog(provider: string, codexModels: unknown, opencodeModels: unknown): ModelEntry[] {
  const raw = providerFamily(provider) === "codex" ? codexModels : providerFamily(provider) === "opencode" ? opencodeModels : [];
  const catalog = Array.isArray(raw) ? raw : array(object(raw).models);
  return catalog.filter((item): item is ModelEntry => item !== null && typeof item === "object");
}

function thinkingIds(entry: ModelEntry): unknown[] {
  if (Array.isArray(entry.thinkingOptionIds)) return entry.thinkingOptionIds;
  return array(entry.thinkingOptions).map((option) => object(option).id ?? option);
}

function supportsPreferences(provider: string, model: unknown, thinking: unknown, codexModels: unknown, opencodeModels: unknown): boolean {
  if (model === null || model === undefined) return thinking === null || thinking === undefined;
  const entry = modelCatalog(provider, codexModels, opencodeModels).find((candidate) => candidate.id === model);
  return entry !== undefined && (thinking === null || thinking === undefined || thinkingIds(entry).includes(thinking));
}

function orderedCandidates(policy: ProfilePolicyEntry, existing: JsonObject, profiles: JsonObject[]): string[] {
  const allowed = policy.allowedProviders;
  if (policy.id === "design-agent-review-v02") {
    const implementation = profiles.find((profile) => profile.id === "design-agent-implementation-v02")?.provider;
    return [...allowed.filter((provider) => provider !== implementation), ...allowed.filter((provider) => provider === implementation)];
  }
  if (policy.id === "design-agent-specialist-v02" && typeof existing.provider === "string" && allowed.includes(existing.provider)) {
    return [...new Set([existing.provider, ...allowed])];
  }
  return allowed;
}

function canonicalProfile(policy: ProfilePolicyEntry, existing: JsonObject, provider: string): JsonObject {
  const profile: JsonObject = { ...existing, id: policy.id, name: policy.name, provider, notes: policy.notes };
  const defaultMode = policy.defaultModeByProvider?.[provider];
  if (Object.keys(existing).length === 0 || existing.modeId === null || existing.modeId === undefined || providerFamily(typeof existing.provider === "string" ? existing.provider : "") !== providerFamily(provider)) {
    if (defaultMode === undefined) delete profile.modeId;
    else profile.modeId = defaultMode;
  }
  return profile;
}

export function reconcileConfig(input: {
  currentConfig: unknown;
  providerPolicy: ProviderPolicy;
  profilePolicy: ProfilesPolicy;
  codexModels: unknown;
  opencodeModels: unknown;
}): ReconcileResult {
  const config = clone(object(input.currentConfig));
  config["$schema"] = "https://paseo.sh/schemas/paseo.config.v1.json";
  config.version = 1;
  config.daemon = object(config.daemon);
  const daemon = config.daemon as JsonObject;
  daemon.mcp = { ...object(daemon.mcp), enabled: true, injectIntoAgents: true };
  config.agents = object(config.agents);
  const agents = config.agents as JsonObject;
  agents.providers = object(agents.providers);
  const providers = agents.providers as JsonObject;
  for (const [id, required] of Object.entries(input.providerPolicy)) {
    providers[id] = { ...object(providers[id]), ...required };
    if (id === "codex-lead") delete (providers[id] as JsonObject).paseoTools;
  }

  const profiles = array(daemon.agentProfiles).map(object);
  const blockers: ReconcileBlocker[] = [];
  for (const policy of input.profilePolicy.profiles) {
    const index = profiles.findIndex((profile) => profile.id === policy.id);
    const existing = index < 0 ? {} : profiles[index];
    const provider = orderedCandidates(policy, existing, profiles).find((candidate) => supportsPreferences(candidate, existing.model, existing.thinkingOptionId, input.codexModels, input.opencodeModels));
    if (provider === undefined) {
      blockers.push({ profileId: policy.id, model: existing.model ?? null, thinkingOptionId: existing.thinkingOptionId ?? null });
      continue;
    }
    const profile = canonicalProfile(policy, existing, provider);
    if (index < 0) profiles.push(profile); else profiles[index] = profile;
  }
  if (blockers.length > 0) return { status: "BLOCKED", blockers };
  daemon.agentProfiles = profiles;
  return { status: "RECONCILED", changed: stableJson(input.currentConfig) !== stableJson(config), config, blockers: [] };
}
