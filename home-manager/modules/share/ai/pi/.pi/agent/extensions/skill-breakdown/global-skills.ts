import os from "node:os";
import path from "node:path";
import { loadSkillsFromDir } from "@mariozechner/pi-coding-agent";
import type { SkillName } from "./types.js";

export function getGlobalUserSkillsRoot(): string {
  const configHome =
    process.env.XDG_CONFIG_HOME ?? path.join(os.homedir(), ".config");
  return path.join(configHome, "ai", "skills");
}

export function loadGlobalUserSkillNames(
  skillRoot: string | null = getGlobalUserSkillsRoot(),
): SkillName[] {
  if (!skillRoot) return [];

  const { skills } = loadSkillsFromDir({
    dir: skillRoot,
    source: "user",
  });

  return [
    ...new Set(skills.map((skill) => skill.name.trim()).filter(Boolean)),
  ].sort((left, right) => left.localeCompare(right));
}
