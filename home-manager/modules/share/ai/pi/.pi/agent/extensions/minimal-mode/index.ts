/**
 * Minimal Mode - overrides built-in tools with custom rendering:
 * - Collapsed: Shows only the tool call summary (path, pattern, etc.)
 * - Expanded: Shows full output like the built-in renderers
 *
 * Use ctrl+o to toggle between collapsed and expanded views.
 *
 * src: https://github.com/badlogic/pi-mono/blob/3a3e37d39014acc4269171be2a51518f6a71be1f/packages/coding-agent/examples/extensions/minimal-mode.ts
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Clone } from "@sinclair/typebox/value";
import {
  renderEditResult,
  renderFindResult,
  renderGrepResult,
  renderLsResult,
  renderReadResult,
  renderWriteResult,
} from "./renders.js";
import { type BuiltInTools, getBuiltInTools } from "./tool-cache.js";

type ToolName = keyof BuiltInTools;

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

export default function (pi: ExtensionAPI): void {
  registerMinimalTool(pi, "read", renderReadResult);
  //registerMinimalTool(pi, "write", renderWriteResult);
  //registerMinimalTool(pi, "edit", renderEditResult);
  registerMinimalTool(pi, "find", renderFindResult);
  registerMinimalTool(pi, "grep", renderGrepResult);
  registerMinimalTool(pi, "ls", renderLsResult);
}
