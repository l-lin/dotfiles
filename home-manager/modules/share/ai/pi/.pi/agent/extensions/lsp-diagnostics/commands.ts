/**
 * LSP command handlers
 * Consolidates all LSP commands into a single cmd:lsp with selection menu
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { TUI } from "@mariozechner/pi-tui";
import type { LspClientEntry } from "./lsp-details.js";
import { LspDetailsComponent } from "./lsp-details.js";
import { clearWidget, LSP_ICON } from "./widget.js";
import type { LspDiagnosticsConfig } from "./config.js";
import { saveEnabled } from "./config.js";

const TOGGLE_LABEL = "Toggle LSP extension on/off";
const KILL_LABEL = "Kill active LSP server(s)";
const DETAILS_LABEL = "Show LSP details";

/**
 * Main LSP command handler - shows a selection menu for all LSP actions
 */
export async function handleLspCommand(
  config: LspDiagnosticsConfig,
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
): Promise<void> {
  const action = await ctx.ui.select("Select an LSP action:", [
    TOGGLE_LABEL,
    KILL_LABEL,
    DETAILS_LABEL,
  ]);

  if (!action) return;

  switch (action) {
    case TOGGLE_LABEL:
      await handleToggle(config, ctx);
      break;
    case KILL_LABEL:
      await handleKill(lspClients, ctx);
      break;
    case DETAILS_LABEL:
      await handleDetails(lspClients, ctx);
      break;
  }
}

/**
 * Toggle auto LSP diagnostics on/off for this session
 */
async function handleToggle(
  config: LspDiagnosticsConfig,
  ctx: ExtensionContext,
): Promise<void> {
  config.enabled = !config.enabled;
  saveEnabled(config.enabled);
  ctx.ui.notify(
    `lsp-diagnostics ${config.enabled ? "enabled" : "disabled"}`,
    "info",
  );
}

/**
 * Manually shut down one or all active LSP server(s)
 */
async function handleKill(
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
): Promise<void> {
  if (lspClients.size === 0) {
    ctx.ui.notify("No active LSP servers.", "info");
    return;
  }

  const ALL_LABEL = `${LSP_ICON} ALL`;
  // Map display label → original commandKey so icon-prefix stripping can't silently mismatch
  const labelToKey = new Map<string, string>();
  for (const k of lspClients.keys()) {
    labelToKey.set(`${LSP_ICON} ${k}`, k);
  }
  const options = [ALL_LABEL, ...labelToKey.keys()];
  const chosen = await ctx.ui.select("Select an LSP server to kill:", options);
  if (!chosen) return;

  if (chosen === ALL_LABEL) {
    const count = lspClients.size;
    const shutdowns = [...lspClients.values()].map(({ client }) =>
      client.shutdown(),
    );
    lspClients.clear();
    await Promise.allSettled(shutdowns);
    clearWidget(ctx);
    ctx.ui.notify(`Killed all ${count} LSP server(s).`, "info");
  } else {
    const key = labelToKey.get(chosen)!;
    const entry = lspClients.get(key);
    if (!entry) {
      ctx.ui.notify(`LSP server "${key}" not found.`, "error");
      return;
    }
    await entry.client.shutdown();
    lspClients.delete(key);
    if (lspClients.size === 0) {
      clearWidget(ctx);
    }
    ctx.ui.notify(`Killed LSP server "${key}".`, "info");
  }
}

/**
 * Show detailed debug info for all active LSP server(s) in an interactive TUI
 */
async function handleDetails(
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
): Promise<void> {
  if (!ctx.hasUI) return;

  await ctx.ui.custom(
    (
      tui: TUI,
      theme: unknown,
      _kb: unknown,
      done: (result: unknown) => void,
    ) => {
      return new LspDetailsComponent(lspClients, tui, theme, done);
    },
  );
}
