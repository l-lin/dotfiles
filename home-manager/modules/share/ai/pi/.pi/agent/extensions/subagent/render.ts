/** Rendering for subagent tool calls, results, and notifications */

import * as path from "node:path";
import { getMarkdownTheme } from "@mariozechner/pi-coding-agent";
import {
  Box,
  Container,
  Markdown,
  Spacer,
  Text,
  truncateToWidth,
} from "@mariozechner/pi-tui";
import { Action } from "./sessions.js";
import type { SubagentDetails } from "./sessions.js";

type Theme = { fg: Function; bg: Function; bold: Function };

// ─── renderCall ──────────────────────────────────────────────────────────────

export function renderListCall(args: any, theme: Theme): Text {
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));
  return new Text(title("󰚩 subagent list"), 0, 0);
}

export function renderCall(args: any, theme: Theme): Text {
  const action = args.action || "?";
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));

  if (action === Action.Spawn) {
    if (args.tasks?.length > 0) {
      let text =
        title("󰚩 subagent spawn ") +
        theme.fg("accent", `${args.tasks.length} panes`);
      for (const t of args.tasks.slice(0, 3)) {
        text += `\n  ${theme.fg("accent", t.agent)}${theme.fg("dim", ` ${truncateToWidth(t.task, 40)}`)}`;
      }
      if (args.tasks.length > 3)
        text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
      return new Text(text, 0, 0);
    }
    return new Text(
      title("󰚩 subagent spawn ") +
        theme.fg("accent", args.agent || "...") +
        `\n  ${theme.fg("dim", truncateToWidth(args.task || "...", 60))}`,
      0,
      0,
    );
  }

  if (action === Action.Send) {
    return new Text(
      title("󱃜 subagent send ") +
        theme.fg("accent", args.id || "?") +
        `\n  ${theme.fg("dim", truncateToWidth(args.message || "...", 50))}`,
      0,
      0,
    );
  }

  if (action === Action.Read) {
    return new Text(
      title(" subagent read ") + theme.fg("accent", args.id || "(all)"),
      0,
      0,
    );
  }

  if (action === Action.Close) {
    return new Text(
      title("󱚧 subagent close ") + theme.fg("accent", args.id || "?"),
      0,
      0,
    );
  }

  return new Text(title("subagent ") + theme.fg("dim", action), 0, 0);
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
      // Raw text format: "Spawned X sub-agent(s):\n- ...\n\n<instructions>"
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
  let rendered = theme.fg("toolOutput", firstLine);
  return new Text(rendered, 0, 0);
}

// ─── message renderer for subagent-result notifications ──────────────────────

export function renderMessage(
  message: any,
  { expanded }: { expanded: boolean },
  theme: Theme,
) {
  const details = message.details as
    | { sessionId?: string; agentName?: string }
    | undefined;
  const id = details?.sessionId ?? "?";
  const mdTheme = getMarkdownTheme();
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));

  const isAllDone = (details as any)?.action === Action.AllDone;
  const header = isAllDone
    ? `${title("󱃚 subagent report")} ${theme.fg("success", "all")}`
    : `${title("󱃚 subagent report")} ${theme.fg("accent", id)}`;
  const box = new Box(1, 1, (s: string) => theme.bg("toolSuccessBg", s));

  if (expanded) {
    box.addChild(new Text(header, 0, 0));
    box.addChild(new Spacer(1));
    box.addChild(
      new Markdown(message.content?.trim() ?? "(empty)", 0, 0, mdTheme),
    );
    return box;
  }

  box.addChild(new Text(header, 0, 0));
  return box;
}
