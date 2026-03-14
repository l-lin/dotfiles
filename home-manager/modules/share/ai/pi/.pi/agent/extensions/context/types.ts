export type SkillIndexEntry = {
  name: string;
  skillFilePath: string;
  skillDir: string;
};

export type SkillLoadedEntryData = {
  name: string;
  path: string;
};

export type ContextViewData = {
  usage: {
    messageTokens: number;
    contextWindow: number;
    effectiveTokens: number;
    percent: number;
    remainingTokens: number;
    systemPromptTokens: number;
    toolsTokens: number;
    activeTools: number;
  } | null;
  agentFiles: Array<{ path: string; tokens: number }>;
  extensions: string[];
  skills: string[];
  skillDescTokens: number;
  loadedSkills: string[];
  subagents: string[];
  activeToolNames: string[];
  session: { totalTokens: number; totalCost: number };
};

export const SKILL_LOADED_ENTRY = "context:skill_loaded";

export const SYSTEM_FG = "warning";
export const TOOLS_FG = "error";
export const WINDOW_FG = "warning";
export const CONVO_FG = "accent";
export const FREE_FG = "muted";

export const ICON_WINDOW = "";
export const ICON_SYSTEM = "";
export const ICON_TOOLS = "";
export const ICON_AGENTS = "󰎚";
export const ICON_EXTENSIONS = "";
export const ICON_SKILLS = "";
export const ICON_SUBAGENTS = "󰚩";
export const ICON_SESSION = "";
