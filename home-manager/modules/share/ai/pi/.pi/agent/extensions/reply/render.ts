import { getMarkdownTheme, type Theme } from "@earendil-works/pi-coding-agent";
import {
  CURSOR_MARKER,
  Markdown,
  stripTerminalSequences,
  visibleWidth,
} from "@earendil-works/pi-tui";
import {
  annotationLines,
  createSourceDocument,
  selectionContainsOffset,
  type Annotation,
  type CursorPosition,
  type SearchMatch,
  type SelectionRange,
  type SourceDocument,
  type SourceLine,
} from "./model.js";

export type DisplayRow = SourceDisplayRow | CommentDisplayRow;

type SourceDisplayRow = {
  kind: "source";
  line: number;
  startGrapheme: number;
  endGrapheme: number;
  content: string;
};

type CommentDisplayRow = {
  kind: "comment";
  annotationId: number;
  content: string;
};

export interface ReplyRenderState {
  cursor: CursorPosition;
  activeSelection: SelectionRange | null;
  searchMatches: readonly SearchMatch[];
  currentSearchMatch: SearchMatch | null;
  yankHighlight?: SelectionRange | null;
  hasCommentInput: boolean;
  focused: boolean;
}

const ANSI_REVERSE_ON = "\x1b[7m";
const ANSI_REVERSE_OFF = "\x1b[27m";
const TAB_SIZE = 4;
const ANSI_SEQUENCE_RE =
  /\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)|P[^\x1b]*(?:\x1b\\)|_[^\x1b]*(?:\x1b\\))/gu;
const renderedGraphemeSegmenter = new Intl.Segmenter(undefined, {
  granularity: "grapheme",
});

export class ReplyRenderer {
  constructor(
    private readonly theme: Theme,
    private readonly document: SourceDocument,
    private readonly annotations: readonly Annotation[],
    private readonly state: ReplyRenderState,
    private readonly renderedLines?: readonly string[],
  ) {}

  buildDisplayRows(width: number): DisplayRow[] {
    const rows: DisplayRow[] = [];
    for (
      let lineIndex = 0;
      lineIndex < this.document.lines.length;
      lineIndex++
    ) {
      const line = this.document.lines[lineIndex]!;
      const renderedLine = this.renderedLines?.[lineIndex];
      const sourceRows =
        renderedLine === undefined
          ? this.renderSourceLine(line, lineIndex, width)
          : [
              {
                start: 0,
                end: line.graphemes.length,
                content: this.renderRenderedLine(renderedLine, line, lineIndex),
              },
            ];
      for (const row of sourceRows) {
        rows.push({
          kind: "source",
          line: lineIndex,
          startGrapheme: row.start,
          endGrapheme: row.end,
          content: row.content,
        });
      }

      const comments = this.annotations.filter(
        (annotation) =>
          annotationLines(this.document, annotation).end === lineIndex,
      );
      for (const annotation of comments)
        rows.push(...this.renderComment(annotation, width));
    }
    return rows;
  }

  findCursorRow(rows: DisplayRow[]): number {
    return rows.findIndex(
      (row) =>
        row.kind === "source" &&
        row.line === this.state.cursor.line &&
        (row.startGrapheme === row.endGrapheme ||
          (this.state.cursor.grapheme >= row.startGrapheme &&
            this.state.cursor.grapheme < row.endGrapheme)),
    );
  }

  private renderSourceLine(
    line: SourceLine,
    lineIndex: number,
    width: number,
  ): Array<{ start: number; end: number; content: string }> {
    const textWidth = Math.max(1, width);
    const chunks: Array<{ start: number; end: number }> = [];
    let chunkStart = 0;
    let chunkCellWidth = 0;

    for (let index = 0; index < line.graphemes.length; index++) {
      const grapheme = line.graphemes[index]!;
      const nextWidth = cellWidth(grapheme.text, chunkCellWidth);
      if (chunkCellWidth > 0 && chunkCellWidth + nextWidth > textWidth) {
        chunks.push({ start: chunkStart, end: index });
        chunkStart = index;
        chunkCellWidth = 0;
      }
      chunkCellWidth += cellWidth(grapheme.text, chunkCellWidth);
    }

    if (line.graphemes.length > 0) {
      chunks.push({ start: chunkStart, end: line.graphemes.length });
    } else {
      chunks.push({ start: 0, end: 0 });
    }

    return chunks.map((chunk) => {
      return {
        start: chunk.start,
        end: chunk.end,
        content: this.renderChunk(
          line,
          lineIndex,
          chunk.start,
          chunk.end,
          width,
        ),
      };
    });
  }

