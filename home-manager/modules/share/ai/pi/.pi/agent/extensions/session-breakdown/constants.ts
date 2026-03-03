import os from "node:os";
import path from "node:path";
import type { RGB } from "./types.ts";

export const SESSION_ROOT = path.join(os.homedir(), ".pi", "agent", "sessions");
export const RANGE_DAYS = [7, 30, 90] as const;

// Dark-ish background and empty cell color (close to GitHub dark)
export const DEFAULT_BG: RGB = { r: 13, g: 17, b: 23 };
export const EMPTY_CELL_BG: RGB = { r: 22, g: 27, b: 34 };

// Light theme base/background and empty cell color (GitHub light-ish)
export const LIGHT_BG: RGB = { r: 255, g: 255, b: 255 };
export const LIGHT_EMPTY_CELL_BG: RGB = { r: 255, g: 255, b: 255 };

// Default palette (assigned to top models)
export const PALETTE: RGB[] = [
  { r: 64, g: 196, b: 99 }, // green
  { r: 47, g: 129, b: 247 }, // blue
  { r: 163, g: 113, b: 247 }, // purple
  { r: 255, g: 159, b: 10 }, // orange
  { r: 244, g: 67, b: 54 }, // red
];
