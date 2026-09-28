import { resolve } from "node:path";
import { realpath, stat } from "node:fs/promises";
import { parseArgs } from "node:util";
import { pathExists, readJson } from "../core/filesystem.ts";
import { runCommand } from "../core/process.ts";
import { validPaseoProjectConfig } from "../config/validate.ts";
import type { JsonObject, ProjectRuntimeStatus } from "../domain/types.ts";

export type ProjectInspection = {
  status: ProjectRuntimeStatus;
  repository: string;
  assessmentMode: "read-only";
  observedManifests: string[];
  observedCommands: string[];
  reason: string;
  nextAction: string;
};

const manifests = ["paseo.json", "package.json", "pnpm-workspace.yaml", "yarn.lock", "package-lock.json", "pyproject.toml", "Cargo.toml", "go.mod", "Makefile"];

function result(status: ProjectRuntimeStatus, repository: string, observedManifests: string[], observedCommands: string[], reason: string): ProjectInspection {
  const nextAction = status === "PROJECT_RUNTIME_READY"
    ? "Register or open the repository in Paseo and verify its configured scripts against the real workspace."
    : status === "PROJECT_RUNTIME_PENDING"
      ? "Human-review the observed commands, then add the smallest documented paseo.json appropriate for this repository."
      : "Resolve the reported repository or configuration problem, then rerun this assessment.";
  return { status, repository, assessmentMode: "read-only", observedManifests, observedCommands, reason, nextAction };
}

export async function inspectProject(target: string, env = process.env): Promise<ProjectInspection> {
  try { if (!(await stat(target)).isDirectory()) throw new Error(); } catch { return result("BLOCKED", target, [], [], "Target repository path does not exist or is not a directory."); }
  const repository = await realpath(target);
  const git = await runCommand({ command: "git", args: ["-C", repository, "rev-parse", "--is-inside-work-tree"], env });
  if (git.code !== 0 || git.stdout.trim() !== "true") return result("BLOCKED", repository, [], [], "Target directory is not a Git repository.");
  const observedManifests = (await Promise.all(manifests.map(async (name) => [name, await pathExists(resolve(repository, name))] as const))).filter(([, exists]) => exists).map(([name]) => name);
  if (observedManifests.includes("paseo.json")) {
    try {
      const config = await readJson(resolve(repository, "paseo.json"));
      if (!validPaseoProjectConfig(config)) throw new Error();
      const scripts = ((config as JsonObject).scripts ?? {}) as JsonObject;
      return result("PROJECT_RUNTIME_READY", repository, observedManifests, Object.values(scripts).map((value) => (value as JsonObject).command as string), "A structurally valid documented paseo.json is present; no project files were changed.");
    } catch { return result("BLOCKED", repository, observedManifests, [], "paseo.json is invalid for the documented Paseo 0.9.1 worktree/scripts shape."); }
  }
  if (observedManifests.includes("package.json")) {
    try {
      const pkg = await readJson(resolve(repository, "package.json")) as JsonObject;
      if (pkg === null || typeof pkg !== "object" || Array.isArray(pkg) || (pkg.scripts != null && (typeof pkg.scripts !== "object" || Array.isArray(pkg.scripts)))) throw new Error();
      const scripts = (pkg.scripts ?? {}) as JsonObject;
      return result("PROJECT_RUNTIME_PENDING", repository, observedManifests, Object.values(scripts).filter((value): value is string => typeof value === "string"), "Node scripts were observed, but no paseo.json exists; V1 does not guess setup, service, port, or lifecycle policy.");
    } catch { return result("BLOCKED", repository, observedManifests, [], "package.json is invalid JSON or its scripts field is not an object."); }
  }
  const reason = observedManifests.length > 0 ? "Project manifests were observed, but V1 has no validated Paseo runtime for them and will not invent commands." : "No recognized runtime manifest or paseo.json was found; project runtime remains pending.";
  return result("PROJECT_RUNTIME_PENDING", repository, observedManifests, [], reason);
}

function renderHuman(value: ProjectInspection): string {
  return `${value.status}: ${value.reason}\nRepository: ${value.repository}\nObserved manifests: ${value.observedManifests.join(", ")}\nObserved commands: ${value.observedCommands.join(", ")}\nNext action: ${value.nextAction}\n`;
}

export async function projectInspectCommand(args: string[]): Promise<number> {
  let values: ReturnType<typeof parseArgs>["values"]; let positionals: string[];
  try { ({ values, positionals } = parseArgs({ args, allowPositionals: true, strict: true, options: { json: { type: "boolean" } } })); }
  catch { process.stderr.write("Usage: paseo-workflow project inspect <repository> [--json]\n"); return 2; }
  if (positionals.length !== 1) { process.stderr.write("Usage: paseo-workflow project inspect <repository> [--json]\n"); return 2; }
  const inspection = await inspectProject(positionals[0]);
  process.stdout.write(values.json ? `${JSON.stringify(inspection, null, 2)}\n` : renderHuman(inspection));
  return inspection.status === "PROJECT_RUNTIME_READY" ? 0 : inspection.status === "PROJECT_RUNTIME_PENDING" ? 2 : 1;
}
