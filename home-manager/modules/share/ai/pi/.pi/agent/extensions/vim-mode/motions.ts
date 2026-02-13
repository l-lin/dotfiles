/**
 * Motion calculation utilities for vim-mode
 */

import type { CharMotion } from "./types.js";

// Word character regex (alphanumeric + underscore)
export const isWordChar = (c: string) => /\w/.test(c);

/**
 * Reverse a character motion direction (f ↔ F, t ↔ T).
 */
export function reverseCharMotion(motion: CharMotion): CharMotion {
  const reverseMap: Record<CharMotion, CharMotion> = {
    f: "F",
    F: "f",
    t: "T",
    T: "t",
  };
  return reverseMap[motion];
}

/**
 * Find target column for a character motion (f/F/t/T).
 * @returns target column or null if not found
 */
export function findCharMotionTarget(
  line: string,
  col: number,
  motion: CharMotion,
  targetChar: string,
  isRepeat: boolean = false,
): number | null {
  const isForward = motion === "f" || motion === "t";
  const isTill = motion === "t" || motion === "T";

  // For till repeats (;/,), we need extra offset to skip past the character we stopped before/after
  const tillRepeatOffset = isTill && isRepeat ? 1 : 0;

  if (isForward) {
    const searchStart = col + 1 + tillRepeatOffset;
    const idx = line.indexOf(targetChar, searchStart);
    if (idx !== -1) {
      return isTill ? idx - 1 : idx;
    }
  } else {
    const searchStart = col - 1 - tillRepeatOffset;
    const idx = line.lastIndexOf(targetChar, searchStart);
    if (idx !== -1) {
      return isTill ? idx + 1 : idx;
    }
  }
  return null;
}

/**
 * Calculate word motion target column.
 */
export function findWordMotionTarget(
  line: string,
  col: number,
  direction: "forward" | "backward",
  target: "start" | "end",
): number {
  if (direction === "forward") {
    if (target === "start") {
      // w: move to start of next word
      let i = col;
      while (i < line.length && isWordChar(line[i]!)) i++;
      while (i < line.length && !isWordChar(line[i]!)) i++;
      return i;
    } else {
      // e: move to end of current/next word
      let i = col;
      if (i < line.length - 1) i++;
      while (i < line.length && !isWordChar(line[i]!)) i++;
      while (i < line.length - 1 && isWordChar(line[i + 1]!)) i++;
      return i;
    }
  } else {
    // b: move to start of previous word
    let i = col;
    if (i > 0) i--;
    while (i > 0 && !isWordChar(line[i]!)) i--;
    while (i > 0 && isWordChar(line[i - 1]!)) i--;
    return i;
  }
}
