import {
  matchesKey,
  truncateToWidth,
  visibleWidth,
  type Component,
} from "@mariozechner/pi-tui";
import type { ContextViewData } from "./types.js";
import {
  SYSTEM_FG,
  TOOLS_FG,
  WINDOW_FG,
  CONVO_FG,
  FREE_FG,
  ICON_WINDOW,
  ICON_SYSTEM,
  ICON_TOOLS,
  ICON_AGENTS,
  ICON_EXTENSIONS,
  ICON_SKILLS,
  ICON_SUBAGENTS,
  ICON_SESSION,
} from "./types.js";
import { formatUsd, joinComma } from "./utils.js";

function wrapItems(
  items: string[],
  maxWidth: number,
  indent: string = "  ",
  firstLineIndent: string = "  ",
): string[] {
  if (items.length === 0) return [];

  const lines: string[] = [];
  let currentLine = "";

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const sep = i < items.length - 1 ? ", " : "";
    const token = item + sep;
    const prefix = !currentLine
      ? lines.length === 0
        ? firstLineIndent
        : indent
      : "";

    if (!currentLine) {
      currentLine = prefix + token;
    } else {
      const testLine = currentLine + token;
      if (visibleWidth(testLine) <= maxWidth) {
        currentLine = testLine;
      } else {
        lines.push(currentLine);
        currentLine = indent + token;
      }
    }
  }

  if (currentLine) lines.push(currentLine);
  return lines;
}

function renderUsageBar(
  theme: any,
  parts: { system: number; tools: number; convo: number; remaining: number },
  total: number,
  width: number,
): string {
  const barWidth = Math.max(10, width);
  if (total <= 0) return "";

  const tokensToColumns = (tokens: number) =>
    Math.round((tokens / total) * barWidth);

  let systemCols = tokensToColumns(parts.system);
  let toolsCols = tokensToColumns(parts.tools);
  let convoCols = tokensToColumns(parts.convo);
  let remainingCols = barWidth - systemCols - toolsCols - convoCols;

  // Ensure tools are visible if they exist
  if (parts.tools > 0 && toolsCols === 0) {
    toolsCols = 1;
    if (remainingCols > 0) remainingCols--;
    else if (convoCols > 0) convoCols--;
    else if (systemCols > 0) systemCols--;
  }

  // Adjust for rounding errors
  remainingCols = Math.max(0, remainingCols);
  const actualTotal = systemCols + toolsCols + convoCols + remainingCols;
  remainingCols += barWidth - actualTotal;

  const block = "█";
  return (
    theme.fg(SYSTEM_FG, block.repeat(systemCols)) +
    theme.fg(TOOLS_FG, block.repeat(toolsCols)) +
    theme.fg(CONVO_FG, block.repeat(convoCols)) +
    theme.fg(FREE_FG, block.repeat(remainingCols))
  );
}

export class ContextView implements Component {
  private theme: any;
  private onDone: () => void;
  private data: ContextViewData;

