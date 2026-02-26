/** Rendering for subagent tool calls, results, and notifications */

import { getMarkdownTheme } from "@mariozechner/pi-coding-agent";
import { Box, Container, Markdown, Spacer, Text } from "@mariozechner/pi-tui";
import { Action } from "./sessions.js";
import type { SubagentDetails } from "./sessions.js";

type Theme = { fg: Function; bg: Function; bold: Function };

/**
 * Truncate plain text to maxWidth, then apply a theme color.
 *
 * We strip ANSI codes first so that `theme.fg` wraps only clean text
 * with no embedded resets — otherwise `truncateToWidth` injects `\x1b[0m`
 * before the ellipsis, which gets wrapped inside the background color and
 * causes the background to bleed past the visible characters on light themes.
 */
function styledTruncate(
  theme: Theme,
  colorKey: string,
  text: string,
  maxWidth: number,
  ellipsis = "...",
): string {
  const truncated =
    text.length <= maxWidth
      ? text
      : text.slice(0, maxWidth - ellipsis.length) + ellipsis;
  return theme.fg(colorKey, truncated);
}

// ─── renderCall ──────────────────────────────────────────────────────────────

export function renderListCall(_: any, theme: Theme): Text {
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));
  return new Text(title("󰚩 subagent list"), 0, 0);
}

export function renderSpawnCall(args: any, theme: Theme): Text {
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));
  if (args.tasks?.length > 0) {
    let text =
      title("󰚩 subagent spawn ") +
      theme.fg("accent", `${args.tasks.length} agents`);
    for (const t of args.tasks.slice(0, 3)) {
      text += `\n  ${theme.fg("accent", t.agent)} ${styledTruncate(theme, "dim", t.task, 40)}`;
    }
    if (args.tasks.length > 3)
      text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
    return new Text(text, 0, 0);
  }
  // Single agent: one compact line — agent name + truncated task inline
  const agent = args.agent || "...";
  const task = args.task
    ? ` ${styledTruncate(theme, "dim", args.task, 50)}`
    : "";
  return new Text(
    title("󰚩 subagent spawn ") + theme.fg("accent", agent) + task,
    0,
    0,
  );
}

export function renderSendCall(args: any, theme: Theme): Text {
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));
  const msg = args.message
    ? ` ${styledTruncate(theme, "dim", args.message, 50)}`
    : "";
  return new Text(
    title("󱃜 subagent send ") + theme.fg("accent", args.id || "?") + msg,
    0,
    0,
  );
}

export function renderCloseCall(args: any, theme: Theme): Text {
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));
  return new Text(
    title("󱚧 subagent close ") + theme.fg("accent", args.id || "?"),
    0,
    0,
  );
}

// ─── renderListResult ────────────────────────────────────────────────────────

export function renderListResult(
  result: any,
  { expanded }: { expanded: boolean },
  theme: Theme,
) {
  const details = result.details as
    | { action?: string; count?: number }
    | undefined;
  const mdTheme = getMarkdownTheme();
  const textContent =
    result.content[0]?.type === "text" ? result.content[0].text : "(no output)";

  if (details?.action === Action.List && details.count !== undefined) {
    if (expanded) {
      return new Markdown(textContent.trim(), 0, 0, mdTheme);
    }
    return new Text(
      theme.fg(
        "toolOutput",
        `Found ${details.count} available subagent${details.count === 1 ? "" : "s"}.`,
      ),
      0,
      0,
    );
  }

  // Fallback
  if (expanded) return new Markdown(textContent.trim(), 0, 0, mdTheme);
  return new Text(
    theme.fg("toolOutput", textContent.trim().split("\n")[0]),
    0,
    0,
  );
}

// ─── renderResult ────────────────────────────────────────────────────────────

export function renderResult(
  result: any,
  { expanded }: { expanded: boolean },
  theme: Theme,
) {
  const details = result.details as SubagentDetails | undefined;
  const mdTheme = getMarkdownTheme();
  const textContent =
    result.content[0]?.type === "text" ? result.content[0].text : "(no output)";

  // Spawn: show session IDs prominently
  if (details?.action === Action.Spawn && details.spawned?.length) {
    if (!expanded && details.spawned.length === 1) {
      // Single spawn collapsed: one compact line with session ID only
      const s = details.spawned[0];
      return new Text(
        `  ${theme.fg("success", "▶")} ${theme.fg("accent", s.id)}`,
        0,
        0,
      );
    }
    const container = new Container();
    for (const s of details.spawned) {
      container.addChild(
        new Text(
          `  ${theme.fg("success", "▶")} ${theme.fg("accent", s.id)}`,
          0,
          0,
        ),
      );
    }
    if (expanded) {
      // Raw text format: "Spawned X subagent(s):\n- ...\n\n<instructions>"
      // Skip the session list lines (already shown visually) and show only
      // the instructions that follow the first blank line.
      const separatorIdx = textContent.indexOf("\n\n");
      const extraText =
        separatorIdx >= 0 ? textContent.slice(separatorIdx + 2).trim() : "";
      if (extraText) {
        container.addChild(new Spacer(1));
        container.addChild(new Markdown(extraText, 0, 0, mdTheme));
      }
    }
    return container;
  }

  // All non-spawn actions: collapsed = first line only, expanded = full markdown
  if (expanded) return new Markdown(textContent.trim(), 0, 0, mdTheme);

  if (!textContent.trim()) return new Text("", 0, 0);

  const firstLine = textContent.split("\n")[0].trim();
  const rendered = theme.fg("toolOutput", firstLine);
  return new Text(rendered, 0, 0);
}

// ─── message renderer for subagent-result notifications ──────────────────────

export function renderMessage(
  message: any,
  { expanded }: { expanded: boolean },
  theme: Theme,
) {
  const details = message.details as SubagentDetails | undefined;
  const id = details?.sessionId ?? "?";
  const mdTheme = getMarkdownTheme();
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));

  const isAll =
    details?.action === Action.AllDone || details?.sessionId === "all";
  const header = isAll
    ? `${title("󱃚 subagent report")} ${theme.fg("success", "all")}`
    : `${title("󱃚 subagent report")} ${theme.fg("accent", id)}`;

  const box = new Box(1, 1, (t) => theme.bg("toolSuccessBg", t));

  if (expanded) {
    const container = new Container();
    container.addChild(new Text(header, 0, 0));
    container.addChild(new Spacer(1));
    container.addChild(
      new Markdown(message.content?.trim() ?? "(empty)", 0, 0, mdTheme),
    );
    box.addChild(container);
    return box;
  }

  box.addChild(new Text(header, 0, 0));
  return box;
}
