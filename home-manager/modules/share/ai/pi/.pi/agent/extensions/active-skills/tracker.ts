/**
 * Skill tracker — maintains the ordered list of activated skills for the
 * current session and derives a display name from the SKILL.md file path.
 */
import { dirname, basename } from "path";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
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

  /**
   * Reconstructs activated skills by scanning existing session message entries.
   * Used when resuming a session or after a /reload, so the widget reflects
   * skills that were read in previous turns of the current session.
   *
   * Looks at all assistant messages in the current branch and extracts
   * `read` tool calls whose `path` argument points to a SKILL.md file.
   */
  rebuildFromHistory(ctx: ExtensionContext): void {
    this.reset();

    const entries = ctx.sessionManager.getEntries();
    for (const entry of entries) {
      if (entry.type !== "message") continue;
      // SessionMessageEntry — message is typed as AgentMessage (Message | custom)
      const msg = (
        entry as {
          type: "message";
          message: { role: string; content?: unknown[] };
        }
      ).message;
      if (msg.role !== "assistant" || !Array.isArray(msg.content)) continue;

      for (const block of msg.content) {
        const b = block as {
          type?: string;
          name?: string;
          arguments?: { path?: string };
        };
        if (
          typeof b !== "object" ||
          b === null ||
          b.type !== "toolCall" ||
          b.name !== "read"
        )
          continue;

        const path = b.arguments?.path;
        if (path && isSkillPath(path)) {
          this.activate(path);
        }
      }
    }
  }
}
