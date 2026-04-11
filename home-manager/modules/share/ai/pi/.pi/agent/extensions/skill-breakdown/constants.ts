import os from "node:os";
import path from "node:path";

export {
  DEFAULT_BG,
  EMPTY_CELL_BG,
  LIGHT_BG,
  LIGHT_EMPTY_CELL_BG,
  PALETTE,
  RANGE_DAYS,
} from "../session-breakdown/constants.js";

export const TOP_SKILLS_LIMIT = 10;
export const LEAST_USED_SKILLS_LIMIT = 20;
export const SEARCH_MATCH_LIMIT = 5;
export const OTHER_COLOR = { r: 160, g: 160, b: 160 };
export const LOADER_BASE_MESSAGE = "Analyzing skill usage (last 90 days)…";
export const ALL_MODELS_LABEL = "all models";
export const UNKNOWN_PROJECT_LABEL = "(unknown project)";
export const UNKNOWN_MODEL_LABEL = "(unknown model)";

export function getSessionRoot(): string {
  return path.join(os.homedir(), ".pi", "agent", "sessions");
}
