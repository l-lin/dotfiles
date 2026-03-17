/**
 * Minimal Mode - overrides built-in tools with custom rendering:
 * - Collapsed: Shows only the tool call summary (path, pattern, etc.)
 * - Expanded: Shows full output like the built-in renderers
 *
 * Use ctrl+o to toggle between collapsed and expanded views.
 *
 * src: https://github.com/badlogic/pi-mono/blob/3a3e37d39014acc4269171be2a51518f6a71be1f/packages/coding-agent/examples/extensions/minimal-mode.ts
 * Adapted to remove the bash tool override (used by rtk-rewrite extension).
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  renderEditCall,
  renderEditResult,
  renderFindCall,
  renderFindResult,
  renderGrepCall,
  renderGrepResult,
  renderLsCall,
  renderLsResult,
  renderReadCall,
  renderReadResult,
  renderWriteCall,
  renderWriteResult,
} from "./renders.js";
import { type BuiltInTools, getBuiltInTools } from "./tool-cache.js";

type ToolName = keyof Omit<BuiltInTools, "bash">;

function registerMinimalTool(
  pi: ExtensionAPI,
  name: ToolName,
  renderCall: (args: any, theme: any) => any,
  renderResult: (
    result: any,
    options: { expanded: boolean },
    theme: any,
  ) => any,
): void {
  const builtIn = getBuiltInTools(process.cwd());
  pi.registerTool({
    name,
    label: name,
    description: builtIn[name].description,
    parameters: builtIn[name].parameters,
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return getBuiltInTools(ctx.cwd)[name].execute(
        toolCallId,
        params,
        signal as AbortSignal,
        onUpdate,
      );
    },
    renderCall,
    renderResult,
  });
}

export default function (pi: ExtensionAPI): void {
  registerMinimalTool(pi, "read", renderReadCall, renderReadResult);
  registerMinimalTool(pi, "write", renderWriteCall, renderWriteResult);
  registerMinimalTool(pi, "edit", renderEditCall, renderEditResult);
  registerMinimalTool(pi, "find", renderFindCall, renderFindResult);
  registerMinimalTool(pi, "grep", renderGrepCall, renderGrepResult);
  registerMinimalTool(pi, "ls", renderLsCall, renderLsResult);
}
