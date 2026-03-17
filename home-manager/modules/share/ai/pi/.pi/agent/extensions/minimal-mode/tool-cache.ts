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
 * at runtime. This type covers the subset we need.
 */
type BuiltInTool = {
  description: string;
  parameters: any;
  execute(
    toolCallId: string,
    params: any,
    signal: AbortSignal,
    onUpdate: any,
  ): Promise<any>;
  renderResult(
    result: any,
    options: { expanded: boolean },
    theme: any,
  ): Component | undefined;
};

export type BuiltInTools = {
  bash: BuiltInTool;
  read: BuiltInTool;
  edit: BuiltInTool;
  write: BuiltInTool;
  find: BuiltInTool;
  grep: BuiltInTool;
  ls: BuiltInTool;
};

const toolCache = new Map<string, BuiltInTools>();

export function getBuiltInTools(cwd: string): BuiltInTools {
  const cached = toolCache.get(cwd);
  if (cached) return cached;

  const tools = {
    bash: createBashTool(cwd),
    read: createReadTool(cwd),
    edit: createEditTool(cwd),
    write: createWriteTool(cwd),
    find: createFindTool(cwd),
    grep: createGrepTool(cwd),
    ls: createLsTool(cwd),
  } as unknown as BuiltInTools;

  toolCache.set(cwd, tools);
  return tools;
}
