import type { Theme } from "@mariozechner/pi-coding-agent";
import { keyHint } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import type { FetchDetails } from "./types.js";

const PREVIEW_MAX_CHARS = 500;

export function renderCall(args: Record<string, unknown>, theme: Theme): Text {
  const url = (args.url as string) || "(no url)";
  const mode = (args.mode as string) || "readable";

  const text =
    theme.fg("toolTitle", theme.bold("Web Fetch ")) +
    theme.fg("accent", url) +
    theme.fg("dim", ` [${mode}]`);

  return new Text(text, 0, 0);
}

export function renderResult(
  result: { content: { type: string; text?: string }[]; details?: unknown },
  { expanded, isPartial }: { expanded: boolean; isPartial: boolean },
  theme: Theme,
): Text {
  if (isPartial) {
    return new Text(theme.fg("warning", " ⟳ Fetching…"), 0, 0);
  }

  const details = result.details as FetchDetails | undefined;

  if (details?.error) {
    return new Text(theme.fg("error", ` ✗ ${details.error}`), 0, 0);
  }

  if (!details) {
    return new Text(theme.fg("success", " ✓ Fetched"), 0, 0);
  }

  if (!expanded) {
    const truncNote = details.truncated ? " (truncated)" : "";
    const hint = keyHint("expandTools", "to expand");
    const text =
      theme.fg("success", "✓ ") +
      theme.fg("text", `${details.returnedLength.toLocaleString()} chars`) +
      theme.fg("muted", `${truncNote} • HTTP ${details.status}`) +
      theme.fg("dim", ` (${hint})`);
    return new Text(text, 0, 0);
  }

  function row(label: string, value: string): string {
    return (
      theme.fg("dim", `  ${label.padEnd(10)}`) + theme.fg("text", value) + "\n"
    );
  }

  let text = theme.fg("success", "✓ Fetched\n");
  text += row("URL:", details.url);
  text += row("Mode:", details.mode);
  text += row("Status:", String(details.status));
  text += row("Type:", details.contentType || "unknown");
  text +=
    theme.fg("dim", `  ${"Size:".padEnd(10)}`) +
    theme.fg("text", `${details.returnedLength.toLocaleString()} chars`) +
    theme.fg("dim", ` (raw HTML: ${details.originalLength.toLocaleString()})`) +
    "\n";

  if (details.truncated) {
    text += theme.fg("warning", "  ⚠ Output was truncated\n");
  }

  const firstContent = result.content[0];
  const preview =
    firstContent?.type === "text"
      ? (firstContent.text?.slice(0, PREVIEW_MAX_CHARS) ?? "")
      : "";

  if (preview) {
    text +=
      "\n" + theme.fg("dim", "── preview ──\n") + theme.fg("muted", preview);
    if (preview.length === PREVIEW_MAX_CHARS) text += theme.fg("dim", "\n…");
  }

  return new Text(text, 0, 0);
}
