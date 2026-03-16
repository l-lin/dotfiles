import { dirname, basename } from "path";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { ActivatedSkill } from "./types.js";
import { SKILL_MD_FILENAME } from "./types.js";

// Local types for casting untyped session history entries
type HistoryMessageEntry = { message: { role: string; content?: unknown[] } };
type ToolCallBlock = {
  type?: string;
  name?: string;
  arguments?: { path?: string };
};

export function isSkillPath(filePath: string): boolean {
  return basename(filePath) === SKILL_MD_FILENAME;
}

/**
 * Derives skill name from path: `.../skills/clarifying-intent/SKILL.md` → `clarifying-intent`.
 *
 * @param filePath The full file path to the skill markdown file.
 * @returns The skill name, or the full path if it can't be derived (e.g., if the path doesn't have a parent directory).
 */
export function skillNameFromPath(filePath: string): string {
  const dir = dirname(filePath);
  return basename(dir) || filePath;
}

export class SkillTracker {
  private skills = new Map<string, ActivatedSkill>();

  /**
   * Records a skill as activated. Idempotent — repeated reads don't create duplicates.
   *
   * @param filePath The full file path to the activated skill's markdown file.
   * @returns The activated skill object, including name, path, and activation timestamp.
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

  list(): ActivatedSkill[] {
    return [...this.skills.values()];
  }

  reset(): void {
    this.skills.clear();
  }

  /**
   * Reconstructs activated skills by scanning existing session message history.
   * Used when resuming a session or after /reload.
   *
   * @param ctx The extension context, providing access to session history.
   */
  rebuildFromHistory(ctx: ExtensionContext): void {
    this.reset();

    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type !== "message") continue;

      const msg = (entry as HistoryMessageEntry).message;
      if (msg.role !== "assistant" || !Array.isArray(msg.content)) continue;

      for (const block of msg.content as ToolCallBlock[]) {
        if (block.type !== "toolCall" || block.name !== "read") continue;
        const path = block.arguments?.path;
        if (path && isSkillPath(path)) this.activate(path);
      }
    }
  }
}
