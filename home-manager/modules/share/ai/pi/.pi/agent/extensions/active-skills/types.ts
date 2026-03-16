export interface ActivatedSkill {
  /** Kebab-case skill name derived from the SKILL.md path */
  name: string;
  /** Absolute path to the SKILL.md file that was read */
  path: string;
  /** When the skill was first activated in this session */
  activatedAt: Date;
}

export const ICON_SKILL = "";
export const SKILL_MD_FILENAME = "SKILL.md";
