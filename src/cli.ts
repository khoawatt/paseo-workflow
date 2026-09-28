#!/usr/bin/env node
import { reconcileCommand } from "./commands/reconcile.ts";
import { projectInspectCommand } from "./commands/project-inspect.ts";
import { verifyCommand } from "./commands/verify.ts";
import { installCommand } from "./commands/install.ts";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { CliError } from "./domain/types.ts";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

const HELP = `Usage: paseo-workflow <command> [options]

Commands:
  install [--home PATH] [--dry-run]
  verify [--home PATH] [--json]
  project inspect <repository> [--json]
`;

export async function main(args = process.argv.slice(2)): Promise<number> {
  if (args.length === 0 || args[0] === "--help" || args[0] === "-h") { process.stdout.write(HELP); return 0; }
  if (args[0] === "reconcile") return await reconcileCommand(args.slice(1));
  if (args[0] === "verify") return await verifyCommand(args.slice(1), ROOT);
  if (args[0] === "install") return await installCommand(args.slice(1), ROOT);
  if (args[0] === "project" && args[1] === "inspect") return await projectInspectCommand(args.slice(2));
  process.stderr.write(HELP);
  return 2;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try { process.exitCode = await main(); }
  catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    process.stderr.write(`${error instanceof CliError && error.exitCode === 2 ? "AUTH_REQUIRED" : "BLOCKED"}: ${message}\n`);
    process.exitCode = error instanceof CliError ? error.exitCode : 1;
  }
}
