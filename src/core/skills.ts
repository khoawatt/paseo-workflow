import { delimiter, resolve } from "node:path";
import { pathExists } from "./filesystem.ts";

export const REQUIRED_SKILLS = ["paseo", "paseo-handoff", "paseo-committee", "paseo-advisor"] as const;

export async function missingSkills(env = process.env): Promise<string[]> {
  const home = env.HOME ?? "";
  const roots = (env.PASEO_WORKFLOW_SKILL_ROOTS ?? `${resolve(home, ".agents/skills")}:${resolve(home, ".codex/skills")}`).split(delimiter);
  const missing: string[] = [];
  for (const skill of REQUIRED_SKILLS) {
    if (!(await Promise.all(roots.map((root) => pathExists(resolve(root, skill, "SKILL.md"))))).some(Boolean)) missing.push(skill);
  }
  return missing;
}
