/**
 * LSP diagnostics widget — shows active LSP server status with blinking indicator.
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";

export const WIDGET_KEY = "lsp-diagnostics";
export const LSP_ICON = "";
const LSP_BLINK_INTERVAL_MS = 500;

export type LspWidgetState = "starting" | "collecting" | "idle";

// Module-level blink state
let blinkTimer: ReturnType<typeof setInterval> | undefined;
let blinkVisible = true;

export function stopBlink(): void {
  if (blinkTimer !== undefined) {
    clearInterval(blinkTimer);
    blinkTimer = undefined;
  }
  blinkVisible = true;
}

function renderWidget(
  ctx: ExtensionContext,
  lspBin: string,
  icon: string,
  iconVisible: boolean,
): void {
  const theme = ctx.ui.theme;
  const renderedIcon = iconVisible ? icon : " ";
  const line = theme.fg("success", renderedIcon) + theme.bold(` ${lspBin}`);
  ctx.ui.setWidget(WIDGET_KEY, [line]);
}

export function setLspWidget(
  ctx: ExtensionContext,
  lspBin: string,
  state: LspWidgetState,
): void {
  if (!ctx.hasUI) return;

  stopBlink();

  if (state === "starting" || state === "collecting") {
    blinkVisible = true;
    renderWidget(ctx, lspBin, LSP_ICON, blinkVisible);
    blinkTimer = setInterval(() => {
      blinkVisible = !blinkVisible;
      renderWidget(ctx, lspBin, LSP_ICON, blinkVisible);
    }, LSP_BLINK_INTERVAL_MS);
  } else {
    renderWidget(ctx, lspBin, LSP_ICON, true);
  }
}

export function clearWidget(ctx: ExtensionContext): void {
  stopBlink();
  if (!ctx.hasUI) return;
  ctx.ui.setWidget(WIDGET_KEY, undefined);
}
