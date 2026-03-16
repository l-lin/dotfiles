/**
 * Skill tracker — maintains the ordered list of activated skills for the
 * current session and derives a display name from the SKILL.md file path.
 */
import { dirname, basename } from "path";
import type { ActivatedSkill } from "./types.js";
import { SKILL_MD_FILENAME } from "./types.js";

/**
 * Returns true when the given file path refers to a SKILL.md file.
 */
export function isSkillPath(filePath: string): boolean {
  return basename(filePath) === SKILL_MD_FILENAME;
}

/**
 * Derives a human-readable skill name from its SKILL.md path.
 *
 * Convention: the directory containing SKILL.md is named after the skill
 * (e.g. `.../skills/clarifying-intent/SKILL.md` → `clarifying-intent`).
 * Falls back to the full path when the structure is unexpected.
 */
export function skillNameFromPath(filePath: string): string {
  const dir = dirname(filePath);
  return basename(dir) || filePath;
}

export class SkillTracker {
  private skills = new Map<string, ActivatedSkill>();

  /**
   * Records a skill as activated. Idempotent — repeated reads of the same
   * SKILL.md do not create duplicate entries.
   *
   * @returns The skill entry (new or existing).
   */
  activate(filePath: string): ActivatedSkill {
    const existing = this.skills.get(filePath);
    if (existing) return existing;

    const skill: ActivatedSkill = {
      name: skillNameFromPath(filePath),
      path: filePath,
      activatedAt: new Date(),
    };
    this.skills.set(filePath, skill);
    return skill;
  }

  /** All activated skills in insertion order. */
  list(): ActivatedSkill[] {
    return [...this.skills.values()];
  }

  /** Remove all entries (called on session_start to reset state). */
  reset(): void {
    this.skills.clear();
  }
}
