/**
 * Toggle auto LSP diagnostics on/off for this session
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { LspDiagnosticsSettings } from "../settings.js";
import { saveEnabled } from "../settings.js";

export async function handleToggle(
  settings: LspDiagnosticsSettings,
  ctx: ExtensionContext,
): Promise<void> {
  settings.enabled = !settings.enabled;
  saveEnabled(settings.enabled);
  ctx.ui.notify(
    `lsp-diagnostics ${settings.enabled ? "enabled" : "disabled"}`,
    "info",
  );
}
