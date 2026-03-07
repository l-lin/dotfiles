/**
 * Tool cache for minimal-mode extension
 *
 * This module maintains a singleton cache of built-in tools by working directory.
 * It prevents recreating tool instances and provides a centralized access point
 * for both the main extension and render functions.
 */

import type { Component } from "@mariozechner/pi-tui";
import {
  createBashTool,
  createEditTool,
  createFindTool,
  createGrepTool,
  createLsTool,
  createReadTool,
  createWriteTool,
} from "@mariozechner/pi-coding-agent";

/**
 * The create*Tool() functions return AgentTool (from pi-agent-core) which
 * doesn't declare renderResult in its type, but the coding-agent layer adds it
 * at runtime. This type extends the return type to include the render methods.
 */
type BuiltInToolWithRender<T> = T & {
  renderResult(result: any, options: { expanded: boolean }, theme: any): Component | undefined;
};

type BuiltInTools = {
  [K in keyof ReturnType<typeof _createBuiltInTools>]: BuiltInToolWithRender<ReturnType<typeof _createBuiltInTools>[K]>;
};

// Cache for built-in tools by cwd
const toolCache = new Map<string, BuiltInTools>();

function _createBuiltInTools(cwd: string) {
  return {
    bash: createBashTool(cwd),
    read: createReadTool(cwd),
    edit: createEditTool(cwd),
    write: createWriteTool(cwd),
    find: createFindTool(cwd),
    grep: createGrepTool(cwd),
    ls: createLsTool(cwd),
  };
}

export function getBuiltInTools(cwd: string): BuiltInTools {
  let tools = toolCache.get(cwd);
  if (!tools) {
    tools = _createBuiltInTools(cwd) as BuiltInTools;
    toolCache.set(cwd, tools);
  }
  return tools;
}
