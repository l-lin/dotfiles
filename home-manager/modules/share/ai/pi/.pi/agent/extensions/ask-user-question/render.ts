/** Rendering for ask-user-question tool calls and results. */

import type {
  AgentToolResult,
  Theme,
  ThemeColor,
  ToolRenderResultOptions,
} from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import type { Question, Result } from "./types.js";

/**
 * Truncate plain text to maxWidth, then apply a theme color.
 *
 * We truncate before applying ANSI codes so that `theme.fg` wraps only clean
 * text — otherwise embedded resets cause background color bleed on light themes.
 */
function styledTruncate(
  theme: Theme,
  colorKey: ThemeColor,
  text: string,
  maxWidth: number,
  ellipsis = "...",
): string {
  if (maxWidth <= 0) return "";
  if (maxWidth <= ellipsis.length) return ellipsis.slice(0, maxWidth);
  const truncated =
    text.length <= maxWidth
      ? text
      : text.slice(0, maxWidth - ellipsis.length) + ellipsis;
  return theme.fg(colorKey, truncated);
}

export function renderCall(args: any, theme: Theme): Text {
  const qs = (args.questions as Question[]) || [];
  let text = theme.fg("toolTitle", theme.bold("ask-user-question "));
  text += theme.fg(
    "muted",
    `${qs.length} question${qs.length !== 1 ? "s" : ""}`,
  );
  const labels = qs.map((q) => q.label || q.id).join(", ");
  if (labels) text += styledTruncate(theme, "dim", ` ${labels}`, 40);
  return new Text(text, 0, 0);
}

export function renderResult(
  result: AgentToolResult<Result>,
  _opts: ToolRenderResultOptions,
  theme: Theme,
): Text {
  const d = result.details as Result | undefined;
  if (!d) {
    const text =
      result.content[0]?.type === "text" ? result.content[0].text : "";
    return new Text(text, 0, 0);
  }
  if (d.cancelled) return new Text(theme.fg("warning", "Cancelled"), 0, 0);
  return new Text(
    d.answers
      .map((a) => {
        const display = a.wasCustom
          ? `${theme.fg("muted", "(wrote) ")}${a.label}`
          : a.index
            ? `${a.index}. ${a.label}`
            : a.label;
        return `${theme.fg("success", "✓ ")}${theme.fg("accent", a.id)}: ${display}`;
      })
      .join("\n"),
    0,
    0,
  );
}
