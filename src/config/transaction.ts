import { chmod, mkdir, open, readFile, rm } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { atomicWritePrivate, pathExists, sha256File } from "../core/filesystem.ts";

export type ConfigTransactionResult = { changed: false } | { changed: true; backupPath?: string; backupSha256?: string; verification: "READY" | "AUTH_REQUIRED" };

export class ConfigTransactionError extends Error {
  readonly rolledBack = true;
  constructor(message: string, options?: ErrorOptions) { super(message, options); }
}

export async function applyConfigTransaction(options: {
  livePath: string;
  candidate: string;
  validateCandidate: () => Promise<void>;
  applyRuntime: () => Promise<void>;
  verifyAppliedState: () => Promise<"READY" | "AUTH_REQUIRED" | "BLOCKED">;
  reapplyRuntimeAfterRollback?: () => Promise<void>;
  onBackup?: (path: string, sha256: string) => void;
  writeLive?: (path: string, content: string) => Promise<void>;
  now?: () => Date;
}): Promise<ConfigTransactionResult> {
  const existing = await pathExists(options.livePath) ? await readFile(options.livePath) : undefined;
  const candidate = Buffer.from(options.candidate);
  if (existing?.equals(candidate)) return { changed: false };
  await options.validateCandidate();
  await mkdir(dirname(options.livePath), { recursive: true });
  let backupPath: string | undefined;
  let backupSha256: string | undefined;
  if (existing) {
    const timestamp = (options.now?.() ?? new Date()).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
    backupPath = resolve(dirname(options.livePath), `config.json.backup-bootstrap-${timestamp}`);
    const backup = await open(backupPath, "wx", 0o600);
    try { await backup.writeFile(existing); await backup.sync(); } finally { await backup.close(); }
    await chmod(backupPath, 0o600);
    backupSha256 = await sha256File(backupPath);
    options.onBackup?.(backupPath, backupSha256);
  }
  const writeLive = options.writeLive ?? atomicWritePrivate;
  try {
    await writeLive(options.livePath, options.candidate);
  } catch (error) {
    if (existing) await atomicWritePrivate(options.livePath, existing.toString("utf8"));
    else await rm(options.livePath, { force: true });
    throw new ConfigTransactionError("live config write failed", { cause: error });
  }
  const rollback = async (): Promise<void> => {
    if (existing) await atomicWritePrivate(options.livePath, existing.toString("utf8"));
    else await rm(options.livePath, { force: true });
    try { await options.reapplyRuntimeAfterRollback?.(); } catch { /* best effort */ }
  };
  try {
    await options.applyRuntime();
    const verification = await options.verifyAppliedState();
    if (verification === "BLOCKED") throw new Error("final verification returned BLOCKED");
    return { changed: true, backupPath, backupSha256, verification };
  } catch (error) {
    await rollback();
    throw new ConfigTransactionError(error instanceof Error ? error.message : String(error), { cause: error });
  }
}
