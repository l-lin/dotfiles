import type { Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

export function buildSessionNameLine(
  width: number,
  theme: Theme,
  sessionName: string | undefined,
): string | null {
  const name = sessionName?.replace(/[\r\n\t]/g, " ").trim();
  if (!name) return null;

  const label = truncateToWidth(`  ${name}`, Math.max(0, width - 1), "…");
  return theme.bg(
    "userMessageBg",
    theme.fg("text", width > 0 ? `${label} ` : ""),
  );
}
