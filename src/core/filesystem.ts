import { constants } from "node:fs";
import { access, chmod, copyFile, mkdir, mkdtemp, open, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { createHash } from "node:crypto";
import type { JsonObject } from "../domain/types.ts";

export async function pathExists(path: string): Promise<boolean> {
  try { await access(path, constants.F_OK); return true; } catch { return false; }
}

export async function readJson(path: string): Promise<unknown> {
  return JSON.parse(await readFile(path, "utf8"));
}

export function stableJson(value: unknown): string {
  const normalize = (item: unknown): unknown => {
    if (Array.isArray(item)) return item.map(normalize);
    if (item !== null && typeof item === "object") {
      return Object.fromEntries(Object.entries(item as JsonObject).sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0).map(([key, child]) => [key, normalize(child)]));
    }
    return item;
  };
  return `${JSON.stringify(normalize(value), null, 2)}\n`;
}

export async function writePrivateFile(path: string, content: string): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, content, { mode: 0o600 });
  await chmod(path, 0o600);
}

export async function atomicWritePrivate(path: string, content: string): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  const tempDir = await mkdtemp(join(dirname(path), ".paseo-workflow-"));
  const tempPath = join(tempDir, "config.json");
  try {
    const handle = await open(tempPath, "wx", 0o600);
    try { await handle.writeFile(content); await handle.sync(); } finally { await handle.close(); }
    await chmod(tempPath, 0o600);
    await rename(tempPath, path);
  } finally {
    await rm(tempDir, { recursive: true, force: true });
  }
}

export async function privateCopy(source: string, destination: string): Promise<void> {
  await copyFile(source, destination);
  await chmod(destination, 0o600);
}

export async function sha256File(path: string): Promise<string> {
  return createHash("sha256").update(await readFile(path)).digest("hex");
}

export async function makeTempDirectory(prefix: string): Promise<string> {
  return await mkdtemp(join(process.env.TMPDIR ?? tmpdir(), prefix));
}
