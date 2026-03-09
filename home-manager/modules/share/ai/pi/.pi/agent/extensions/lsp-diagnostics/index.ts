/**
 * lsp-diagnostics pi extension
 *
 * Automatically runs LSP diagnostics after every write/edit tool call and
 * appends results to the tool result so the LLM can self-correct immediately.
 * Updates the LSP widget with a summary of diagnostics.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  isEditToolResult,
  isWriteToolResult,
} from "@mariozechner/pi-coding-agent";
import type { SavedConfig, LspClientEntry } from "./types.js";
import { CONFIG_ENTRY_TYPE } from "./types.js";
import { loadConfig } from "./config.js";
import { LSP_SERVERS_CONFIG } from "./lsp-servers.js";
import { resolveLspCommands } from "./resolver.js";
import { collectDiagnostics } from "./collector.js";
import { buildDiagnosticBlock } from "./ui/format.js";
import { clearWidget } from "./ui/widget.js";
import {
  handleCheck,
  handleToggle,
  handleKill,
  handleDetails,
} from "./commands/index.js";

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  const fileConfig = LSP_SERVERS_CONFIG;

  let savedConfig: SavedConfig | null = null;
  // Persistent LSP clients keyed by "command::rootDir" — created lazily, shut down on session end
  const lspClients = new Map<string, LspClientEntry>();

  pi.registerCommand("cmd:lsp-check", {
    description: "Check LSP diagnostics for a file or directory",
    handler: async (args, ctx) => {
      const filePath = args.split(" ")[0] || undefined;
      await handleCheck(lspClients, ctx, savedConfig, pi, filePath);
    },
  });

  pi.registerCommand("cmd:lsp-toggle", {
    description: "Toggle LSP extension on/off",
    handler: async (_args, ctx) => {
      await handleToggle(config, ctx);
    },
  });

  pi.registerCommand("cmd:lsp-kill", {
    description: "Kill active LSP server(s)",
    handler: async (_args, ctx) => {
      await handleKill(lspClients, ctx);
    },
  });

  pi.registerCommand("cmd:lsp-details", {
    description: "Show LSP server details",
    handler: async (_args, ctx) => {
      await handleDetails(lspClients, ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    savedConfig = null;
    const saved = [...ctx.sessionManager.getEntries()].findLast(
      (
        e,
      ): e is import("@mariozechner/pi-coding-agent").SessionEntry & {
        type: "custom";
        data?: unknown;
      } => e.type === "custom" && (e as any).customType === CONFIG_ENTRY_TYPE,
    );
    if (saved && saved.data) savedConfig = saved.data as SavedConfig;

    if (savedConfig) {
      const parts: string[] = [];
      if (savedConfig.lspCommand)
        parts.push(`global: ${savedConfig.lspCommand.join(" ")}`);
      for (const [lang, cmd] of Object.entries(savedConfig.perLanguage ?? {})) {
        parts.push(`${lang}: ${cmd.join(" ")}`);
      }
      if (parts.length > 0) {
        ctx.ui.notify(`lsp-diagnostics config — ${parts.join(" | ")}`, "info");
      }
    }
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    const shutdowns = [...lspClients.values()].map(({ client }) =>
      client.shutdown(),
    );
    lspClients.clear();
    await Promise.allSettled(shutdowns);
    clearWidget(ctx);
  });

  pi.on("tool_result", async (event, ctx) => {
    if (!config.enabled) return;
    if (!isWriteToolResult(event) && !isEditToolResult(event)) return;

    const filePath = event.input.path as string | undefined;
    if (!filePath) return;

    const resolvedList = resolveLspCommands(
      [filePath],
      undefined,
      savedConfig,
      fileConfig,
    );
    if (resolvedList.length === 0) return;

    const { merged, servers } = await collectDiagnostics(
      [filePath],
      resolvedList,
      lspClients,
      ctx,
    );
    if (servers.length === 0) return;

    const lspBinLabel = servers.map((s) => s.bin).join("+");
    const block = buildDiagnosticBlock(merged, filePath, lspBinLabel, ctx.cwd);
    if (block) {
      return {
        content: [
          ...event.content,
          { type: "text" as const, text: `\n${block}` },
        ],
      };
    }
  });
}
