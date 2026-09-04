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
          content += this.renderGrapheme(
            line,
            lineIndex,
            graphemeIndex,
            segment.segment,
            this.isYankHighlighted(line, graphemeIndex),
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

  private renderGrapheme(
    line: SourceLine,
    lineIndex: number,
    index: number,
    displayText: string,
    yankHighlighted = false,
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
      styled = `${this.cursorMarker()}${ANSI_REVERSE_ON}${styled}${ANSI_REVERSE_OFF}`;
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
      const yankHighlighted = this.isYankHighlighted(line, index);
      const isCurrentSearchMatch =
        searchMatch !== undefined &&
        this.state.currentSearchMatch !== null &&
        searchMatch.start === this.state.currentSearchMatch.start &&
        searchMatch.end === this.state.currentSearchMatch.end;

      const displayText =
        grapheme.text === "\t"
          ? " ".repeat(cellWidth(grapheme.text, cellColumn))
          : grapheme.text;
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
      output += styled;
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
): { document: SourceDocument; renderedLines: string[] } {
  const renderedLines = new Markdown(sourceText, 1, 0, getMarkdownTheme())
    .render(Math.max(3, width))
    .map((line) => removeLastVisibleGrapheme(removeFirstVisibleGrapheme(line)));
  const plainText = renderedLines
    .map((line) => stripTerminalSequences(line).replace(/ +$/u, ""))
    .join("\n");

  return {
    document: createSourceDocument(plainText),
    renderedLines,
  };
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
