import os from "node:os";

export type VisualMode = "character" | "line";

export interface CursorPosition {
  line: number;
  grapheme: number;
}

export interface Grapheme {
  text: string;
  start: number;
  end: number;
}

export interface SourceLine {
  text: string;
  start: number;
  graphemes: Grapheme[];
}

export interface SourceDocument {
  text: string;
  lines: SourceLine[];
}

export type SearchDirection = "forward" | "backward";

export interface SearchMatch {
  start: number;
  end: number;
}

export interface SelectionRange {
  start: number;
  end: number;
  text: string;
}

export interface Annotation extends SelectionRange {
  id: number;
  comment: string;
}

const graphemeSegmenter = new Intl.Segmenter(undefined, {
  granularity: "grapheme",
});

export function normalizePlatformLineEndings(text: string): string {
  const normalized = text.replace(/\r\n?|\n/g, "\n");
  return os.EOL === "\n" ? normalized : normalized.replaceAll("\n", os.EOL);
}

export function toInternalLineEndings(text: string): string {
  return text.replace(/\r\n?|\n/g, "\n");
}

export function fromAssistantContent(content: unknown): string | null {
  if (!Array.isArray(content)) return null;

  let hasText = false;
  const parts: string[] = [];

  for (const block of content) {
    if (!isRecord(block) || typeof block.type !== "string") continue;
    if (isThinkingBlock(block.type)) continue;

    if (block.type === "text" && typeof block.text === "string") {
      hasText ||= block.text.trim().length > 0;
      parts.push(block.text);
      continue;
    }

    parts.push(`[${formatBlockType(block.type)}]`);
  }

  if (!hasText) return null;

  return normalizePlatformLineEndings(parts.join("\n"));
}

function formatBlockType(type: string): string {
  return type
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/[-_]+/g, " ")
    .toLowerCase();
}

function isThinkingBlock(type: string): boolean {
  const normalizedType = formatBlockType(type).replaceAll(" ", "");
  return normalizedType === "thinking" || normalizedType === "redactedthinking";
}

export function createSourceDocument(text: string): SourceDocument {
  const internalText = toInternalLineEndings(text);
  const lines: SourceLine[] = [];
  let start = 0;

  for (const line of internalText.split("\n")) {
    const graphemes = [...graphemeSegmenter.segment(line)].map((segment) => ({
      text: segment.segment,
      start: segment.index,
      end: segment.index + segment.segment.length,
    }));

    lines.push({ text: line, start, graphemes });
    start += line.length + 1;
  }

  return { text: internalText, lines };
}

export function decodeSearchQuery(query: string): string {
  let decoded = "";
  for (let index = 0; index < query.length; index++) {
    const character = query[index]!;
    if (character !== "\\") {
      decoded += character;
      continue;
    }

    const next = query[index + 1];
    if (next === "n") {
      decoded += "\n";
      index++;
    } else if (next === "\\") {
      decoded += "\\";
      index++;
    } else {
      decoded += character;
    }
  }
  return decoded;
}

export function findLiteralSearchMatches(
  text: string,
  query: string,
): SearchMatch[] {
  if (query.length === 0) return [];

  const foldedText = foldAsciiCase(text, query);
  const foldedQuery = foldAsciiCase(query, query);
  const starts = [...graphemeSegmenter.segment(text)].map(
    (segment) => segment.index,
  );
  const matches: SearchMatch[] = [];
  let startIndex = 0;

  while (startIndex < starts.length) {
    const start = starts[startIndex]!;
    if (!foldedText.startsWith(foldedQuery, start)) {
      startIndex++;
      continue;
    }

    const end = start + query.length;
    matches.push({ start, end });
    // Vim's literal search advances past a match before looking for the next
    // one, so a match cannot overlap the previous match.
    while (startIndex < starts.length && starts[startIndex]! < end) {
      startIndex++;
    }
  }

  return matches;
}

export function findKeywordAtCursor(
  document: SourceDocument,
  cursor: CursorPosition,
): string | null {
  const line = document.lines[cursor.line];
  if (!line) return null;

  const grapheme = line.graphemes[cursor.grapheme];
  if (!grapheme || !isKeywordGrapheme(grapheme.text)) return null;

  let start = cursor.grapheme;
  while (start > 0 && isKeywordGrapheme(line.graphemes[start - 1]!.text)) {
    start--;
  }

  let end = cursor.grapheme + 1;
  while (
    end < line.graphemes.length &&
    isKeywordGrapheme(line.graphemes[end]!.text)
  ) {
    end++;
  }

  return line.graphemes
    .slice(start, end)
    .map((grapheme) => grapheme.text)
    .join("");
}

export function findKeywordSearchMatches(
  document: SourceDocument,
  keyword: string,
): SearchMatch[] {
  return findLiteralSearchMatches(document.text, keyword).filter(
    (match) =>
      !isKeywordCodeUnit(document.text[match.start - 1]) &&
      !isKeywordCodeUnit(document.text[match.end]),
  );
}

export function cursorOffset(
  document: SourceDocument,
  cursor: CursorPosition,
): number {
  const line = document.lines[cursor.line];
  if (!line) return 0;
  const grapheme = line.graphemes[cursor.grapheme];
  return line.start + (grapheme?.start ?? 0);
}

