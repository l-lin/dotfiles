import { Key, matchesKey, visibleWidth } from "@mariozechner/pi-tui";

// ANSI helpers — attribute-specific resets to allow nesting
export const dim = (s: string): string => `\x1b[2m${s}\x1b[22m`;
export const bold = (s: string): string => `\x1b[1m${s}\x1b[22m`;
export const green = (s: string): string => `\x1b[32m${s}\x1b[39m`;
export const yellow = (s: string): string => `\x1b[33m${s}\x1b[39m`;
export const cyan = (s: string): string => `\x1b[36m${s}\x1b[39m`;
export const magenta = (s: string): string => `\x1b[35m${s}\x1b[39m`;

/** Pad a line to fill the full terminal width */
export function padLine(line: string, width: number): string {
  return line + " ".repeat(Math.max(0, width - visibleWidth(line)));
}

/** Render content inside a bordered box row */
export function boxLine(content: string, boxWidth: number): string {
  const padding = Math.max(0, boxWidth - 2 - visibleWidth(content));
  return dim("│ ") + content + " ".repeat(padding) + dim(" │");
}

/** Box drawing borders */
export function boxTop(boxWidth: number): string {
  return dim("╭" + "─".repeat(boxWidth) + "╮");
}

export function boxMid(boxWidth: number): string {
  return dim("├" + "─".repeat(boxWidth) + "┤");
}

export function boxBottom(boxWidth: number): string {
  return dim("╰" + "─".repeat(boxWidth) + "╯");
}

/** Truncate text with ellipsis if it exceeds maxLen */
export function truncate(text: string, maxLen: number): string {
  return text.length > maxLen ? text.slice(0, maxLen - 3) + "..." : text;
}

/** Word-wrap text to fit within maxWidth */
export function wrapText(text: string, maxWidth: number): string[] {
  const wrapped: string[] = [];
  for (const paragraph of text.split("\n")) {
    if (paragraph.length <= maxWidth) {
      wrapped.push(paragraph);
      continue;
    }
    let remaining = paragraph;
    while (remaining.length > maxWidth) {
      let breakPoint = remaining.lastIndexOf(" ", maxWidth);
      if (breakPoint === -1) breakPoint = maxWidth;
      wrapped.push(remaining.slice(0, breakPoint));
      remaining = remaining.slice(breakPoint + 1);
    }
    if (remaining) wrapped.push(remaining);
  }
  return wrapped;
}

/** Check if input matches "move up" keys (↑, k, Ctrl-P) */
export function isNavUp(data: string): boolean {
  return (
    matchesKey(data, "up") || data === "k" || matchesKey(data, Key.ctrl("p"))
  );
}

/** Check if input matches "move down" keys (↓, j, Ctrl-N) */
export function isNavDown(data: string): boolean {
  return (
    matchesKey(data, "down") || data === "j" || matchesKey(data, Key.ctrl("n"))
  );
}

/** Check if input is confirm (Enter/Return) */
export function isConfirm(data: string): boolean {
  return matchesKey(data, "return") || matchesKey(data, "enter");
}

/** Check if input is cancel (Escape) */
export function isCancel(data: string): boolean {
  return matchesKey(data, "escape");
}
