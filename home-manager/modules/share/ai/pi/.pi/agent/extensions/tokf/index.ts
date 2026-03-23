import type {
  BashOperations,
  ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import { createBashTool } from "@mariozechner/pi-coding-agent";
import { renderBashCall, renderBashResult } from "../minimal-mode/renders.js";

const TOKF_BASH_PREFIX = "tokf run --";

function createTokfBashTool(
  cwd = process.cwd(),
  options?: { operations?: BashOperations },
) {
  return createBashTool(cwd, {
    operations: options?.operations,
    spawnHook: ({ command, cwd: commandCwd, env }) => ({
      command: `${TOKF_BASH_PREFIX} ${command}`,
      cwd: commandCwd,
      env,
    }),
  });
}

export default function tokfExtension(pi: ExtensionAPI) {
  const bashTool = createTokfBashTool(process.cwd());

  pi.registerTool({
    ...bashTool,
    renderCall(args, theme) {
      return renderBashCall(args, theme);
    },
    renderResult(result, { expanded }, theme, context) {
      return renderBashResult(result, { expanded }, theme, context);
    },
  });
}
