/**
 * LspDetailsComponent — interactive TUI panel for inspecting active LSP clients.
 */
import {
  matchesKey,
  type Component,
  type TUI,
  truncateToWidth,
  visibleWidth,
} from "@mariozechner/pi-tui";
import type { LspDiagnostic, LspClientEntry } from "../types.js";
import {
  ICON_LSP,
  ICON_SUCCESS,
  ICON_ERROR,
  ICON_WARNING,
  ICON_INFO,
  ICON_HINT,
  ICON_TIMEOUT,
} from "../types.js";

// ── Helpers ───────────────────────────────────────────────────────────────────

function padRight(s: string, n: number): string {
  const delta = n - visibleWidth(s);
  return delta > 0 ? s + " ".repeat(delta) : s;
}

function elapsedSince(date: Date): string {
  const ms = Date.now() - date.getTime();
  const secs = Math.floor(ms / 1000);
  if (secs < 60) return `${secs}s ago`;
  const mins = Math.floor(secs / 60);
  if (mins < 60) return `${mins}m ${secs % 60}s ago`;
  return `${Math.floor(mins / 60)}h ${mins % 60}m ago`;
}

// ── Types ─────────────────────────────────────────────────────────────────────

interface LspClientEntrySnapshot {
  commandKey: string;
  bin: string;
  command: string[];
  rootDir: string;
  settings?: Record<string, unknown>;
  startedAt: Date;
  openedFiles: string[];
  diagnosticsMap: Map<string, LspDiagnostic[]>;
  versionCounter: number;
  pendingWaiters: string[];
  initDurationMs: number;
  lastCheckDurationMs: number;
  lastCheckReceivedResponse: boolean;
  totalNotificationsReceived: number;
  pendingUris: string[];
  receivedUris: string[];
  lastMismatchInfo: string | null;
}

function snapshotClient(
  commandKey: string,
  entry: LspClientEntry,
): LspClientEntrySnapshot {
  const info = entry.client.getDebugInfo();
  return {
    commandKey,
    bin: entry.bin,
    command: entry.command,
    rootDir: entry.rootDir,
    settings: entry.settings,
    startedAt: entry.startedAt,
    ...info,
  };
}

// ── Component ─────────────────────────────────────────────────────────────────

export class LspDetailsComponent implements Component {
  private snapshots: LspClientEntrySnapshot[] = [];
  private lspClients: Map<string, LspClientEntry>;
  private tui: TUI;
  private theme: any;
  private onDone: (result?: unknown) => void;
  private selectedIdx = 0;
  private scrollOffset = 0;

  constructor(
    lspClients: Map<string, LspClientEntry>,
    tui: TUI,
    theme: any,
    onDone: (result?: unknown) => void,
  ) {
    this.lspClients = lspClients;
    this.tui = tui;
    this.theme = theme;
    this.onDone = onDone;
    this.refreshSnapshots();
  }

  private refreshSnapshots(): void {
    this.snapshots = [...this.lspClients.entries()].map(([key, entry]) =>
      snapshotClient(key, entry),
    );
    if (this.selectedIdx >= this.snapshots.length) {
      this.selectedIdx = Math.max(0, this.snapshots.length - 1);
    }
  }

  private renderEmpty(): string[] {
    const d = (s: string) => this.theme.fg("dim", s);
    return [
      "",
      d("  No active LSP servers."),
      "",
      d("  Press Esc or q to close"),
      "",
    ];
  }

  private renderTabBar(): string[] {
    if (this.snapshots.length <= 1) return [];
    const th = this.theme;
    const tabs = this.snapshots
      .map((s, i) =>
        i === this.selectedIdx
          ? th.bold(th.fg("accent", `[${s.bin}]`))
          : th.fg("dim", ` ${s.bin} `),
      )
      .join("  ");
    return [tabs, ""];
  }

  private renderServerInfo(snap: LspClientEntrySnapshot): string[] {
    const th = this.theme;
    const d = (s: string) => th.fg("dim", s);
    const b = (s: string) => th.bold(s);
    const LABEL_W = 12;
    const row = (label: string, value: string) =>
      `${d(padRight(label, LABEL_W))}  ${value}`;

    const isCollecting = snap.pendingWaiters.length > 0;
    const statusText = isCollecting
      ? th.fg(
          "warning",
          `${ICON_LSP} collecting (${snap.pendingWaiters.length} pending)`,
        )
      : th.fg("success", `${ICON_LSP} idle`);

    return [
      b("Server Info"),
      row("Status", statusText),
      row("Binary", b(snap.bin)),
      row("Full path", snap.command[0] ?? d("(none)")),
      row("Arguments", snap.command.slice(1).join(" ") || d("(none)")),
      row("Root dir", snap.rootDir),
      row(
        "Started",
        `${snap.startedAt.toLocaleTimeString()}  ${d(elapsedSince(snap.startedAt))}`,
      ),
    ];
  }

