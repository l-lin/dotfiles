/**
 * Minimal Mode - re-renders the built-in `read` tool with compact output and
 * disables search and listing helpers that do not fit this mode:
 * - Collapsed: Shows only the tool call summary (path, pattern, etc.)
 * - Expanded: Shows full output like the built-in renderer
 *
 * Disabled tools: find, grep, ls
 *
 * Use ctrl+o to toggle between collapsed and expanded views.
 *
 * src: https://github.com/badlogic/pi-mono/blob/3a3e37d39014acc4269171be2a51518f6a71be1f/packages/coding-agent/examples/extensions/minimal-mode.ts
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Clone } from "@sinclair/typebox/value";
import { renderReadResult } from "./renders.js";
import { type BuiltInTools, getBuiltInTools } from "./tool-cache.js";

type ToolName = keyof BuiltInTools;

const DISABLED_TOOL_NAMES = new Set(["find", "grep", "ls"]);

function registerMinimalTool(
  pi: ExtensionAPI,
  name: ToolName,
  renderResult: any,
): void {
  const builtInTool = getBuiltInTools(process.cwd())[name];

  pi.registerTool({
    ...builtInTool,
    parameters: Clone(builtInTool.parameters),
    renderResult,
  } as any);
}

function removeDisabledTools(pi: ExtensionAPI): void {
  const activeTools = pi.getActiveTools();
  const nextActiveTools = activeTools.filter(
    (toolName) => !DISABLED_TOOL_NAMES.has(toolName),
  );

  if (nextActiveTools.length === activeTools.length) return;
  pi.setActiveTools(nextActiveTools);
}

export default function (pi: ExtensionAPI): void {
  registerMinimalTool(pi, "read", renderReadResult);

  pi.on("session_start", async () => {
    removeDisabledTools(pi);
  });

  // We should no need to guard, but I'm being paranoid, so let's keep this snippet just in case.
  // pi.on("tool_call", async (event) => {
  //   if (!DISABLED_TOOL_NAMES.has(event.toolName)) return undefined;
  //
  //   return {
  //     block: true,
  //     reason: `${event.toolName} is disabled`,
  //   };
  // });
}