  constructor(theme: any, data: ContextViewData, onDone: () => void) {
    this.theme = theme;
    this.data = data;
    this.onDone = onDone;
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

  private buildContent(): string[] {
    const dim = (s: string) => this.theme.fg("dim", s);
    const label = (icon: string, s: string) =>
      icon + " " + this.theme.bold(this.theme.fg("text", s));

    const lines: string[] = [];
    const maxWidth = 80;

    if (!this.data.usage) {
      lines.push(label(ICON_WINDOW, "Window:") + " " + dim("(unknown)"));
    } else {
      const u = this.data.usage;
      lines.push(
        label(ICON_WINDOW, "Window:") +
          " " +
          this.theme.fg(WINDOW_FG, `~${u.effectiveTokens.toLocaleString()}`) +
          dim(
            ` / ${u.contextWindow.toLocaleString()}  (${u.percent.toFixed(1)}% used, ~${u.remainingTokens.toLocaleString()} left)`,
          ),
      );

      const barWidth = Math.max(10, 36);
      const sysInMessages = Math.min(u.systemPromptTokens, u.messageTokens);
      const convoInMessages = Math.max(0, u.messageTokens - sysInMessages);
      const bar =
        renderUsageBar(
          this.theme,
          {
            system: sysInMessages,
            tools: u.toolsTokens,
            convo: convoInMessages,
            remaining: u.remainingTokens,
          },
          u.contextWindow,
          barWidth,
        ) +
        " " +
        dim("sys") +
        this.theme.fg(SYSTEM_FG, "█") +
        " " +
        dim("tools") +
        this.theme.fg(TOOLS_FG, "█") +
        " " +
        dim("convo") +
        this.theme.fg(CONVO_FG, "█") +
        " " +
        dim("free") +
        this.theme.fg(FREE_FG, "█");
      lines.push(bar);
    }

    lines.push("");

    if (this.data.usage) {
      const u = this.data.usage;
      lines.push(
        label(ICON_SYSTEM, "System:") +
          " " +
          this.theme.fg(
            SYSTEM_FG,
            `~${u.systemPromptTokens.toLocaleString()} tok`,
          ),
      );
      lines.push(
        label(ICON_TOOLS, `Tools (${u.activeTools}):`) +
          " " +
          this.theme.fg(TOOLS_FG, `~${u.toolsTokens.toLocaleString()} tok`),
      );
      if (this.data.activeToolNames.length > 0) {
        const wrapped = wrapItems(
          this.data.activeToolNames.slice().sort().map(dim),
          maxWidth,
        );
        lines.push(...wrapped);
      }
    }

    lines.push(label(ICON_AGENTS, `AGENTS (${this.data.agentFiles.length}):`));
    if (this.data.agentFiles.length === 0) {
      lines.push("  " + dim("(none)"));
    } else {
      for (const f of this.data.agentFiles) {
        lines.push(
          "  " +
            dim(f.path) +
            "  " +
            this.theme.fg(SYSTEM_FG, `~${f.tokens.toLocaleString()} tok`),
        );
      }
    }

    const skillLabel = label(
      ICON_SKILLS,
      `Skills (${this.data.skills.length}):`,
    );
    const skillTokenInfo =
      this.data.skillDescTokens > 0
        ? " " +
          this.theme.fg(
            SYSTEM_FG,
            `~${this.data.skillDescTokens.toLocaleString()} tok`,
          )
        : "";
    lines.push(skillLabel + skillTokenInfo);
    if (this.data.skills.length === 0) {
      lines.push("  " + dim("(none)"));
    } else {
      const loaded = new Set(this.data.loadedSkills);
      const styledSkills = this.data.skills.map((name) =>
        loaded.has(name) ? this.theme.fg("success", name) : dim(name),
      );
      const wrapped = wrapItems(styledSkills, maxWidth);
      lines.push(...wrapped);
    }

    lines.push(
      label(ICON_EXTENSIONS, `Extensions (${this.data.extensions.length}):`),
    );
    if (this.data.extensions.length === 0) {
      lines.push("  " + dim("(none)"));
    } else {
      const wrapped = wrapItems(this.data.extensions.map(dim), maxWidth);
      lines.push(...wrapped);
    }

    lines.push(
      label(ICON_SUBAGENTS, `Subagents (${this.data.subagents.length}):`),
    );
    if (this.data.subagents.length === 0) {
      lines.push("  " + dim("(none)"));
    } else {
      const wrapped = wrapItems(this.data.subagents.map(dim), maxWidth);
      lines.push(...wrapped);
    }
    lines.push("");
    lines.push(
      label(ICON_SESSION, "Session:") +
        " " +
        dim(
          `${this.data.session.totalTokens.toLocaleString()} tok · ${formatUsd(this.data.session.totalCost)}`,
        ),
    );

    return lines;
  }

  handleInput(data: string): void {
    if (
      matchesKey(data, "escape") ||
      matchesKey(data, "ctrl+c") ||
      data.toLowerCase() === "q" ||
      data === "\r"
    ) {
      this.onDone();
      return;
    }
  }

  invalidate(): void {}

  render(width: number): string[] {
    const content = this.buildContent();
    const title = "Context · Esc/q/Enter:close";
    return this.box(content, width, title);
  }
}

export function makePlainTextView(data: ContextViewData): string {
  const lines: string[] = [];
  lines.push("Context");
  if (data.usage) {
    const u = data.usage;
    lines.push(
      `Window: ~${u.effectiveTokens.toLocaleString()} / ${u.contextWindow.toLocaleString()} (${u.percent.toFixed(1)}% used, ~${u.remainingTokens.toLocaleString()} left)`,
    );
    lines.push(`System: ~${u.systemPromptTokens.toLocaleString()} tok`);
    lines.push(
      `Tools: ~${u.toolsTokens.toLocaleString()} tok (${data.activeToolNames.length} active)` +
        (data.activeToolNames.length
          ? ` — ${data.activeToolNames.slice().sort().join(", ")}`
          : ""),
    );
  } else {
    lines.push("Window: (unknown)");
  }
  if (data.agentFiles.length > 0) {
    lines.push(
      `AGENTS: ${data.agentFiles.map((f) => `${f.path} ~${f.tokens.toLocaleString()} tok`).join(", ")}`,
    );
  } else {
    lines.push("AGENTS: (none)");
  }
  lines.push(
    `Skills (${data.skills.length}): ${data.skillDescTokens > 0 ? `~${data.skillDescTokens.toLocaleString()} tok  ` : ""}${data.skills.length ? joinComma(data.skills) : "(none)"}`,
  );
  lines.push(
    `Extensions (${data.extensions.length}): ${data.extensions.length ? joinComma(data.extensions) : "(none)"}`,
  );
  lines.push(
    `Subagents (${data.subagents.length}): ${data.subagents.length ? joinComma(data.subagents) : "(none)"}`,
  );
  lines.push(
    `Session: ${data.session.totalTokens.toLocaleString()} tok · ${formatUsd(data.session.totalCost)}`,
  );
  return lines.join("\n");
}
