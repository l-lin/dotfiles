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
import type { LspDiagnostic } from "./types.js";
import type { PersistentLspClient } from "./lsp-client.js";

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

export interface LspClientEntry {
  client: PersistentLspClient;
  bin: string;
  /** Full command array as passed to spawn */
  command: string[];
  /** Resolved project root directory */
  rootDir: string;
  /** Settings forwarded via workspace/didChangeConfiguration */
  settings?: Record<string, unknown>;
  /** When this client was first created */
  startedAt: Date;
}

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
  // Timing metrics
  initDurationMs: number;
  lastCheckDurationMs: number;
  lastCheckReceivedResponse: boolean;
  totalNotificationsReceived: number;
  // Debug info
  pendingUris: string[];
  receivedUris: string[];
  lastMismatchInfo: string | null;
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
    this.snapshots = [...this.lspClients.entries()].map(
      ([commandKey, entry]) => {
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
      },
    );
    // Keep selectedIdx in bounds
    if (this.selectedIdx >= this.snapshots.length) {
      this.selectedIdx = Math.max(0, this.snapshots.length - 1);
    }
  }

  private buildContentLines(): string[] {
    this.refreshSnapshots();
    const th = this.theme;
    const d = (s: string) => th.fg("dim", s);
    const b = (s: string) => th.bold(s);

    if (this.snapshots.length === 0) {
      return [
        "",
        d("  No active LSP servers."),
        "",
        d("  Press Esc or q to close"),
        "",
      ];
    }

    const lines: string[] = [];

    // Tab bar for server selection
    if (this.snapshots.length > 1) {
      const tabs = this.snapshots
        .map((s, i) =>
          i === this.selectedIdx
            ? b(th.fg("accent", `[${s.bin}]`))
            : d(` ${s.bin} `),
        )
        .join("  ");
      lines.push(tabs);
      lines.push("");
    }

    const snap = this.snapshots[this.selectedIdx];
    if (!snap) return lines;

    // Filter diagnostics map to only show entries with diagnostics
    const activeDiagnostics = new Map(
      [...snap.diagnosticsMap.entries()].filter(
        ([_, diags]) => diags.length > 0,
      ),
    );

    const allDiags = [...activeDiagnostics.values()].flat();
    const totalDiags = allDiags.length;
    const errorCount = allDiags.filter((d) => d.severity === 1).length;
    const warnCount = allDiags.filter((d) => d.severity === 2).length;

    const LABEL_W = 12;
    const row = (label: string, value: string) =>
      `${d(padRight(label, LABEL_W))}  ${value}`;

    const isCollecting = snap.pendingWaiters.length > 0;
    const statusText = isCollecting
      ? th.fg("warning", `● collecting (${snap.pendingWaiters.length} pending)`)
      : th.fg("success", "● idle");

    // Server info section
    lines.push(b("Server Info"));
    lines.push(row("Status", statusText));
    lines.push(row("Binary", b(snap.bin)));
    lines.push(row("Full path", snap.command[0] ?? d("(none)")));
    lines.push(
      row("Arguments", snap.command.slice(1).join(" ") || d("(none)")),
    );
    lines.push(row("Root dir", snap.rootDir));
    lines.push(
      row(
        "Started",
        `${snap.startedAt.toLocaleTimeString()}  ${d(elapsedSince(snap.startedAt))}`,
      ),
    );

    // Timing metrics section
    lines.push("");
    lines.push(b("Timing Metrics"));
    lines.push(row("Init time", `${snap.initDurationMs}ms`));
    if (snap.lastCheckDurationMs > 0) {
      const checkStatus = snap.lastCheckReceivedResponse
        ? th.fg("success", "✓ received")
        : th.fg("error", "✖ TIMEOUT");
      lines.push(
        row("Last check", `${snap.lastCheckDurationMs}ms  ${checkStatus}`),
      );
    } else {
      lines.push(row("Last check", d("(no checks yet)")));
    }
    lines.push(row("Notifs recv", String(snap.totalNotificationsReceived)));
    lines.push(row("Notifs sent", String(snap.versionCounter - 1)));

    lines.push(row("Files open", String(snap.openedFiles.length)));
    lines.push(
      row(
        "Diagnostics",
        `${totalDiags} total  ` +
          th.fg("error", `${errorCount} error(s)`) +
          `  ` +
          th.fg("warning", `${warnCount} warning(s)`),
      ),
    );

    // Settings section
    if (snap.settings && Object.keys(snap.settings).length > 0) {
      lines.push("");
      lines.push(b("Settings"));
      for (const l of JSON.stringify(snap.settings, null, 2).split("\n")) {
        lines.push("  " + l);
      }
    }

    // Debug section (show if there was a timeout or mismatch)
    if (!snap.lastCheckReceivedResponse || snap.lastMismatchInfo) {
      lines.push("");
      lines.push(b(th.fg("warning", "Debug Info")));
      if (snap.lastMismatchInfo) {
        lines.push(th.fg("error", "  URI Mismatch Detected:"));
        for (const line of snap.lastMismatchInfo.split("\n")) {
          lines.push("    " + line);
        }
      }
      if (snap.pendingUris.length > 0) {
        lines.push(d("  Last pending URIs:"));
        for (const uri of snap.pendingUris) {
          lines.push("    " + uri);
        }
      }
      if (snap.receivedUris.length > 0) {
        lines.push(d("  Last received URIs:"));
        for (const uri of snap.receivedUris) {
          lines.push("    " + uri);
        }
      }
    }

    // Open files section
    lines.push("");
    lines.push(b(`Open Files (${snap.openedFiles.length})`));
    if (snap.openedFiles.length === 0) {
      lines.push(d("  (none)"));
    } else {
      for (const uri of snap.openedFiles) {
        const filePath = uri.replace(/^file:\/\//, "");
        const diags = snap.diagnosticsMap.get(uri) ?? [];
        const errors = diags.filter((dg) => dg.severity === 1).length;
        const warns = diags.filter((dg) => dg.severity === 2).length;
        const infos = diags.filter((dg) => dg.severity === 3).length;
        const hints = diags.filter((dg) => dg.severity === 4).length;
        const badge =
          diags.length === 0
            ? "  " + th.fg("success", "✓")
            : "  " +
              (errors > 0 ? th.fg("error", `✖ ${errors}`) : "") +
              (warns > 0 ? " " + th.fg("warning", `⚠ ${warns}`) : "") +
              (infos > 0 ? " " + th.fg("muted", ` ${infos}`) : "") +
              (hints > 0 ? " " + th.fg("muted", ` ${hints}`) : "");
        lines.push(`  ${filePath}${badge}`);
      }
    }

    // Diagnostics detail section
    lines.push("");
    lines.push(b(`Diagnostics Detail (${totalDiags})`));
    if (totalDiags === 0) {
      lines.push(
        "  " + th.fg("success", "✓ No diagnostics — clean bill of health!"),
      );
    } else {
      for (const [uri, diags] of activeDiagnostics.entries()) {
        if (diags.length === 0) continue;
        lines.push(`  ${d(uri.replace(/^file:\/\//, ""))}`);
        for (const diag of diags) {
          const sev =
            diag.severity === 1
              ? th.fg("error", "error  ")
              : diag.severity === 2
                ? th.fg("warning", "warning")
                : d("info   ");
          const loc = `${diag.range.start.line + 1}:${diag.range.start.character + 1}`;
          const src = diag.source ? d(` [${diag.source}]`) : "";
          const code = diag.code != null ? d(` (${diag.code})`) : "";
          lines.push(
            `    ${sev}  ${padRight(loc, 8)} ${diag.message}${src}${code}`,
          );
        }
        lines.push("");
      }
    }

    return lines;
  }

  private box(contentLines: string[], width: number, title: string): string[] {
    const th = this.theme;
    const innerW = Math.max(1, width - 2);
    const result: string[] = [];

    // Top border with title
    const titleStr = truncateToWidth(` ${title} `, innerW);
    const titleW = visibleWidth(titleStr);
    const topLine = "─".repeat(Math.floor((innerW - titleW) / 2));
    const topLine2 = "─".repeat(Math.max(0, innerW - titleW - topLine.length));
    result.push(
      th.fg("border", `╭${topLine}`) +
        th.fg("accent", titleStr) +
        th.fg("border", `${topLine2}╮`),
    );

    // Content with scroll support
    for (const line of contentLines) {
      result.push(
        th.fg("border", "│") +
          truncateToWidth(" " + line, innerW, "...", true) +
          th.fg("border", "│"),
      );
    }

    // Bottom border
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

    const prev = () => {
      if (this.selectedIdx > 0) {
        this.selectedIdx--;
        this.scrollOffset = 0;
        this.tui.requestRender();
      }
    };
    const next = () => {
      if (this.selectedIdx < this.snapshots.length - 1) {
        this.selectedIdx++;
        this.scrollOffset = 0;
        this.tui.requestRender();
      }
    };

    if (matchesKey(data, "left") || data.toLowerCase() === "h") prev();
    if (matchesKey(data, "right") || data.toLowerCase() === "l") next();
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
    if (matchesKey(data, "ctrl+u") || data === "\x1b[5~") {
      // Page up: scroll half viewport (^U or PgUp key sequence)
      const terminalHeight = process.stdout.rows ?? 40;
      const viewportLines = Math.floor(terminalHeight * 0.85) - 2;
      const pageSize = Math.max(1, Math.floor(viewportLines / 2));
      this.scrollOffset = Math.max(0, this.scrollOffset - pageSize);
      this.tui.requestRender();
    }
    if (matchesKey(data, "ctrl+d") || data === "\x1b[6~") {
      // Page down: scroll half viewport (^D or PgDn key sequence)
      const terminalHeight = process.stdout.rows ?? 40;
      const viewportLines = Math.floor(terminalHeight * 0.85) - 2;
      const pageSize = Math.max(1, Math.floor(viewportLines / 2));
      this.scrollOffset += pageSize;
      this.tui.requestRender();
    }
    if (matchesKey(data, "home") || data === "g") {
      // Jump to top
      this.scrollOffset = 0;
      this.tui.requestRender();
    }
    if (matchesKey(data, "end") || data === "G") {
      // Jump to bottom
      const contentLines = this.buildContentLines();
      const terminalHeight = process.stdout.rows ?? 40;
      const viewportLines = Math.floor(terminalHeight * 0.85) - 2;
      this.scrollOffset = Math.max(0, contentLines.length - viewportLines);
      this.tui.requestRender();
    }
  }

  invalidate(): void {
    // Force rebuild on next render
  }

  render(width: number): string[] {
    const contentLines = this.buildContentLines();

    // Get actual terminal height (default to 40 if not available)
    const terminalHeight = process.stdout.rows ?? 40;
    // Overlay with 85% maxHeight from overlayOptions, with margin
    const maxOverlayHeight = Math.floor(terminalHeight * 0.85);
    // Account for box borders (top + bottom = 2 lines)
    const viewportLines = Math.max(1, maxOverlayHeight - 2);

    // Clamp scroll
    const maxScroll = Math.max(0, contentLines.length - viewportLines);
    this.scrollOffset = Math.min(this.scrollOffset, maxScroll);

    // Slice visible content
    const visibleContent = contentLines.slice(
      this.scrollOffset,
      this.scrollOffset + viewportLines,
    );

    // Build title with navigation hints and scroll indicator
    const navHint = this.snapshots.length > 1 ? " ←→/hl:server" : "";
    const scrollHint =
      contentLines.length > viewportLines
        ? ` ${this.scrollOffset + 1}-${Math.min(this.scrollOffset + viewportLines, contentLines.length)}/${contentLines.length}`
        : "";
    const title = `LSP Server Details${navHint} · ↑↓/jk:scroll · ^u/^d/PgUp/PgDn:page · g/G/Home/End:jump · q:close${scrollHint}`;

    return this.box(visibleContent, width, title);
  }

  dispose(): void {
    // Cleanup if needed
  }
}