export function cursorPositionAtSearchMatch(
  document: SourceDocument,
  match: SearchMatch,
): CursorPosition {
  for (let lineIndex = 0; lineIndex < document.lines.length; lineIndex++) {
    const line = document.lines[lineIndex]!;
    for (
      let graphemeIndex = 0;
      graphemeIndex < line.graphemes.length;
      graphemeIndex++
    ) {
      const grapheme = line.graphemes[graphemeIndex]!;
      const start = line.start + grapheme.start;
      const end = line.start + grapheme.end;
      if (start < match.end && end > match.start) {
        return { line: lineIndex, grapheme: graphemeIndex };
      }
    }
  }

  return cursorPositionAtOffset(document, match.start);
}

export function searchMatchContainsCursor(
  document: SourceDocument,
  match: SearchMatch,
  cursor: CursorPosition,
): boolean {
  const offset = cursorOffset(document, cursor);
  return offset >= match.start && offset < match.end;
}

function cursorPositionAtOffset(
  document: SourceDocument,
  offset: number,
): CursorPosition {
  const boundedOffset = Math.max(0, Math.min(offset, document.text.length));
  for (let lineIndex = 0; lineIndex < document.lines.length; lineIndex++) {
    const line = document.lines[lineIndex]!;
    const lineEnd = line.start + line.text.length;
    if (boundedOffset < lineEnd) {
      const graphemeIndex = line.graphemes.findIndex(
        (grapheme) => line.start + grapheme.end > boundedOffset,
      );
      return {
        line: lineIndex,
        grapheme:
          graphemeIndex === -1
            ? Math.max(0, line.graphemes.length - 1)
            : graphemeIndex,
      };
    }
    if (boundedOffset === lineEnd && lineIndex < document.lines.length - 1) {
      return { line: lineIndex + 1, grapheme: 0 };
    }
  }

  const lastLine = document.lines.length - 1;
  return {
    line: Math.max(0, lastLine),
    grapheme: Math.max(
      0,
      (document.lines[lastLine]?.graphemes.length ?? 1) - 1,
    ),
  };
}

function foldAsciiCase(text: string, query: string): string {
  return /[A-Z]/.test(query)
    ? text
    : text.replace(/[A-Z]/g, (character) => character.toLowerCase());
}

function isKeywordGrapheme(text: string): boolean {
  return text.length === 1 && isKeywordCodeUnit(text);
}

function isKeywordCodeUnit(character: string | undefined): boolean {
  return character !== undefined && /^[A-Za-z0-9_]$/.test(character);
}

export function getSelectionRange(
  document: SourceDocument,
  anchor: CursorPosition,
  cursor: CursorPosition,
  mode: VisualMode,
): SelectionRange | null {
  if (document.lines.length === 0) return null;

  if (mode === "line") {
    const firstLine = Math.min(anchor.line, cursor.line);
    const lastLine = Math.max(anchor.line, cursor.line);
    const start = document.lines[firstLine]!.start;
    const last = document.lines[lastLine]!;
    const end =
      last.start +
      last.text.length +
      (lastLine < document.lines.length - 1 ? 1 : 0);
    return { start, end, text: document.text.slice(start, end) };
  }

  const anchorLine = document.lines[anchor.line]!;
  const cursorLine = document.lines[cursor.line]!;
  if (anchorLine.graphemes.length === 0 || cursorLine.graphemes.length === 0) {
    return null;
  }

  const anchorGrapheme = anchorLine.graphemes[anchor.grapheme]!;
  const cursorGrapheme = cursorLine.graphemes[cursor.grapheme]!;
  const anchorStart = anchorLine.start + anchorGrapheme.start;
  const cursorStart = cursorLine.start + cursorGrapheme.start;
  const anchorEnd = anchorLine.start + anchorGrapheme.end;
  const cursorEnd = cursorLine.start + cursorGrapheme.end;
  const start = Math.min(anchorStart, cursorStart);
  const end = Math.max(anchorEnd, cursorEnd);

  return { start, end, text: document.text.slice(start, end) };
}

export function selectionContainsOffset(
  selection: Pick<SelectionRange, "start" | "end">,
  start: number,
  end: number,
): boolean {
  return start < selection.end && end > selection.start;
}

export function annotationLines(
  document: SourceDocument,
  annotation: Annotation,
): { start: number; end: number } {
  const start = findLineAtOffset(document, annotation.start);
  const end = findLineAtOffset(
    document,
    Math.max(annotation.start, annotation.end - 1),
  );
  return { start, end };
}

export function findLineAtOffset(
  document: SourceDocument,
  offset: number,
): number {
  const boundedOffset = Math.max(0, Math.min(offset, document.text.length));
  for (let index = document.lines.length - 1; index >= 0; index--) {
    if (document.lines[index]!.start <= boundedOffset) return index;
  }
  return 0;
}

export function formatAnnotatedText(
  annotations: readonly Annotation[],
  lineSeparator = os.EOL,
): string {
  const blocks = annotations.map((annotation) => {
    const quoted = quoteSelectedText(annotation.text, lineSeparator);
    const separator = quoted.endsWith(lineSeparator)
      ? lineSeparator
      : lineSeparator + lineSeparator;
    return `${quoted}${separator}${annotation.comment}`;
  });
  return blocks.join(`${lineSeparator}${lineSeparator}`);
}

function quoteSelectedText(text: string, lineSeparator: string): string {
  const normalized = toInternalLineEndings(text);
  const lines = normalized.split("\n");
  const endsWithNewline = lines.at(-1) === "";
  if (endsWithNewline) lines.pop();

  const quoted = lines.map((line) => `> ${line}`).join(lineSeparator);
  return endsWithNewline ? `${quoted}${lineSeparator}` : quoted;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
