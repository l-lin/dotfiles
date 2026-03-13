/**
 * Constants and type definitions
 */

import * as os from "node:os";
import * as path from "node:path";

export const SETTINGS_PATH = path.join(
  os.homedir(),
  ".pi",
  "agent",
  "settings.json",
);

export const ICONS: Record<string, string> = {
  "token-usage": "",
  "cost": "",
  "thinking-level": "󰧑",
  "model": " ",
  "cwd": "",
  "branch": "󰘬",
}

export const TOOL_ICONS: Record<string, { enabled: string; disabled: string }> =
  {
    "ask-user-question": { enabled: "󰍡", disabled: "󱙍" },
    subagent: { enabled: "󰚩", disabled: "󱚧" },
    "web-fetch": { enabled: "󰖟", disabled: "󰪎" },
    "web-search": { enabled: "󰩄", disabled: "󱛮" },
  };

export const TOOL_ORDER: Array<keyof typeof TOOL_ICONS> = [
  "ask-user-question",
  "subagent",
  "web-fetch",
  "web-search",
];

export type ThinkingLevel =
  | "off"
  | "minimal"
  | "low"
  | "medium"
  | "high"
  | "xhigh";

export interface SettingsStructure {
  extensionSettings?: {
    webFetch?: { enabled?: boolean };
    webSearch?: { enabled?: boolean };
    subagent?: { enabled?: boolean };
    askUserQuestion?: { enabled?: boolean };
  };
}
