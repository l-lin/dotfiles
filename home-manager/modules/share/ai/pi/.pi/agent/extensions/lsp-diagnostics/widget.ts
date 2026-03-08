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
import type { LspDiagnostic } from "./types.js";
import { SEVERITY_ERROR, SEVERITY_WARNING, SEVERITY_INFO, SEVERITY_HINT } from "./types.js";

export const WIDGET_KEY = "lsp-diagnostics";
export const LSP_ICON = "";
export const SUCCESS_ICON = "✓";
const LSP_BLINK_INTERVAL_MS = 500;

export type LspWidgetState = "starting" | "collecting" | "idle";

interface DiagnosticCounts {
  errors: number;
  warnings: number;
  infos: number;
  hints: number;
}

interface TimingInfo {
  initDurationMs: number;
  lastCheckDurationMs: number;
  receivedResponse: boolean;
}

interface ServerWidgetEntry {
  state: LspWidgetState;
  diagnostics: DiagnosticCounts | null; // null = no diagnostics run yet
  timing: TimingInfo | null;
}

// Per-server state: bin → entry
const serverStates = new Map<string, ServerWidgetEntry>();

/**
 * Count diagnostics by severity across all files in the map.
 */
function countDiagnostics(
  diagnostics: Map<string, LspDiagnostic[]>,
): DiagnosticCounts {
  let errors = 0;
  let warnings = 0;
  let infos = 0;
  let hints = 0;

  for (const diags of diagnostics.values()) {
    for (const d of diags) {
      if (d.severity === SEVERITY_ERROR) errors++;
      else if (d.severity === SEVERITY_WARNING) warnings++;
      else if (d.severity === SEVERITY_INFO) infos++;
      else if (d.severity === SEVERITY_HINT) hints++;
    }
  }

  return { errors, warnings, infos, hints };
}

/**
 * Build a colored summary string from diagnostic counts.
 * Returns empty string if no issues, or formatted string like "✖ 2 ⚠ 1  3  4"
 */
function buildSummary(counts: DiagnosticCounts, theme: any): string {
  const parts: string[] = [];
  if (counts.errors > 0) {
    parts.push(theme.fg("error", `✖ ${counts.errors}`));
  }
  if (counts.warnings > 0) {
    parts.push(theme.fg("warning", `⚠ ${counts.warnings}`));
  }
  if (counts.infos > 0) {
    parts.push(theme.fg("muted", ` ${counts.infos}`));
  }
  if (counts.hints > 0) {
    parts.push(theme.fg("muted", ` ${counts.hints}`));
  }
  return parts.length > 0 ? ` ${parts.join(" ")}` : "";
}

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
    if ([...serverStates.values()].every((e) => e.state === "idle"))
      stopBlink();
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
        return [...serverStates.entries()].map(([bin, entry]) => {
          const isActive =
            entry.state === "starting" || entry.state === "collecting";
          const icon = isActive && !blinkVisible ? "  " : ` ${LSP_ICON}`;

          let statusPart = "";
          if (isActive || entry.diagnostics === null) {
            // Show timing for active state
            if (entry.timing && entry.state === "collecting") {
              statusPart = theme.fg(
                "dim",
                ` (init: ${entry.timing.initDurationMs}ms)`,
              );
            }
          } else {
            const summary = buildSummary(entry.diagnostics, theme);
            // Show timing info: checkTime + init time
            const timingPart = entry.timing
              ? theme.fg("dim", ` ${entry.timing.lastCheckDurationMs}ms`)
              : "";
            const timeoutWarning =
              entry.timing && !entry.timing.receivedResponse
                ? theme.fg("error", " 󱫏")
                : "";
            if (summary === "" && timeoutWarning === "") {
              statusPart =
                timingPart +
                theme.fg("success", ` ${SUCCESS_ICON}`);
            } else {
              statusPart = timeoutWarning + timingPart + summary;
            }
          }

          const line =
            theme.fg("success", icon) + theme.bold(` ${bin}`) + statusPart;
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
    (e) => e.state === "starting" || e.state === "collecting",
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
  diagnostics?: Map<string, LspDiagnostic[]>,
  timing?: TimingInfo,
): void {
  if (!ctx.hasUI) return;
  const existing = serverStates.get(lspBin);

  let counts: DiagnosticCounts | null;
  if (diagnostics !== undefined) {
    counts = countDiagnostics(diagnostics);
  } else {
    counts = existing?.diagnostics ?? null;
  }

  serverStates.set(lspBin, {
    state,
    diagnostics: counts,
    timing: timing ?? existing?.timing ?? null,
  });
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
