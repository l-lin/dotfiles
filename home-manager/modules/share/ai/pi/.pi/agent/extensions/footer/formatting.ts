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

export function colorByThreshold(
  value: number,
  text: string,
  theme: Theme,
  thresholds: { high: number; medium: number },
): string {
  if (value > thresholds.high) return theme.fg("error", text);
  if (value > thresholds.medium) return theme.fg("warning", text);
  return theme.fg("dim", text);
}

export function colorContext(
  percent: number,
  text: string,
  theme: Theme,
): string {
  return colorByThreshold(percent, text, theme, { high: 60, medium: 40 });
}

export function colorCost(amount: number, text: string, theme: Theme): string {
  return colorByThreshold(amount, text, theme, { high: 5, medium: 3 });
}

export function colorThinking(
  level: ThinkingLevel,
  text: string,
  theme: Theme,
): string {
  if (level === "high" || level === "xhigh") return theme.fg("error", text);
  if (level === "medium") return theme.fg("warning", text);
  return theme.fg("dim", text);
}

export function formatCurrentDirectory(): string {
  let pwd = process.cwd();
  const home = process.env.HOME ?? process.env.USERPROFILE ?? "";

  if (home && pwd.startsWith(home)) {
    pwd = `~${pwd.slice(home.length)}`;
  }

  return pwd;
}
