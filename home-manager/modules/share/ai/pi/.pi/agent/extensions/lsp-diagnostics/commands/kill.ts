/**
 * Manually shut down one or all active LSP server(s)
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { LspClientEntry } from "../types.js";
import { clearWidget, LSP_ICON } from "../ui/widget.js";

export async function handleKill(
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
