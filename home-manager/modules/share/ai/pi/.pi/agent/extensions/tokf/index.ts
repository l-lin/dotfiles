import type {
  BashOperations,
  ExtensionAPI,
  ToolRenderResultOptions,
} from "@mariozechner/pi-coding-agent";
import { createBashTool } from "@mariozechner/pi-coding-agent";
import { Clone } from "@sinclair/typebox/value";
import { renderBashCall, renderBashResult } from "../minimal-mode/renders.js";

export const TOKF_BASH_PREFIX = "tokf run --";

export function rewriteCommandForTokf(command: string): string {
  return `${TOKF_BASH_PREFIX} ${command}`;
}

export function createTokfBashTool(
  cwd = process.cwd(),
  options?: { operations?: BashOperations },
) {
  return createBashTool(cwd, {
    operations: options?.operations,
    spawnHook: ({ command, cwd: commandCwd, env }) => ({
      command: rewriteCommandForTokf(command),
      cwd: commandCwd,
      env,
    }),
  });
}

export default function tokfExtension(pi: ExtensionAPI) {
  const bashTool = createTokfBashTool(process.cwd());

  pi.registerTool({
    ...bashTool,
    parameters: Clone(bashTool.parameters),
    renderCall(args: any, theme: any, ctx: any) {
      return renderBashCall(args, theme, ctx);
    },
    renderResult(
      result: any,
      options: ToolRenderResultOptions,
      theme: any,
      context: any,
    ) {
      return renderBashResult(result, options, theme, context);
    },
  } as any);
}
