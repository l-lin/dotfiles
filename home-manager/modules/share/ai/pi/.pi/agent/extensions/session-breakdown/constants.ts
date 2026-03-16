import os from "node:os";
import path from "node:path";
import type { RGB, DowKey, TodKey } from "./types.ts";

export const SESSION_ROOT = path.join(os.homedir(), ".pi", "agent", "sessions");
export const RANGE_DAYS = [7, 30, 90] as const;

// Dark-ish background and empty cell color (close to GitHub dark)
export const DEFAULT_BG: RGB = { r: 13, g: 17, b: 23 };
export const EMPTY_CELL_BG: RGB = { r: 22, g: 27, b: 34 };

// Light theme base/background and empty cell color (GitHub light-ish)
export const LIGHT_BG: RGB = { r: 255, g: 255, b: 255 };
export const LIGHT_EMPTY_CELL_BG: RGB = { r: 255, g: 255, b: 255 };

// Default palette (assigned to top models / cwds)
export const PALETTE: RGB[] = [
  { r: 64, g: 196, b: 99 }, // green
  { r: 47, g: 129, b: 247 }, // blue
  { r: 163, g: 113, b: 247 }, // purple
  { r: 255, g: 159, b: 10 }, // orange
  { r: 244, g: 67, b: 54 }, // red
];

export const DOW_NAMES: DowKey[] = [
  "Mon",
  "Tue",
  "Wed",
  "Thu",
  "Fri",
  "Sat",
  "Sun",
];

// Fixed palette for day-of-week: weekdays cool tones, weekend warm
export const DOW_PALETTE: RGB[] = [
  { r: 47, g: 129, b: 247 }, // Mon – blue
  { r: 64, g: 196, b: 99 }, // Tue – green
  { r: 163, g: 113, b: 247 }, // Wed – purple
  { r: 47, g: 175, b: 200 }, // Thu – teal
  { r: 100, g: 200, b: 150 }, // Fri – mint
  { r: 255, g: 159, b: 10 }, // Sat – orange
  { r: 244, g: 67, b: 54 }, // Sun – red
];

export const TOD_BUCKETS: {
  key: TodKey;
  label: string;
  from: number;
  to: number;
}[] = [
  { key: "after-midnight", label: "After midnight (0–5)", from: 0, to: 5 },
  { key: "morning", label: "Morning (6–11)", from: 6, to: 11 },
  { key: "afternoon", label: "Afternoon (12–16)", from: 12, to: 16 },
  { key: "evening", label: "Evening (17–21)", from: 17, to: 21 },
  { key: "night", label: "Night (22–23)", from: 22, to: 23 },
];

// Fixed palette for time-of-day buckets
export const TOD_PALETTE: Map<TodKey, RGB> = new Map([
  ["after-midnight", { r: 100, g: 60, b: 180 }], // deep purple
  ["morning", { r: 255, g: 200, b: 50 }], // golden yellow
  ["afternoon", { r: 64, g: 196, b: 99 }], // green
  ["evening", { r: 47, g: 129, b: 247 }], // blue
  ["night", { r: 60, g: 40, b: 140 }], // dark indigo
]);