  private renderRenderedLine(
    renderedLine: string,
    line: SourceLine,
    lineIndex: number,
  ): string {
    let content = "";
    let trailing = "";
    let graphemeIndex = 0;

    const appendVisibleText = (text: string): void => {
      for (const segment of renderedGraphemeSegmenter.segment(text)) {
        const target =
          graphemeIndex < line.graphemes.length ? "content" : "trailing";
        if (target === "content") {
          content += this.styleGrapheme(
            line,
            lineIndex,
            graphemeIndex,
            segment.segment,
          );
        } else {
          trailing += segment.segment;
        }
        graphemeIndex++;
      }
    };

    let lastIndex = 0;
    for (const match of renderedLine.matchAll(ANSI_SEQUENCE_RE)) {
      appendVisibleText(renderedLine.slice(lastIndex, match.index));
      const target =
        graphemeIndex < line.graphemes.length ? "content" : "trailing";
      if (target === "content") content += match[0];
      else trailing += match[0];
      lastIndex = match.index + match[0].length;
    }
    appendVisibleText(renderedLine.slice(lastIndex));

    if (
      !this.state.hasCommentInput &&
      this.state.cursor.line === lineIndex &&
      this.state.cursor.grapheme >= line.graphemes.length
    ) {
      content += `${this.cursorMarker()}${ANSI_REVERSE_ON} ${ANSI_REVERSE_OFF}`;
      trailing = removeFirstVisibleGrapheme(trailing);
    }

    return content + trailing;
  }

  private styleGrapheme(
    line: SourceLine,
    lineIndex: number,
    index: number,
    displayText: string,
  ): string {
    const grapheme = line.graphemes[index]!;
    const globalStart = line.start + grapheme.start;
    const globalEnd = line.start + grapheme.end;
    const annotation = this.annotations.find((candidate) =>
      selectionContainsOffset(candidate, globalStart, globalEnd),
    );
    const selected = this.state.activeSelection
      ? selectionContainsOffset(
          this.state.activeSelection,
          globalStart,
          globalEnd,
        )
      : false;
    const isCursor =
      !this.state.hasCommentInput &&
      this.state.cursor.line === lineIndex &&
      this.state.cursor.grapheme === index;
    const searchMatch = this.state.searchMatches.find((candidate) =>
      selectionContainsOffset(candidate, globalStart, globalEnd),
    );
    const isCurrentSearchMatch =
      searchMatch !== undefined &&
      this.state.currentSearchMatch !== null &&
      searchMatch.start === this.state.currentSearchMatch.start &&
      searchMatch.end === this.state.currentSearchMatch.end;
    const yankHighlighted = this.isYankHighlighted(line, index);

    let styled = displayText;
    if (annotation) styled = this.theme.underline(styled);
    if (yankHighlighted) {
      styled = this.theme.bg("toolSuccessBg", styled);
    } else if (selected) {
      styled = this.theme.bg("selectedBg", styled);
    } else if (searchMatch) {
      styled = this.theme.bg("searchMatchBg", styled);
      if (isCurrentSearchMatch) {
        styled = this.theme.fg("searchMatchText", styled);
      }
    }
    if (isCursor) {
      const cursorContent = styled || " ";
      styled = `${this.cursorMarker()}${ANSI_REVERSE_ON}${cursorContent}${ANSI_REVERSE_OFF}`;
    }
    return styled;
  }

