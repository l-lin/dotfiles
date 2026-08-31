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
  selection: SelectionRange,
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
