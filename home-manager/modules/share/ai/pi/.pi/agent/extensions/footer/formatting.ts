/**
 * Formatting and color utilities
 */

import type { Theme } from "@mariozechner/pi-coding-agent";
import type { ThinkingLevel } from "./constants.js";

export function formatTokens(count: number): string {
  if (count < 1_000) return count.toString();
  if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

export function colorByPercent(
  percent: number,
  text: string,
  theme: Theme,
): string {
  if (percent > 60) return theme.fg("error", text);
  if (percent > 40) return theme.fg("warning", text);
  return theme.fg("dim", text);
}

export function colorByCost(
  amount: number,
  text: string,
  theme: Theme,
): string {
  if (amount > 5) return theme.fg("error", text);
  if (amount > 3) return theme.fg("warning", text);
  return theme.fg("dim", text);
}

export function colorByThinkingLevel(
  level: ThinkingLevel,
  text: string,
  theme: Theme,
): string {
  if (level === "high" || level === "xhigh") return theme.fg("error", text);
  if (level === "medium") return theme.fg("warning", text);
  return theme.fg("dim", text);
}

export function formatCurrentDirectory(maxLength: number = 40): string {
  let pwd = process.cwd();
  const home = process.env.HOME ?? process.env.USERPROFILE ?? "";

  if (home && pwd.startsWith(home)) {
    pwd = `~${pwd.slice(home.length)}`;
  }

  if (pwd.length <= maxLength) {
    return pwd;
  }

  const parts = pwd.split("/");
  const first = parts[0] || "/";
  const remaining: string[] = [];

  for (let i = parts.length - 1; i > 0; i--) {
    const part = parts[i];
    const candidate =
      remaining.length === 0 ? part : `${part}/${remaining.join("/")}`;

    const withEllipsis = `${first}/…/${candidate}`;
    if (withEllipsis.length > maxLength) {
      break;
    }

    remaining.unshift(part);
  }

  if (remaining.length === parts.length - 1) {
    return pwd;
  }

  return remaining.length > 0
    ? `${first}/…/${remaining.join("/")}`
    : `${first}/…`;
}