  private renderChunk(
    line: SourceLine,
    lineIndex: number,
    start: number,
    end: number,
    width: number,
  ): string {
    let output = "";
    let cellColumn = 0;

    for (let index = start; index < end; index++) {
      const grapheme = line.graphemes[index]!;
      const displayText =
        grapheme.text === "\t"
          ? " ".repeat(cellWidth(grapheme.text, cellColumn))
          : grapheme.text;
      output += this.styleGrapheme(line, lineIndex, index, displayText);
      cellColumn += cellWidth(grapheme.text, cellColumn);
    }

    if (
      !this.state.hasCommentInput &&
      this.state.cursor.line === lineIndex &&
      this.state.cursor.grapheme >= end &&
      end === line.graphemes.length
    ) {
      output += `${this.cursorMarker()}${ANSI_REVERSE_ON} ${ANSI_REVERSE_OFF}`;
      cellColumn++;
    }

    return output + " ".repeat(Math.max(0, width - cellColumn));
  }

  private isYankHighlighted(line: SourceLine, index: number): boolean {
    const highlight = this.state.yankHighlight;
    const grapheme = line.graphemes[index];
    if (!highlight || !grapheme) return false;

    return selectionContainsOffset(
      highlight,
      line.start + grapheme.start,
      line.start + grapheme.end,
    );
  }

  private renderComment(annotation: Annotation, width: number): DisplayRow[] {
    const label = `#${annotation.id}`;
    const topPrefix = `╭─ ${label} `;
    const topFill = "─".repeat(
      Math.max(0, width - visibleWidth(topPrefix) - 1),
    );
    const commentLines = wrapPlainText(
      annotation.comment,
      Math.max(1, width - 4),
    );
    const rows: DisplayRow[] = [
      {
        kind: "comment",
        annotationId: annotation.id,
        content:
          this.theme.fg("borderMuted", "╭─ ") +
          this.theme.fg("muted", label) +
          this.theme.fg("borderMuted", ` ${topFill}╮`),
      },
    ];

    for (const line of commentLines) {
      const padding = " ".repeat(Math.max(0, width - 3 - visibleWidth(line)));
      rows.push({
        kind: "comment",
        annotationId: annotation.id,
        content:
          this.theme.fg("borderMuted", "│") +
          " " +
          this.theme.fg("muted", line) +
          padding +
          this.theme.fg("borderMuted", "│"),
      });
    }

    rows.push({
      kind: "comment",
      annotationId: annotation.id,
      content: this.theme.fg(
        "borderMuted",
        `╰${"─".repeat(Math.max(0, width - 2))}╯`,
      ),
    });
    return rows;
  }

  private cursorMarker(): string {
    return this.state.focused ? CURSOR_MARKER : "";
  }
}

export function renderMarkdownDocument(
  sourceText: string,
  width: number,
): {
  document: SourceDocument;
  renderedLines: string[];
  logicalLineStartByLine: number[];
  logicalLineEndByLine: number[];
} {
  const renderedLines = renderMarkdownLines(sourceText, Math.max(3, width));
  const logicalLines = renderMarkdownLines(
    sourceText,
    Math.max(80, sourceText.length + 4, width),
  );
  const plainText = renderedLines
    .map((line) => stripTerminalSequences(line).replace(/ +$/u, ""))
    .join("\n");
  const document = createSourceDocument(plainText);

  const logicalLineBounds = mapLogicalLineBounds(logicalLines, document);

  return {
    document,
    renderedLines,
    logicalLineStartByLine: logicalLineBounds.startByLine,
    logicalLineEndByLine: logicalLineBounds.endByLine,
  };
}

function renderMarkdownLines(sourceText: string, width: number): string[] {
  return new Markdown(sourceText, 1, 0, getMarkdownTheme())
    .render(width)
    .map((line) => removeLastVisibleGrapheme(removeFirstVisibleGrapheme(line)));
}

type TableBlock = { start: number; end: number };

