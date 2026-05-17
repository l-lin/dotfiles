/**
 * lsp-diagnostics pi extension
 *
 * Exposes LSP-backed tools for on-demand diagnostics, navigation, and semantic
 * rename operations. Keeps LSP clients warm across tool calls and shows their
 * status in the widget while requests are in flight.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { SavedConfig, LspClientEntry } from "./types.js";
import { CONFIG_ENTRY_TYPE } from "./types.js";
import { clearWidget } from "./ui/widget.js";
import { handleCheck, handleClose, handleDetails } from "./commands/index.js";
import { executeLspTool, LspToolParams } from "./tool.js";
import {
  loadEnabledSettings,
  registerEnabledToggleCommand,
  updateActiveTools,
} from "../tool-settings/index.js";

const SETTINGS_KEY = "lspDiagnostics";
const DEFAULT_SETTINGS = { enabled: true };

export default function (pi: ExtensionAPI) {
  const settings = loadEnabledSettings(SETTINGS_KEY, DEFAULT_SETTINGS);
  let savedConfig: SavedConfig | null = null;
  // Persistent LSP clients keyed by "command::rootDir" — created lazily, shut down on session end
  const lspClients = new Map<string, LspClientEntry>();

  pi.registerTool({
    name: "lsp",
    label: "LSP",
    description:
      "Use LSP for on-demand static analysis and semantic code navigation. Run diagnostics after finishing a meaningful batch of edits, use workspace_symbols/document_symbols/definition/references for discovery before falling back to text search, and use rename for symbol-safe refactors.",
    parameters: LspToolParams,
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      return executeLspTool(params, signal, ctx, lspClients, savedConfig);
    },
  });

  pi.registerCommand("cmd:lsp-check", {
    description: "Check LSP diagnostics for a file or directory",
    handler: async (args, ctx) => {
      const filePath = args.split(" ")[0] || undefined;
      await handleCheck(lspClients, ctx, savedConfig, pi, filePath);
    },
  });

  registerEnabledToggleCommand(pi, {
    toolName: "lsp",
    extensionKey: SETTINGS_KEY,
    description: "Toggle LSP extension on/off",
    settings,
  });

  pi.registerCommand("cmd:lsp-close", {
    description: "Close active LSP server(s)",
    handler: async (_args, ctx) => {
      await handleClose(lspClients, ctx);
    },
  });

  pi.registerCommand("cmd:lsp-details", {
    description: "Show LSP server details",
    handler: async (_args, ctx) => {
      await handleDetails(lspClients, ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    updateActiveTools(pi, { toolName: "lsp", enabled: settings.enabled });

    savedConfig = null;
    const saved = [...ctx.sessionManager.getEntries()].findLast(
      (e) => e.type === "custom" && (e as any).customType === CONFIG_ENTRY_TYPE,
    );
    if (saved && (saved as any).data)
      savedConfig = (saved as any).data as SavedConfig;

    if (savedConfig) {
      const parts: string[] = [];
      if (savedConfig.lspCommand)
        parts.push(`global: ${savedConfig.lspCommand.join(" ")}`);
      for (const [lang, cmd] of Object.entries(savedConfig.perLanguage ?? {})) {
        parts.push(`${lang}: ${cmd.join(" ")}`);
      }
      if (parts.length > 0) {
        ctx.ui.notify(
          `lsp-diagnostics extension — ${parts.join(" | ")}`,
          "info",
        );
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
}
