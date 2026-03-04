/**
 * LspDebugComponent — interactive TUI panel for inspecting active LSP clients.
 */
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import {
  Container,
  Key,
  Text,
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
}

// ── Component ─────────────────────────────────────────────────────────────────

export class LspDebugComponent implements Component {
  // Rows reserved for fixed structural chrome: 2× DynamicBorder + title + 2× padding + tab bar
  private static readonly STRUCTURAL_ROWS = 6;

  private snapshots: LspClientEntrySnapshot[] = [];
  private lspClients: Map<string, LspClientEntry>;
  private tui: TUI;
  private theme: any;
  private onDone: (result?: unknown) => void;
  private selectedIdx = 0;
  private scrollOffset = 0;
  private container: Container;
  private body: Text;
  private cachedWidth?: number;
  private cachedHeight?: number;

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

    this.container = new Container();
    this.container.addChild(
      new DynamicBorder((s: string) => theme.fg("accent", s)),
    );
    this.container.addChild(
      new Text(
        theme.fg("accent", theme.bold("LSP Server Debug")) +
          theme.fg(
            "dim",
            "  (←/→ server · ↑↓/jk scroll · ^u/^d page · q close)",
          ),
        1,
        0,
      ),
    );
    this.container.addChild(new Text("", 1, 0));
    this.body = new Text("", 1, 0);
    this.container.addChild(this.body);
    this.container.addChild(new Text("", 1, 0));
    this.container.addChild(
      new DynamicBorder((s: string) => theme.fg("accent", s)),
    );
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

  private get terminalHeight(): number {
    // TUI.terminal.rows gives the actual terminal height
    return (this.tui as any).terminal?.rows ?? 24;
  }

