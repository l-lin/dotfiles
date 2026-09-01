import type { Theme } from "@earendil-works/pi-coding-agent";
import { CURSOR_MARKER, visibleWidth } from "@earendil-works/pi-tui";
import {
  annotationLines,
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
  hasCommentInput: boolean;
  focused: boolean;
}

const ANSI_REVERSE_ON = "\x1b[7m";
const ANSI_REVERSE_OFF = "\x1b[27m";
const TAB_SIZE = 4;

export class ReplyRenderer {
  constructor(
    private readonly theme: Theme,
    private readonly document: SourceDocument,
    private readonly annotations: readonly Annotation[],
    private readonly state: ReplyRenderState,
  ) {}

  buildDisplayRows(width: number): DisplayRow[] {
    const rows: DisplayRow[] = [];
    for (
      let lineIndex = 0;
      lineIndex < this.document.lines.length;
      lineIndex++
    ) {
      const line = this.document.lines[lineIndex]!;
      for (const row of this.renderSourceLine(line, lineIndex, width)) {
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
      if (selected) {
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
