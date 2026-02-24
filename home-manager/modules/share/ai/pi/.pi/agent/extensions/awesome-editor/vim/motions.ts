/**
 * Motion calculation utilities for vim mode.
 */

import type { CharMotion } from "./types.js";

const isWordChar = (c: string) => /\w/.test(c);

export function reverseCharMotion(motion: CharMotion): CharMotion {
  return ({ f: "F", F: "f", t: "T", T: "t" } as const)[motion];
}

/**
 * Find target column for a character motion (f/F/t/T).
 * Returns null if the target character is not found.
 */
export function findCharMotionTarget(
  line: string,
  col: number,
  motion: CharMotion,
  targetChar: string,
  isRepeat = false,
): number | null {
  const isForward  = motion === "f" || motion === "t";
  const isTill     = motion === "t" || motion === "T";
  const tillOffset = isTill && isRepeat ? 1 : 0;

  if (isForward) {
    const idx = line.indexOf(targetChar, col + 1 + tillOffset);
    return idx !== -1 ? (isTill ? idx - 1 : idx) : null;
  } else {
    const idx = line.lastIndexOf(targetChar, col - 1 - tillOffset);
    return idx !== -1 ? (isTill ? idx + 1 : idx) : null;
  }
}

/**
 * Calculate word motion target column (w/b/e).
 */
export function findWordMotionTarget(
  line: string,
  col: number,
  direction: "forward" | "backward",
  target: "start" | "end",
): number {
  if (direction === "forward") {
    if (target === "start") {
      // w: start of next word
      let i = col;
      while (i < line.length && isWordChar(line[i]!)) i++;
      while (i < line.length && !isWordChar(line[i]!)) i++;
      return i;
    } else {
      // e: end of current/next word
      let i = col;
      if (i < line.length - 1) i++;
      while (i < line.length && !isWordChar(line[i]!)) i++;
      while (i < line.length - 1 && isWordChar(line[i + 1]!)) i++;
      return i;
    }
  } else {
    // b: start of previous word
    let i = col;
    if (i > 0) i--;
    while (i > 0 && !isWordChar(line[i]!)) i--;
    while (i > 0 && isWordChar(line[i - 1]!)) i--;
    return i;
  }
}