  private renderTimingMetrics(snap: LspClientEntrySnapshot): string[] {
    const th = this.theme;
    const d = (s: string) => th.fg("dim", s);
    const b = (s: string) => th.bold(s);
    const LABEL_W = 12;
    const row = (label: string, value: string) =>
      `${d(padRight(label, LABEL_W))}  ${value}`;

    const activeDiags = [...snap.diagnosticsMap.values()]
      .filter((v) => v.length > 0)
      .flat();
    const errorCount = activeDiags.filter((d) => d.severity === 1).length;
    const warnCount = activeDiags.filter((d) => d.severity === 2).length;
    const totalCount = activeDiags.length;

    const lastCheckLine =
      snap.lastCheckDurationMs > 0
        ? row(
            "Last check",
            `${snap.lastCheckDurationMs}ms  ${
              snap.lastCheckReceivedResponse
                ? th.fg("success", `${ICON_SUCCESS} received`)
                : th.fg("error", `${ICON_TIMEOUT} TIMEOUT`)
            }`,
          )
        : row("Last check", d("(no checks yet)"));

    return [
      "",
      b("Timing Metrics"),
      row("Init time", `${snap.initDurationMs}ms`),
      lastCheckLine,
      row("Notifs recv", String(snap.totalNotificationsReceived)),
      row("Notifs sent", String(snap.versionCounter - 1)),
      row("Files open", String(snap.openedFiles.length)),
      row(
        "Diagnostics",
        `${totalCount} total  ` +
          th.fg("error", `${errorCount} error(s)`) +
          `  ` +
          th.fg("warning", `${warnCount} warning(s)`),
      ),
    ];
  }

  private renderSettings(snap: LspClientEntrySnapshot): string[] {
    if (!snap.settings || Object.keys(snap.settings).length === 0) return [];
    const b = (s: string) => this.theme.bold(s);
    return [
      "",
      b("Settings"),
      ...JSON.stringify(snap.settings, null, 2)
        .split("\n")
        .map((l) => "  " + l),
    ];
  }

  private renderDebugInfo(snap: LspClientEntrySnapshot): string[] {
    if (snap.lastCheckReceivedResponse && !snap.lastMismatchInfo) return [];
    const th = this.theme;
    const d = (s: string) => th.fg("dim", s);
    const b = (s: string) => th.bold(s);
    const lines: string[] = ["", b(th.fg("warning", "Debug Info"))];

    if (snap.lastMismatchInfo) {
      lines.push(th.fg("error", "  URI Mismatch Detected:"));
      for (const line of snap.lastMismatchInfo.split("\n")) {
        lines.push("    " + line);
      }
    }
    if (snap.pendingUris.length > 0) {
      lines.push(d("  Last pending URIs:"));
      for (const uri of snap.pendingUris) lines.push("    " + uri);
    }
    if (snap.receivedUris.length > 0) {
      lines.push(d("  Last received URIs:"));
      for (const uri of snap.receivedUris) lines.push("    " + uri);
    }
    return lines;
  }

