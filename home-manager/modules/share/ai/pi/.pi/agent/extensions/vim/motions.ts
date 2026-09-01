import type {
  CharMotion,
  MotionPosition,
  WordDirection,
  WordTarget,
} from "./types.js";

export type MotionLine = readonly string[];
export type MotionDocument = readonly MotionLine[];

export function reverseCharMotion(motion: CharMotion): CharMotion {
  return ({ f: "F", F: "f", t: "T", T: "t" } as const)[motion];
}

/**
 * Find a target column for a character motion (f/F/t/T).
 *
 * A repeated till motion starts two units away because its cursor is already
 * sitting immediately before or after the previous target.
 */
export function findCharMotionTarget(
  line: MotionLine,
  column: number,
  motion: CharMotion,
  targetChar: string,
  isRepeat = false,
): number | null {
  const isForward = motion === "f" || motion === "t";
  const isTill = motion === "t" || motion === "T";
  const offset = isRepeat && isTill ? 2 : 1;
  const start = column + (isForward ? offset : -offset);

  if (isForward) {
    for (let index = Math.max(0, start); index < line.length; index++) {
      if (line[index] === targetChar) {
        return isTill ? index - 1 : index;
      }
    }
    return null;
  }

  for (let index = Math.min(line.length - 1, start); index >= 0; index--) {
    if (line[index] === targetChar) {
      return isTill ? index + 1 : index;
    }
  }
  return null;
}

/** Return true for one printable ASCII code unit, including a space. */
export function isPrintableAscii(data: string): boolean {
  return (
    data.length === 1 && data.charCodeAt(0) >= 32 && data.charCodeAt(0) <= 126
  );
}

/** Return the first non-whitespace unit, or zero for a blank line. */
export function firstNonBlankColumn(line: MotionLine): number {
  const column = line.findIndex((unit) => !isWhitespace(unit));
  return column === -1 ? 0 : column;
}

/**
 * Calculate a Vim word motion over logical lines.
 *
 * ASCII keyword runs and non-whitespace punctuation runs are separate word
 * units. Empty lines are positions for w/b, while e skips them like Vim.
 */
export function findWordMotionTarget(
  lines: MotionDocument,
  position: MotionPosition,
  direction: WordDirection,
  target: WordTarget,
): MotionPosition {
  if (lines.length === 0) return { line: 0, column: 0 };

  const currentLineIndex = clamp(position.line, 0, lines.length - 1);
  const currentLine = lines[currentLineIndex] ?? [];
  const currentColumn = clamp(
    position.column,
    0,
    Math.max(0, currentLine.length - 1),
  );

  if (direction === "forward" && target === "start") {
    return findForwardWordStart(lines, currentLineIndex, currentColumn);
  }
  if (direction === "backward" && target === "start") {
    return findBackwardWordStart(lines, currentLineIndex, currentColumn);
  }
  return findForwardWordEnd(lines, currentLineIndex, currentColumn);
}

function findForwardWordStart(
  lines: MotionDocument,
  lineIndex: number,
  column: number,
): MotionPosition {
  const line = lines[lineIndex] ?? [];

  if (line.length > 0) {
    const currentKind = wordKind(line[column]!);
    let nextColumn = column + 1;

    if (currentKind !== "whitespace") {
      while (
        nextColumn < line.length &&
        wordKind(line[nextColumn]!) === currentKind
      ) {
        nextColumn++;
      }
    } else {
      while (
        nextColumn < line.length &&
        wordKind(line[nextColumn]!) === "whitespace"
      ) {
        nextColumn++;
      }
    }

    const nextWord = firstNonWhitespaceAtOrAfter(line, nextColumn);
    if (nextWord !== null) return { line: lineIndex, column: nextWord };
  }

  for (
    let nextLineIndex = lineIndex + 1;
    nextLineIndex < lines.length;
    nextLineIndex++
  ) {
    const nextLine = lines[nextLineIndex] ?? [];
    if (nextLine.length === 0) return { line: nextLineIndex, column: 0 };
    const nextWord = firstNonWhitespaceAtOrAfter(nextLine, 0);
    if (nextWord !== null) {
      return { line: nextLineIndex, column: nextWord };
    }
  }

  return lastPosition(lines);
}

