import type { ExtensionAPI, ToolInfo } from "@earendil-works/pi-coding-agent";
import {
  loadEnabledSettings,
  saveExtensionSettings,
  type EnabledSettings,
} from "../tool-settings/index.js";

export type McpAdapterEnabledSettings = EnabledSettings;

export const MCP_TOGGLE_COMMAND = "cmd:mcp-toggle";
export const MCP_ADAPTER_SETTINGS_KEY = "mcpAdapter";
export const MCP_ADAPTER_SOURCE = "npm:pi-mcp-adapter";
export const MCP_ADAPTER_STATE_CHANGED_EVENT = "mcp-adapter:state-changed";
export const DEFAULT_MCP_ADAPTER_ENABLED_SETTINGS: McpAdapterEnabledSettings = {
  enabled: true,
};

export function loadMcpAdapterEnabledSettings(
  defaults: McpAdapterEnabledSettings = DEFAULT_MCP_ADAPTER_ENABLED_SETTINGS,
): McpAdapterEnabledSettings {
  return loadEnabledSettings(MCP_ADAPTER_SETTINGS_KEY, defaults);
}

export function getMcpAdapterToolNames(
  allTools: Array<Pick<ToolInfo, "name" | "sourceInfo">>,
): string[] {
  return allTools
    .filter((tool) => tool.sourceInfo.source === MCP_ADAPTER_SOURCE)
    .map((tool) => tool.name);
}

export function applyMcpAdapterEnabledState(
  pi: Pick<
    ExtensionAPI,
    "getActiveTools" | "getAllTools" | "setActiveTools" | "events"
  >,
  enabled: boolean,
): void {
  const adapterToolNames = getMcpAdapterToolNames(pi.getAllTools());
  const currentActiveTools = pi.getActiveTools();
  const adapterToolNamesSet = new Set(adapterToolNames);
  const nextActiveTools = enabled
    ? mergeToolNames(currentActiveTools, adapterToolNames)
    : currentActiveTools.filter(
        (toolName) => !adapterToolNamesSet.has(toolName),
      );

  if (!areToolListsEqual(currentActiveTools, nextActiveTools)) {
    pi.setActiveTools(nextActiveTools);
  }

  pi.events.emit(MCP_ADAPTER_STATE_CHANGED_EVENT, enabled);
}

function mergeToolNames(current: string[], additions: string[]): string[] {
  const merged = [...current];
  const seen = new Set(current);

  for (const toolName of additions) {
    if (seen.has(toolName)) {
      continue;
    }

    seen.add(toolName);
    merged.push(toolName);
  }

  return merged;
}

function areToolListsEqual(left: string[], right: string[]): boolean {
  return (
    left.length === right.length &&
    left.every((toolName, index) => toolName === right[index])
  );
}

export default function (pi: ExtensionAPI) {
  const settings = loadMcpAdapterEnabledSettings();

  pi.registerCommand(MCP_TOGGLE_COMMAND, {
    description: "Toggle MCP adapter tools on/off",
    handler: async (_commandArgs, ctx) => {
      const nextEnabled = !settings.enabled;

      saveExtensionSettings({
        extensionKey: MCP_ADAPTER_SETTINGS_KEY,
        enabled: nextEnabled,
      });
      settings.enabled = nextEnabled;

      applyMcpAdapterEnabledState(pi, nextEnabled);
      ctx.ui.notify(
        `MCP adapter ${nextEnabled ? "enabled" : "disabled"}`,
        "info",
      );
    },
  });

  pi.on("session_start", () => {
    applyMcpAdapterEnabledState(pi, settings.enabled);
  });
}
