/** Rendering for subagent tool calls, results, and notifications */

import { getMarkdownTheme } from "@mariozechner/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@mariozechner/pi-tui";
import type { SubagentDetails } from "./types.js";

type Theme = { fg: Function; bg: Function; bold: Function };

function truncate(s: string, max: number): string {
  return s.length > max ? `${s.slice(0, max)}...` : s;
}

// ─── renderCall ──────────────────────────────────────────────────────────────

export function renderCall(args: any, theme: Theme): Text {
  const action = args.action || "?";
  const title = (s: string) => theme.fg("toolTitle", theme.bold(s));

  if (action === "spawn") {
    if (args.tasks?.length > 0) {
      let text = title("subagent spawn ") + theme.fg("accent", `${args.tasks.length} panes`);
      for (const t of args.tasks.slice(0, 3)) {
        text += `\n  ${theme.fg("accent", t.agent)}${theme.fg("dim", ` ${truncate(t.task, 40)}`)}`;
      }
      if (args.tasks.length > 3) text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
      return new Text(text, 0, 0);
    }
    return new Text(
      title("subagent spawn ") + theme.fg("accent", args.agent || "...") +
      `\n  ${theme.fg("dim", truncate(args.task || "...", 60))}`,
      0, 0,
    );
  }

  if (action === "send") {
    return new Text(
      title("subagent send ") + theme.fg("accent", args.id || "?") +
      `\n  ${theme.fg("dim", truncate(args.message || "...", 50))}`,
      0, 0,
    );
  }

  if (action === "read") {
    return new Text(title("subagent read ") + theme.fg("accent", args.id || "(all)"), 0, 0);
  }

  if (action === "close") {
    return new Text(title("subagent close ") + theme.fg("accent", args.id || "?"), 0, 0);
  }

  return new Text(title("subagent ") + theme.fg("dim", action), 0, 0);
}

// ─── renderResult ────────────────────────────────────────────────────────────

export function renderResult(result: any, { expanded }: { expanded: boolean }, theme: Theme) {
  const details = result.details as SubagentDetails | undefined;
  const mdTheme = getMarkdownTheme();
  const textContent = result.content[0]?.type === "text" ? result.content[0].text : "(no output)";

  // Spawn: show session IDs prominently
  if (details?.action === "spawn" && details.spawned?.length) {
    const container = new Container();
    for (const s of details.spawned) {
      container.addChild(new Text(
        `${theme.fg("success", "▶")} ${theme.fg("toolTitle", theme.bold(s.agent))} ${theme.fg("muted", `(${s.agentSource})`)} → ${theme.fg("accent", s.id)}`,
        0, 0,
      ));
    }
    if (expanded) {
      container.addChild(new Spacer(1));
      container.addChild(new Markdown(textContent.trim(), 0, 0, mdTheme));
    }
    return container;
  }

  // Default
  if (expanded) return new Markdown(textContent.trim(), 0, 0, mdTheme);

  const lines = textContent.split("\n");
  let rendered = theme.fg("toolOutput", lines.slice(0, 5).join("\n"));
  if (lines.length > 5) rendered += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
  return new Text(rendered, 0, 0);
}

// ─── message renderer for subagent-result notifications ──────────────────────

export function renderMessage(message: any, { expanded }: { expanded: boolean }, theme: Theme) {
  const details = message.details as { sessionId?: string; agentName?: string } | undefined;
  const name = details?.agentName ?? "sub-agent";
  const id = details?.sessionId ?? "?";
  const mdTheme = getMarkdownTheme();

  const header = `${theme.fg("accent", "📨")} ${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("muted", `(${id})`)}`;

  if (expanded) {
    const container = new Container();
    container.addChild(new Text(header, 0, 0));
    container.addChild(new Spacer(1));
    container.addChild(new Markdown(message.content?.trim() ?? "(empty)", 0, 0, mdTheme));
    return container;
  }

  const content = message.content ?? "";
  const lines = content.split("\n");
  let text = header + `\n${theme.fg("toolOutput", lines.slice(0, 5).join("\n"))}`;
  if (lines.length > 5) text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
  return new Text(text, 0, 0);
}
