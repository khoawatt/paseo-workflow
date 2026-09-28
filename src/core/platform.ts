import { readFile } from "node:fs/promises";
import { CliError } from "../domain/types.ts";

export async function requireWslUbuntu(env = process.env): Promise<void> {
  const procPath = env.PASEO_WORKFLOW_PROC_VERSION ?? "/proc/version";
  const osPath = env.PASEO_WORKFLOW_OS_RELEASE ?? "/etc/os-release";
  let procVersion: string;
  let osRelease: string;
  try {
    [procVersion, osRelease] = await Promise.all([readFile(procPath, "utf8"), readFile(osPath, "utf8")]);
  } catch {
    throw new CliError("platform metadata is unavailable");
  }
  if (!/(microsoft.*wsl|wsl.*microsoft)/i.test(procVersion)) throw new CliError("V1 supports WSL2 only");
  const id = /^ID=(?:"([^"]+)"|([^\s]+))$/m.exec(osRelease);
  if ((id?.[1] ?? id?.[2]) !== "ubuntu") throw new CliError("V1 supports Ubuntu only");
}
