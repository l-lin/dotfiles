/**
 * LSP diagnostics widget — shows all active LSP server statuses with blinking indicator.
 *
 * Uses the factory form of setWidget so the component is registered once and
 * renders dynamically — avoids re-registering the widget on every blink tick
 * which would cause pi to rebuild the widget container and potentially disrupt
 * widget ordering when multiple widgets are active simultaneously.
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { TUI } from "@mariozechner/pi-tui";
import { truncateToWidth } from "@mariozechner/pi-tui";

export const WIDGET_KEY = "lsp-diagnostics";
export const LSP_ICON = "";
const LSP_BLINK_INTERVAL_MS = 500;

export type LspWidgetState = "starting" | "collecting" | "idle";

// Per-server state: bin → current state
const serverStates = new Map<string, LspWidgetState>();

// Module-level blink & render state
let blinkTimer: ReturnType<typeof setInterval> | undefined;
let blinkVisible = true;
let requestRenderFn: (() => void) | undefined;
let widgetRegistered = false;

function stopBlink(): void {
  if (blinkTimer !== undefined) {
    clearInterval(blinkTimer);
    blinkTimer = undefined;
  }
  blinkVisible = true;
}

function ensureBlinkRunning(): void {
  if (blinkTimer !== undefined) return;
  blinkVisible = true;
  blinkTimer = setInterval(() => {
    blinkVisible = !blinkVisible;
    requestRenderFn?.();
    if ([...serverStates.values()].every((s) => s === "idle")) stopBlink();
  }, LSP_BLINK_INTERVAL_MS);
}

/**
 * Register the widget factory once per active session. The factory captures
 * the tui reference for requestRender, and the component reads live state on
 * every render() call — no re-registration needed on blink ticks.
 */
function ensureWidgetRegistered(ctx: ExtensionContext): void {
  if (widgetRegistered) return;
  widgetRegistered = true;

  ctx.ui.setWidget(WIDGET_KEY, (tui: TUI, theme: any) => {
    // Wire up the render callback now that the factory has been invoked.
    // Any requestRenderFn?.() calls that fired before this point were no-ops;
    // trigger one immediate render to catch up.
    requestRenderFn = () => tui.requestRender();
    tui.requestRender();
    return {
      render(width: number): string[] {
        if (serverStates.size === 0) return [];
        return [...serverStates.entries()].map(([bin, state]) => {
          const isActive = state === "starting" || state === "collecting";
          const icon = isActive && !blinkVisible ? " " : LSP_ICON;
          const line = theme.fg("success", icon) + theme.bold(` ${bin}`);
          return truncateToWidth(line, width);
        });
      },
      invalidate() {},
    };
  });
}

function refreshBlink(ctx: ExtensionContext): void {
  if (serverStates.size === 0) {
    stopBlink();
    if (widgetRegistered) {
      widgetRegistered = false;
      ctx.ui.setWidget(WIDGET_KEY, undefined);
    }
    return;
  }

  ensureWidgetRegistered(ctx);

  const hasActive = [...serverStates.values()].some(
    (s) => s === "starting" || s === "collecting",
  );
  if (hasActive) {
    ensureBlinkRunning();
  } else {
    stopBlink();
  }
  requestRenderFn?.();
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
  requestRenderFn = undefined;
  widgetRegistered = false;
  if (!ctx.hasUI) return;
  ctx.ui.setWidget(WIDGET_KEY, undefined);
}
