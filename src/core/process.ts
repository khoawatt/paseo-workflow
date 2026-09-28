import { spawn } from "node:child_process";
import type { CommandResult } from "../domain/types.ts";

export type RunCommandOptions = {
  command: string;
  args?: string[];
  cwd?: string;
  env?: NodeJS.ProcessEnv;
  input?: string;
  signal?: AbortSignal;
};

export async function runCommand(options: RunCommandOptions): Promise<CommandResult> {
  return await new Promise((resolve, reject) => {
    let settled = false;
    const child = spawn(options.command, options.args ?? [], {
      cwd: options.cwd,
      env: options.env,
      signal: options.signal,
      shell: false,
      stdio: [options.input === undefined ? "ignore" : "pipe", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    child.stdout!.setEncoding("utf8").on("data", (chunk: string) => { stdout += chunk; });
    child.stderr!.setEncoding("utf8").on("data", (chunk: string) => { stderr += chunk; });
    child.on("error", (error: NodeJS.ErrnoException) => {
      if (settled) return;
      settled = true;
      if (error.code === "ENOENT") resolve({ code: 127, stdout, stderr: error.message });
      else reject(error);
    });
    child.on("close", (code) => {
      if (settled) return;
      settled = true;
      resolve({ code: code ?? 1, stdout, stderr });
    });
    if (options.input !== undefined) child.stdin!.end(options.input);
  });
}

export async function commandExists(command: string, env = process.env): Promise<boolean> {
  const pathValue = env.PATH ?? "";
  const delimiter = process.platform === "win32" ? ";" : ":";
  const { access } = await import("node:fs/promises");
  const { constants } = await import("node:fs");
  const { join } = await import("node:path");
  for (const directory of pathValue.split(delimiter)) {
    if (!directory) continue;
    try {
      await access(join(directory, command), constants.X_OK);
      return true;
    } catch { /* keep searching */ }
  }
  return false;
}