function mapLogicalLineBounds(
  logicalLines: readonly string[],
  document: SourceDocument,
): { startByLine: number[]; endByLine: number[] } {
  const startByLine = document.lines.map((_line, index) => index);
  const endByLine = document.lines.map((_line, index) => index);
  const documentLines = document.lines.map((line) => line.text);
  const documentTables = findTableBlocks(documentLines);
  const logicalTables = findTableBlocks(logicalLines);
  // Markdown changes table column widths during reflow, so text-length matching loses row boundaries.

  if (documentTables.length !== logicalTables.length) {
    mapTextLineBounds(logicalLines, documentLines, startByLine, endByLine, 0);
    return { startByLine, endByLine };
  }

  let documentOffset = 0;
  let logicalOffset = 0;
  for (let index = 0; index < documentTables.length; index++) {
    const documentTable = documentTables[index]!;
    const logicalTable = logicalTables[index]!;
    mapTextLineBounds(
      logicalLines.slice(logicalOffset, logicalTable.start),
      documentLines.slice(documentOffset, documentTable.start),
      startByLine,
      endByLine,
      documentOffset,
    );
    mapTableLineBounds(documentTable, documentLines, startByLine, endByLine);
    documentOffset = documentTable.end + 1;
    logicalOffset = logicalTable.end + 1;
  }

  mapTextLineBounds(
    logicalLines.slice(logicalOffset),
    documentLines.slice(documentOffset),
    startByLine,
    endByLine,
    documentOffset,
  );
  return { startByLine, endByLine };
}

function mapTextLineBounds(
  logicalLines: readonly string[],
  documentLines: readonly string[],
  startByLine: number[],
  endByLine: number[],
  documentOffset: number,
): void {
  let documentLineIndex = 0;

  for (const logicalLine of logicalLines) {
    if (documentLineIndex >= documentLines.length) break;

    const logicalText = normalizedLineText(logicalLine);
    if (logicalText.length === 0) {
      documentLineIndex++;
      continue;
    }

    const firstDocumentLineIndex = documentLineIndex;
    let documentText = "";
    while (
      documentLineIndex < documentLines.length &&
      documentText.length < logicalText.length
    ) {
      documentText += normalizedLineText(documentLines[documentLineIndex]!);
      documentLineIndex++;
    }

    const lastDocumentLineIndex = Math.max(
      firstDocumentLineIndex,
      documentLineIndex - 1,
    );
    for (
      let index = firstDocumentLineIndex;
      index <= lastDocumentLineIndex;
      index++
    ) {
      startByLine[documentOffset + index] =
        documentOffset + firstDocumentLineIndex;
      endByLine[documentOffset + index] =
        documentOffset + lastDocumentLineIndex;
    }
  }
}

function normalizedLineText(line: string): string {
  return stripTerminalSequences(line).replace(/ +$/u, "").replace(/\s/gu, "");
}

function findTableBlocks(lines: readonly string[]): TableBlock[] {
  const blocks: TableBlock[] = [];
  for (let index = 0; index < lines.length; index++) {
    if (!isTableTopLine(lines[index]!)) continue;
    const end = lines.findIndex(
      (line, candidate) => candidate > index && isTableBottomLine(line),
    );
    if (end < 0) continue;
    if (!lines.slice(index, end + 1).some(isTableSeparatorLine)) continue;
    blocks.push({ start: index, end });
    index = end;
  }
  return blocks;
}

function mapTableLineBounds(
  table: TableBlock,
  lines: readonly string[],
  startByLine: number[],
  endByLine: number[],
): void {
  const groups: Array<{ start: number; end: number }> = [
    { start: table.start, end: table.start },
  ];
  let groupStart = table.start + 1;

  for (let index = groupStart; index <= table.end; index++) {
    if (
      !isTableSeparatorLine(lines[index]!) &&
      !isTableBottomLine(lines[index]!)
    ) {
      continue;
    }
    if (groupStart < index) groups.push({ start: groupStart, end: index - 1 });
    groups.push({ start: index, end: index });
    groupStart = index + 1;
  }

  if (groupStart <= table.end) {
    groups.push({ start: groupStart, end: table.end });
  }

  for (const group of groups) {
    for (let index = group.start; index <= group.end; index++) {
      startByLine[index] = group.start;
      endByLine[index] = group.end;
    }
  }
}

