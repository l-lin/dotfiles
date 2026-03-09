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
import type { LspDiagnostic } from "../types.js";
import {
  SEVERITY_ERROR,
  SEVERITY_WARNING,
  SEVERITY_INFO,
  SEVERITY_HINT,
  ICON_LSP,
  ICON_SUCCESS,
  ICON_ERROR,
  ICON_WARNING,
  ICON_INFO,
  ICON_HINT,
  ICON_TIMEOUT,
} from "../types.js";

export const WIDGET_KEY = "lsp-diagnostics";
export { ICON_LSP as LSP_ICON, ICON_SUCCESS as SUCCESS_ICON };
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

function buildSummary(counts: DiagnosticCounts, theme: any): string {
  const parts: string[] = [];
  if (counts.errors > 0) parts.push(theme.fg("error", `${ICON_ERROR} ${counts.errors}`));
  if (counts.warnings > 0) parts.push(theme.fg("warning", `${ICON_WARNING} ${counts.warnings}`));
  if (counts.infos > 0) parts.push(theme.fg("muted", `${ICON_INFO} ${counts.infos}`));
  if (counts.hints > 0) parts.push(theme.fg("muted", `${ICON_HINT} ${counts.hints}`));
  return parts.length > 0 ? ` ${parts.join(" ")}` : "";
}

class WidgetManager {
  private serverStates = new Map<string, ServerWidgetEntry>();
  private blinkTimer: ReturnType<typeof setInterval> | undefined;
  private blinkVisible = true;
  private requestRenderFn: (() => void) | undefined;
  private registered = false;

  /**
   * Remove any server not in `activeBins` from widget state.
   * Call at the start of each diagnostic run to prune stale entries.
   */
  sync(ctx: ExtensionContext, activeBins: string[]): void {
    if (!ctx.hasUI) return;
    const activeSet = new Set(activeBins);
    for (const bin of this.serverStates.keys()) {
      if (!activeSet.has(bin)) this.serverStates.delete(bin);
    }
    this.refresh(ctx);
  }

  set(
    ctx: ExtensionContext,
    bin: string,
    state: LspWidgetState,
    diagnostics?: Map<string, LspDiagnostic[]>,
    timing?: TimingInfo,
  ): void {
    if (!ctx.hasUI) return;
    const existing = this.serverStates.get(bin);

    const counts =
      diagnostics !== undefined
        ? countDiagnostics(diagnostics)
        : (existing?.diagnostics ?? null);

    this.serverStates.set(bin, {
      state,
      diagnostics: counts,
      timing: timing ?? existing?.timing ?? null,
    });
    this.refresh(ctx);
  }

  clear(ctx: ExtensionContext): void {
    this.serverStates.clear();
    this.stopBlink();
    this.requestRenderFn = undefined;
    this.registered = false;
    if (!ctx.hasUI) return;
    ctx.ui.setWidget(WIDGET_KEY, undefined);
  }

  private ensureRegistered(ctx: ExtensionContext): void {
    if (this.registered) return;
    this.registered = true;

    ctx.ui.setWidget(WIDGET_KEY, (tui: TUI, theme: any) => {
      // Wire up the render callback now that the factory has been invoked.
      // Any requestRenderFn?.() calls that fired before this point were no-ops;
      // trigger one immediate render to catch up.
      this.requestRenderFn = () => tui.requestRender();
      tui.requestRender();
      return {
        render: (width: number): string[] => {
          if (this.serverStates.size === 0) return [];
          return [...this.serverStates.entries()].map(([bin, entry]) => {
            const isActive =
              entry.state === "starting" || entry.state === "collecting";
            const icon = isActive && !this.blinkVisible ? "  " : ` ${ICON_LSP}`;

            let statusPart = "";
            if (isActive || entry.diagnostics === null) {
              if (entry.timing && entry.state === "collecting") {
                statusPart = theme.fg(
                  "dim",
                  ` (init: ${entry.timing.initDurationMs}ms)`,
                );
              }
            } else {
              const summary = buildSummary(entry.diagnostics, theme);
              const timingPart = entry.timing
                ? theme.fg("dim", ` ${entry.timing.lastCheckDurationMs}ms`)
                : "";
              const timeoutWarning =
                entry.timing && !entry.timing.receivedResponse
                  ? theme.fg("error", ` ${ICON_TIMEOUT}`)
                  : "";
              if (summary === "" && timeoutWarning === "") {
                statusPart =
                  timingPart + theme.fg("success", ` ${ICON_SUCCESS}`);
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

  private startBlink(): void {
    if (this.blinkTimer !== undefined) return;
    this.blinkVisible = true;
    this.blinkTimer = setInterval(() => {
      this.blinkVisible = !this.blinkVisible;
      this.requestRenderFn?.();
      if ([...this.serverStates.values()].every((e) => e.state === "idle")) {
        this.stopBlink();
      }
    }, LSP_BLINK_INTERVAL_MS);
  }

  private stopBlink(): void {
    if (this.blinkTimer !== undefined) {
      clearInterval(this.blinkTimer);
      this.blinkTimer = undefined;
    }
    this.blinkVisible = true;
  }

  private refresh(ctx: ExtensionContext): void {
    if (this.serverStates.size === 0) {
      this.stopBlink();
      if (this.registered) {
        this.registered = false;
        ctx.ui.setWidget(WIDGET_KEY, undefined);
      }
      return;
    }

    this.ensureRegistered(ctx);

    const hasActive = [...this.serverStates.values()].some(
      (e) => e.state === "starting" || e.state === "collecting",
    );
    if (hasActive) {
      this.startBlink();
    } else {
      this.stopBlink();
    }
    this.requestRenderFn?.();
  }
}

export const widgetManager = new WidgetManager();

export function syncLspServers(
  ctx: ExtensionContext,
  activeBins: string[],
): void {
  widgetManager.sync(ctx, activeBins);
}

export function setLspWidget(
  ctx: ExtensionContext,
  lspBin: string,
  state: LspWidgetState,
  diagnostics?: Map<string, LspDiagnostic[]>,
  timing?: {
    initDurationMs: number;
    lastCheckDurationMs: number;
    receivedResponse: boolean;
  },
): void {
  widgetManager.set(ctx, lspBin, state, diagnostics, timing);
}

export function clearWidget(ctx: ExtensionContext): void {
  widgetManager.clear(ctx);
}
