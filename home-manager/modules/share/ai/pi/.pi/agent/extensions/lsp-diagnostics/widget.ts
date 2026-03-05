/**
 * LSP diagnostics widget — shows all active LSP server statuses with blinking indicator.
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";

export const WIDGET_KEY = "lsp-diagnostics";
export const LSP_ICON = "";
const LSP_BLINK_INTERVAL_MS = 500;

export type LspWidgetState = "starting" | "collecting" | "idle";

// Per-server state: bin → current state
const serverStates = new Map<string, LspWidgetState>();

// Module-level blink state (shared across all active servers)
let blinkTimer: ReturnType<typeof setInterval> | undefined;
let blinkVisible = true;

function stopBlink(): void {
  if (blinkTimer !== undefined) {
    clearInterval(blinkTimer);
    blinkTimer = undefined;
  }
  blinkVisible = true;
}

function renderWidget(ctx: ExtensionContext): void {
  if (serverStates.size === 0) {
    ctx.ui.setWidget(WIDGET_KEY, undefined);
    return;
  }

  const theme = ctx.ui.theme;
  const lines = [...serverStates.entries()].map(([bin, state]) => {
    const isActive = state === "starting" || state === "collecting";
    const icon = isActive && !blinkVisible ? " " : LSP_ICON;
    return theme.fg("success", icon) + theme.bold(` ${bin}`);
  });

  ctx.ui.setWidget(WIDGET_KEY, lines);
}

function ensureBlinkRunning(ctx: ExtensionContext): void {
  if (blinkTimer !== undefined) return;
  blinkVisible = true;
  blinkTimer = setInterval(() => {
    blinkVisible = !blinkVisible;
    renderWidget(ctx);
  }, LSP_BLINK_INTERVAL_MS);
}

function refreshBlink(ctx: ExtensionContext): void {
  const hasActive = [...serverStates.values()].some(
    (s) => s === "starting" || s === "collecting",
  );
  if (hasActive) {
    ensureBlinkRunning(ctx);
  } else {
    stopBlink();
  }
  renderWidget(ctx);
}

/**
 * Removes any server not in `activeBins` from the widget state.
 * Call this at the start of each diagnostic run to prune stale entries
 * from previous files that no longer match the current file's servers.
 */
export function syncLspServers(
  ctx: ExtensionContext,
  activeBins: string[],
): void {
  if (!ctx.hasUI) return;
  const activeSet = new Set(activeBins);
  for (const bin of serverStates.keys()) {
    if (!activeSet.has(bin)) serverStates.delete(bin);
  }
  refreshBlink(ctx);
}

export function setLspWidget(
  ctx: ExtensionContext,
  lspBin: string,
  state: LspWidgetState,
): void {
  if (!ctx.hasUI) return;
  serverStates.set(lspBin, state);
  refreshBlink(ctx);
}

export function clearWidget(ctx: ExtensionContext): void {
  serverStates.clear();
  stopBlink();
  if (!ctx.hasUI) return;
  ctx.ui.setWidget(WIDGET_KEY, undefined);
}