function isTableTopLine(line: string): boolean {
  return stripTerminalSequences(line).trimStart().startsWith("┌");
}

function isTableSeparatorLine(line: string): boolean {
  return stripTerminalSequences(line).trimStart().startsWith("├");
}

function isTableBottomLine(line: string): boolean {
  return stripTerminalSequences(line).trimStart().startsWith("└");
}

function removeFirstVisibleGrapheme(text: string): string {
  return removeVisibleGrapheme(text, "first");
}

function removeLastVisibleGrapheme(text: string): string {
  return removeVisibleGrapheme(text, "last");
}

function removeVisibleGrapheme(
  text: string,
  position: "first" | "last",
): string {
  const parts: Array<{ ansi: boolean; text: string }> = [];
  let lastIndex = 0;

  for (const match of text.matchAll(ANSI_SEQUENCE_RE)) {
    appendText(text.slice(lastIndex, match.index));
    parts.push({ ansi: true, text: match[0] });
    lastIndex = match.index + match[0].length;
  }
  appendText(text.slice(lastIndex));

  const targetIndex =
    position === "first"
      ? parts.findIndex((part) => !part.ansi)
      : parts.findLastIndex((part) => !part.ansi);
  if (targetIndex < 0) return text;
  parts.splice(targetIndex, 1);
  return parts.map((part) => part.text).join("");

  function appendText(segment: string): void {
    for (const grapheme of renderedGraphemeSegmenter.segment(segment)) {
      parts.push({ ansi: false, text: grapheme.segment });
    }
  }
}

export function cellColumn(line: SourceLine, graphemeIndex: number): number {
  let column = 0;
  for (let index = 0; index < graphemeIndex; index++) {
    column += cellWidth(line.graphemes[index]!.text, column);
  }
  return column;
}

export function cellWidth(text: string, column: number): number {
  if (text === "\t") return TAB_SIZE - (column % TAB_SIZE);
  return visibleWidth(text);
}

export function graphemeAtOrBeforeColumn(
  line: SourceLine,
  targetColumn: number,
): number {
  if (line.graphemes.length === 0) return 0;
  let column = 0;
  let index = 0;
  for (; index < line.graphemes.length; index++) {
    const width = cellWidth(line.graphemes[index]!.text, column);
    if (column + width > targetColumn) return index;
    column += width;
  }
  return line.graphemes.length - 1;
}

export function displayRowColumn(
  line: SourceLine,
  row: Pick<SourceDisplayRow, "startGrapheme">,
  graphemeIndex: number,
): number {
  return cellColumn(line, graphemeIndex) - cellColumn(line, row.startGrapheme);
}

export function graphemeAtOrBeforeDisplayColumn(
  line: SourceLine,
  row: Pick<SourceDisplayRow, "startGrapheme" | "endGrapheme">,
  targetColumn: number,
): number {
  if (row.startGrapheme >= row.endGrapheme) return row.startGrapheme;

  const rowStartColumn = cellColumn(line, row.startGrapheme);
  const desiredColumn = Math.max(0, targetColumn);
  let column = rowStartColumn;
  let selected = row.startGrapheme;

  for (let index = row.startGrapheme; index < row.endGrapheme; index++) {
    const width = cellWidth(line.graphemes[index]!.text, column);
    const relativeColumn = column - rowStartColumn;
    if (relativeColumn > desiredColumn) break;
    selected = index;
    if (desiredColumn < relativeColumn + width) return index;
    column += width;
  }

  return selected;
}

function wrapPlainText(text: string, width: number): string[] {
  const segmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });
  const lines: string[] = [];
  let line = "";
  let lineWidth = 0;

  for (const segment of segmenter.segment(text)) {
    const segmentWidth = visibleWidth(segment.segment);
    if (line && lineWidth + segmentWidth > width) {
      lines.push(line);
      line = "";
      lineWidth = 0;
    }
    line += segment.segment;
    lineWidth += segmentWidth;
  }
  lines.push(line);
  return lines;
}