  private rebuild(width: number): void {
    this.refreshSnapshots();
    const th = this.theme;
    const d = (s: string) => th.fg("dim", s);
    const b = (s: string) => th.bold(s);
    const divider = d("─".repeat(Math.max(0, width - 4)));

    if (this.snapshots.length === 0) {
      this.body.setText(d("No active LSP servers."));
      this.cachedWidth = width;
      return;
    }

    const lines: string[] = [];

    // Tab bar
    const tabs = this.snapshots
      .map((s, i) =>
        i === this.selectedIdx
          ? b(th.fg("accent", `[${s.bin}]`))
          : d(` ${s.bin} `),
      )
      .join("  ");
    lines.push(tabs);
    lines.push("");

    const snap = this.snapshots[this.selectedIdx];
    if (!snap) {
      this.body.setText(d("No active LSP servers."));
      this.cachedWidth = width;
      return;
    }
    const allDiags = [...snap.diagnosticsMap.values()].flat();
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

    // ── Settings ─────────────────────────────────────────────────────────────
    lines.push("");
    lines.push(divider);
    lines.push(b("Settings"));
    if (!snap.settings || Object.keys(snap.settings).length === 0) {
      lines.push(d("  (none)"));
    } else {
      for (const l of JSON.stringify(snap.settings, null, 2).split("\n")) {
        lines.push("  " + l);
      }
    }

    // ── Open files ────────────────────────────────────────────────────────────
    lines.push("");
    lines.push(divider);
    lines.push(b(`Open Files (${snap.openedFiles.length})`));
    if (snap.openedFiles.length === 0) {
      lines.push(d("  (none)"));
    } else {
      for (const uri of snap.openedFiles) {
        const filePath = uri.replace(/^file:\/\//, "");
        const diags = snap.diagnosticsMap.get(uri) ?? [];
        const errors = diags.filter((dg) => dg.severity === 1).length;
        const warns = diags.filter((dg) => dg.severity === 2).length;
        const badge =
          diags.length === 0
            ? "  " + th.fg("success", "✓")
            : "  " +
              (errors > 0 ? th.fg("error", `${errors}E`) : "") +
              (warns > 0 ? " " + th.fg("warning", `${warns}W`) : "");
        lines.push(`  ${filePath}${badge}`);
      }
    }

    // ── Diagnostics detail ────────────────────────────────────────────────────
    lines.push("");
    lines.push(divider);
    lines.push(b(`Diagnostics Detail (${totalDiags})`));
    if (totalDiags === 0) {
      lines.push(
        "  " + th.fg("success", "✓ No diagnostics — clean bill of health!"),
      );
    } else {
      for (const [uri, diags] of snap.diagnosticsMap.entries()) {
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

    // Clamp scroll so we never scroll past the last line, then slice a single
    // screenful so the component never emits more lines than the terminal can show.
    const termH = this.terminalHeight;
    // Reserve rows for the fixed structural lines surrounding the scrollable body:
    // 2× DynamicBorder + title line + 2× empty Text("") padding = 5 rows.
    // One extra row for the tab bar rendered at the top of the body itself.
    const viewportLines = Math.max(
      1,
      termH - LspDebugComponent.STRUCTURAL_ROWS,
    );
    const maxScroll = Math.max(0, lines.length - viewportLines);
    this.scrollOffset = Math.min(this.scrollOffset, maxScroll);
    const visible = lines.slice(
      this.scrollOffset,
      this.scrollOffset + viewportLines,
    );

    this.body.setText(
      visible
        .map((l) =>
          visibleWidth(l) > width - 4 ? truncateToWidth(l, width - 4) : l,
        )
        .join("\n"),
    );
    this.cachedWidth = width;
    this.cachedHeight = termH;
  }

  handleInput(data: string): void {
    if (
      matchesKey(data, Key.escape) ||
      matchesKey(data, Key.ctrl("c")) ||
      data.toLowerCase() === "q"
    ) {
      this.onDone();
      return;
    }

    const prev = () => {
      if (this.selectedIdx > 0) {
        this.selectedIdx--;
        this.scrollOffset = 0;
        this.cachedWidth = undefined;
        this.container.invalidate();
        this.tui.requestRender();
      }
    };
    const next = () => {
      if (this.selectedIdx < this.snapshots.length - 1) {
        this.selectedIdx++;
        this.scrollOffset = 0;
        this.cachedWidth = undefined;
        this.container.invalidate();
        this.tui.requestRender();
      }
    };

    if (matchesKey(data, Key.left) || data.toLowerCase() === "h") prev();
    if (matchesKey(data, Key.right) || data.toLowerCase() === "l") next();
    if (matchesKey(data, Key.up) || data === "k") {
      if (this.scrollOffset > 0) {
        this.scrollOffset--;
        this.cachedWidth = undefined;
        this.container.invalidate();
        this.tui.requestRender();
      }
    }
    if (matchesKey(data, Key.down) || data === "j") {
      this.scrollOffset++;
      this.cachedWidth = undefined;
      this.container.invalidate();
      this.tui.requestRender();
    }
    if (matchesKey(data, Key.ctrl("u"))) {
      const pageSize = Math.max(
        1,
        Math.floor(
          (this.terminalHeight - LspDebugComponent.STRUCTURAL_ROWS) / 2,
        ),
      );
      this.scrollOffset = Math.max(0, this.scrollOffset - pageSize);
      this.cachedWidth = undefined;
      this.container.invalidate();
      this.tui.requestRender();
    }
    if (matchesKey(data, Key.ctrl("d"))) {
      const pageSize = Math.max(
        1,
        Math.floor(
          (this.terminalHeight - LspDebugComponent.STRUCTURAL_ROWS) / 2,
        ),
      );
      this.scrollOffset += pageSize; // upper-bound clamped lazily in rebuild()
      this.cachedWidth = undefined;
      this.container.invalidate();
      this.tui.requestRender();
    }
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.container.invalidate();
  }

  render(width: number): string[] {
    if (this.cachedWidth !== width || this.cachedHeight !== this.terminalHeight)
      this.rebuild(width);
    return this.container.render(width);
  }
}