  private renderOpenFiles(snap: LspClientEntrySnapshot): string[] {
    const th = this.theme;
    const d = (s: string) => th.fg("dim", s);
    const b = (s: string) => th.bold(s);
    const lines: string[] = ["", b(`Open Files (${snap.openedFiles.length})`)];

    if (snap.openedFiles.length === 0) {
      lines.push(d("  (none)"));
      return lines;
    }

    for (const uri of snap.openedFiles) {
      const filePath = uri.replace(/^file:\/\//, "");
      const diags = snap.diagnosticsMap.get(uri) ?? [];
      const errors = diags.filter((dg) => dg.severity === 1).length;
      const warns = diags.filter((dg) => dg.severity === 2).length;
      const infos = diags.filter((dg) => dg.severity === 3).length;
      const hints = diags.filter((dg) => dg.severity === 4).length;
      const badge =
        diags.length === 0
          ? "  " + th.fg("success", ICON_SUCCESS)
          : "  " +
            (errors > 0 ? th.fg("error", `${ICON_ERROR} ${errors}`) : "") +
            (warns > 0
              ? " " + th.fg("warning", `${ICON_WARNING} ${warns}`)
              : "") +
            (infos > 0 ? " " + th.fg("muted", `${ICON_INFO} ${infos}`) : "") +
            (hints > 0 ? " " + th.fg("muted", `${ICON_HINT} ${hints}`) : "");
      lines.push(`  ${filePath}${badge}`);
    }
    return lines;
  }

  private renderDiagnosticsDetail(snap: LspClientEntrySnapshot): string[] {
    const th = this.theme;
    const d = (s: string) => th.fg("dim", s);
    const b = (s: string) => th.bold(s);

    const activeDiagnostics = new Map(
      [...snap.diagnosticsMap.entries()].filter(
        ([_, diags]) => diags.length > 0,
      ),
    );
    const totalDiags = [...activeDiagnostics.values()].flat().length;

    const lines: string[] = ["", b(`Diagnostics Detail (${totalDiags})`)];

    if (totalDiags === 0) {
      lines.push(
        "  " +
          th.fg(
            "success",
            `${ICON_SUCCESS} No diagnostics — clean bill of health!`,
          ),
      );
      return lines;
    }

    for (const [uri, diags] of activeDiagnostics.entries()) {
      if (diags.length === 0) continue;
      lines.push(`  ${d(uri.replace(/^file:\/\//, ""))}`);
      for (const diag of diags) {
        let sev: string;
        if (diag.severity === 1) sev = th.fg("error", "error  ");
        else if (diag.severity === 2) sev = th.fg("warning", "warning");
        else sev = d("info   ");
        const loc = `${diag.range.start.line + 1}:${diag.range.start.character + 1}`;
        const src = diag.source ? d(` [${diag.source}]`) : "";
        const code = diag.code != null ? d(` (${diag.code})`) : "";
        lines.push(
          `    ${sev}  ${padRight(loc, 8)} ${diag.message}${src}${code}`,
        );
      }
      lines.push("");
    }
    return lines;
  }

  private buildContentLines(): string[] {
    this.refreshSnapshots();
    if (this.snapshots.length === 0) return this.renderEmpty();

    const snap = this.snapshots[this.selectedIdx]!;
    return [
      ...this.renderTabBar(),
      ...this.renderServerInfo(snap),
      ...this.renderTimingMetrics(snap),
      ...this.renderSettings(snap),
      ...this.renderDebugInfo(snap),
      ...this.renderOpenFiles(snap),
      ...this.renderDiagnosticsDetail(snap),
    ];
  }

  private box(contentLines: string[], width: number, title: string): string[] {
    const th = this.theme;
    const innerW = Math.max(1, width - 2);
    const result: string[] = [];

    const titleStr = truncateToWidth(` ${title} `, innerW);
    const titleW = visibleWidth(titleStr);
    const topLine = "─".repeat(Math.floor((innerW - titleW) / 2));
    const topLine2 = "─".repeat(Math.max(0, innerW - titleW - topLine.length));
    result.push(
      th.fg("border", `╭${topLine}`) +
        th.fg("accent", titleStr) +
        th.fg("border", `${topLine2}╮`),
    );

    for (const line of contentLines) {
      result.push(
        th.fg("border", "│") +
          truncateToWidth(" " + line, innerW, "...", true) +
          th.fg("border", "│"),
      );
    }

    result.push(th.fg("border", `╰${"─".repeat(innerW)}╯`));
    return result;
  }

  handleInput(data: string): void {
    if (
      matchesKey(data, "escape") ||
      matchesKey(data, "ctrl+c") ||
      data.toLowerCase() === "q"
    ) {
      this.onDone();
      return;
    }

    if (matchesKey(data, "left") || data.toLowerCase() === "h") {
      if (this.selectedIdx > 0) {
        this.selectedIdx--;
        this.scrollOffset = 0;
        this.tui.requestRender();
      }
    }
    if (matchesKey(data, "right") || data.toLowerCase() === "l") {
      if (this.selectedIdx < this.snapshots.length - 1) {
        this.selectedIdx++;
        this.scrollOffset = 0;
        this.tui.requestRender();
      }
    }
    if (matchesKey(data, "up") || data === "k") {
      if (this.scrollOffset > 0) {
        this.scrollOffset--;
        this.tui.requestRender();
      }
    }
    if (matchesKey(data, "down") || data === "j") {
      this.scrollOffset++;
      this.tui.requestRender();
    }

    const viewportLines = Math.max(
      1,
      Math.floor((process.stdout.rows ?? 40) * 0.85) - 2,
    );
    const pageSize = Math.max(1, Math.floor(viewportLines / 2));

    if (matchesKey(data, "ctrl+u") || data === "\x1b[5~") {
      this.scrollOffset = Math.max(0, this.scrollOffset - pageSize);
      this.tui.requestRender();
    }
    if (matchesKey(data, "ctrl+d") || data === "\x1b[6~") {
      this.scrollOffset += pageSize;
      this.tui.requestRender();
    }
    if (matchesKey(data, "home") || data === "g") {
      this.scrollOffset = 0;
      this.tui.requestRender();
    }
    if (matchesKey(data, "end") || data === "G") {
      const contentLines = this.buildContentLines();
      this.scrollOffset = Math.max(0, contentLines.length - viewportLines);
      this.tui.requestRender();
    }
  }

  invalidate(): void {}

  render(width: number): string[] {
    const contentLines = this.buildContentLines();
    const terminalHeight = process.stdout.rows ?? 40;
    const viewportLines = Math.max(1, Math.floor(terminalHeight * 0.85) - 2);

    const maxScroll = Math.max(0, contentLines.length - viewportLines);
    this.scrollOffset = Math.min(this.scrollOffset, maxScroll);

    const visibleContent = contentLines.slice(
      this.scrollOffset,
      this.scrollOffset + viewportLines,
    );

    const navHint = this.snapshots.length > 1 ? " ←→/hl:server" : "";
    const scrollHint =
      contentLines.length > viewportLines
        ? ` ${this.scrollOffset + 1}-${Math.min(this.scrollOffset + viewportLines, contentLines.length)}/${contentLines.length}`
        : "";
    const title = `LSP Server Details${navHint} · ↑↓/jk:scroll · ^u/^d/PgUp/PgDn:page · g/G/Home/End:jump · q:close${scrollHint}`;

    return this.box(visibleContent, width, title);
  }

  dispose(): void {}
}
