#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";
import { resolve } from "node:path";

async function collect(directory: string): Promise<string[]> {
  const entries = await readdir(directory, { withFileTypes: true });
  const paths = await Promise.all(entries.map((entry) => entry.isDirectory() ? collect(resolve(directory, entry.name)) : Promise.resolve(entry.name.endsWith(".json") ? [resolve(directory, entry.name)] : [])));
  return paths.flat();
}

for (const path of [...await collect("policy"), ...await collect("tests/fixtures")]) JSON.parse(await readFile(path, "utf8"));
