/**
 * Show detailed debug info for all active LSP server(s) in an interactive TUI
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { TUI } from "@mariozechner/pi-tui";
import type { LspClientEntry } from "../lsp-details.js";
import { LspDetailsComponent } from "../lsp-details.js";

export async function handleDetails(
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
    {
      overlay: true,
      overlayOptions: {
        width: "90%",
        minWidth: 80,
        maxHeight: "85%",
        anchor: "center",
        margin: 0,
      },
    },
  );
}
