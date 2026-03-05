import type { RGB } from "./types.js";
import { EMPTY_CELL_BG } from "./constants.js";

export function clamp01(x: number): number {
  return Math.max(0, Math.min(1, x));
}

export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

export function mixRgb(a: RGB, b: RGB, t: number): RGB {
  return {
    r: Math.round(lerp(a.r, b.r, t)),
    g: Math.round(lerp(a.g, b.g, t)),
    b: Math.round(lerp(a.b, b.b, t)),
  };
}

export function weightedMix(
  colors: Array<{ color: RGB; weight: number }>,
): RGB {
  let total = 0;
  let r = 0;
  let g = 0;
  let b = 0;
  for (const c of colors) {
    if (!Number.isFinite(c.weight) || c.weight <= 0) continue;
    total += c.weight;
    r += c.color.r * c.weight;
    g += c.color.g * c.weight;
    b += c.color.b * c.weight;
  }
  if (total <= 0) return EMPTY_CELL_BG;
  return {
    r: Math.round(r / total),
    g: Math.round(g / total),
    b: Math.round(b / total),
  };
}

export function ansiBg(rgb: RGB, text: string): string {
  return `\x1b[48;2;${rgb.r};${rgb.g};${rgb.b}m${text}\x1b[0m`;
}

export function dim(text: string): string {
  return `\x1b[2m${text}\x1b[0m`;
}

export function bold(text: string): string {
  return `\x1b[1m${text}\x1b[0m`;
}

export function formatCount(n: number): string {
  if (!Number.isFinite(n) || n === 0) return "0";
  if (n >= 1_000_000_000) return `${(n / 1_000_000_000).toFixed(1)}B`;
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 10_000) return `${(n / 1_000).toFixed(1)}K`;
  return n.toLocaleString("en-US");
}

export function formatUsd(cost: number): string {
  if (!Number.isFinite(cost)) return "$0.00";
  if (cost === 0) return "$0.00";
  if (cost >= 1) return `$${cost.toFixed(2)}`;
  if (cost >= 0.1) return `$${cost.toFixed(3)}`;
  return `$${cost.toFixed(4)}`;
}

export function padRight(s: string, n: number): string {
  const delta = n - s.length;
  return delta > 0 ? s + " ".repeat(delta) : s;
}

export function padLeft(s: string, n: number): string {
  const delta = n - s.length;
  return delta > 0 ? " ".repeat(delta) + s : s;
}
