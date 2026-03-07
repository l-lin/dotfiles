/**
 * Toggle auto LSP diagnostics on/off for this session
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { LspDiagnosticsConfig } from "../config.js";
import { saveEnabled } from "../config.js";

export async function handleToggle(
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
