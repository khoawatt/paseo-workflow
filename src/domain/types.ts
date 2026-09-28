export type JsonObject = Record<string, unknown>;

export type BootstrapStatus = "READY" | "AUTH_REQUIRED" | "BLOCKED";
export type ProjectRuntimeStatus = "PROJECT_RUNTIME_READY" | "PROJECT_RUNTIME_PENDING" | "BLOCKED";
export type ProviderFamily = "codex" | "opencode";
export type ProviderDiagnosticState = "ready" | "missing" | "auth_required" | "error";

export type CommandResult = {
  code: number;
  stdout: string;
  stderr: string;
};

export type ProviderPolicy = Record<string, JsonObject>;

export type ProfilePolicyEntry = {
  id: string;
  name: string;
  notes: string;
  allowedProviders: string[];
  defaultModeByProvider?: Record<string, string>;
};

export type ProfilesPolicy = {
  version: string;
  profiles: ProfilePolicyEntry[];
};

export type ModelEntry = {
  id?: unknown;
  thinkingOptionIds?: unknown;
  thinkingOptions?: unknown;
};

export type ReconcileBlocker = {
  profileId: string;
  model: unknown;
  thinkingOptionId: unknown;
};

export type ReconcileResult =
  | { status: "RECONCILED"; changed: boolean; config: JsonObject; blockers: [] }
  | { status: "BLOCKED"; blockers: ReconcileBlocker[] };

export class CliError extends Error {
  readonly exitCode: number;

  constructor(message: string, exitCode = 1) {
    super(message);
    this.exitCode = exitCode;
  }
}