function findBackwardWordStart(
  lines: MotionDocument,
  lineIndex: number,
  column: number,
): MotionPosition {
  const line = lines[lineIndex] ?? [];

  if (line.length > 0) {
    let previousColumn = column - 1;
    if (wordKind(line[column]!) !== "whitespace") {
      previousColumn = column - 1;
      if (
        previousColumn >= 0 &&
        wordKind(line[previousColumn]!) === wordKind(line[column]!)
      ) {
        return {
          line: lineIndex,
          column: startOfWord(line, previousColumn),
        };
      }
    }

    while (
      previousColumn >= 0 &&
      wordKind(line[previousColumn]!) === "whitespace"
    ) {
      previousColumn--;
    }
    if (previousColumn >= 0) {
      return {
        line: lineIndex,
        column: startOfWord(line, previousColumn),
      };
    }
  }

  for (
    let previousLineIndex = lineIndex - 1;
    previousLineIndex >= 0;
    previousLineIndex--
  ) {
    const previousLine = lines[previousLineIndex] ?? [];
    if (previousLine.length === 0) {
      return { line: previousLineIndex, column: 0 };
    }
    let previousColumn = previousLine.length - 1;
    while (
      previousColumn >= 0 &&
      wordKind(previousLine[previousColumn]!) === "whitespace"
    ) {
      previousColumn--;
    }
    if (previousColumn >= 0) {
      return {
        line: previousLineIndex,
        column: startOfWord(previousLine, previousColumn),
      };
    }
  }

  return firstPosition();
}

function findForwardWordEnd(
  lines: MotionDocument,
  lineIndex: number,
  column: number,
): MotionPosition {
  const line = lines[lineIndex] ?? [];

  if (line.length > 0) {
    const currentKind = wordKind(line[column]!);
    if (currentKind !== "whitespace") {
      let end = column;
      while (
        end + 1 < line.length &&
        wordKind(line[end + 1]!) === currentKind
      ) {
        end++;
      }
      if (end > column) return { line: lineIndex, column: end };
      const nextWord = firstNonWhitespaceAtOrAfter(line, end + 1);
      if (nextWord !== null) return endOfWord(line, nextWord, lineIndex);
    } else {
      const nextWord = firstNonWhitespaceAtOrAfter(line, column + 1);
      if (nextWord !== null) return endOfWord(line, nextWord, lineIndex);
    }
  }

  for (
    let nextLineIndex = lineIndex + 1;
    nextLineIndex < lines.length;
    nextLineIndex++
  ) {
    const nextLine = lines[nextLineIndex] ?? [];
    const nextWord = firstNonWhitespaceAtOrAfter(nextLine, 0);
    if (nextWord !== null) return endOfWord(nextLine, nextWord, nextLineIndex);
  }

  return lastPosition(lines);
}

function firstNonWhitespaceAtOrAfter(
  line: MotionLine,
  start: number,
): number | null {
  for (let column = Math.max(0, start); column < line.length; column++) {
    if (wordKind(line[column]!) !== "whitespace") return column;
  }
  return null;
}

function endOfWord(
  line: MotionLine,
  start: number,
  lineIndex: number,
): MotionPosition {
  const kind = wordKind(line[start]!);
  let end = start;
  while (end + 1 < line.length && wordKind(line[end + 1]!) === kind) end++;
  return { line: lineIndex, column: end };
}

function startOfWord(line: MotionLine, column: number): number {
  const kind = wordKind(line[column]!);
  let start = column;
  while (start > 0 && wordKind(line[start - 1]!) === kind) start--;
  return start;
}

function wordKind(unit: string): "keyword" | "other" | "whitespace" {
  if (isWhitespace(unit)) return "whitespace";
  return /^[A-Za-z0-9_]$/.test(unit) ? "keyword" : "other";
}

function isWhitespace(unit: string): boolean {
  return /^\s+$/u.test(unit);
}

function firstPosition(): MotionPosition {
  return { line: 0, column: 0 };
}

function lastPosition(lines: MotionDocument): MotionPosition {
  const line = lines.length - 1;
  return { line, column: Math.max(0, (lines[line] ?? []).length - 1) };
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}
