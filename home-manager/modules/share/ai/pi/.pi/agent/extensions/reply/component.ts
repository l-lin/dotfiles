import type { Theme } from "@earendil-works/pi-coding-agent";
import {
  CURSOR_MARKER,
  Input,
  matchesKey,
  truncateToWidth,
  visibleWidth,
  type Component,
  type Focusable,
  type KeyId,
  type TUI,
} from "@earendil-works/pi-tui";
import {
  annotationLines,
  createSourceDocument,
  formatAnnotatedText,
  getSelectionRange,
  selectionContainsOffset,
  type Annotation,
  type CursorPosition,
  type SourceDocument,
  type SourceLine,
  type VisualMode,
} from "./model.js";

export interface ReplyKeymap {
  open: KeyId;
  save: KeyId;
  close: KeyId;
  comment: KeyId;
  left: KeyId;
  down: KeyId;
  up: KeyId;
  right: KeyId;
  halfPageUp: KeyId;
  halfPageDown: KeyId;
  characterVisual: KeyId;
  lineVisual: KeyId;
}

export interface ReplyComponentResult {
  action: "save" | "cancel";
  text?: string;
}

type DisplayRow = SourceDisplayRow | CommentDisplayRow;

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

type CommentInputState = {
  annotation: {
    start: number;
    end: number;
    text: string;
  };
  input: Input;
};

const ANSI_REVERSE_ON = "\x1b[7m";
const ANSI_REVERSE_OFF = "\x1b[27m";
const TAB_SIZE = 4;

export class ReplyComponent implements Component, Focusable {
  focused = false;

  private readonly tui: TUI;
  private readonly theme: Theme;
  private readonly done: (result: ReplyComponentResult) => void;
  private readonly document: SourceDocument;
  private readonly keymap: ReplyKeymap;
  private readonly annotations: Annotation[] = [];
  private readonly onSave?: (text: string) => void;

  private cursor: CursorPosition = { line: 0, grapheme: 0 };
  private preferredColumn: number | null = null;
  private mode: "normal" | "visual" = "normal";
  private visualMode: VisualMode = "character";
  private visualAnchor: CursorPosition | null = null;
  private commentInput: CommentInputState | null = null;
  private scrollTop = 0;
  private lastInnerWidth = 80;

  constructor(
    tui: TUI,
    theme: Theme,
    sourceText: string,
    keymap: ReplyKeymap,
    done: (result: ReplyComponentResult) => void,
    onSave?: (text: string) => void,
  ) {
    this.tui = tui;
    this.theme = theme;
    this.document = createSourceDocument(sourceText);
    this.keymap = keymap;
    this.done = done;
    this.onSave = onSave;
  }

  handleInput(data: string): void {
    if (matchesKey(data, this.keymap.open)) {
      this.restart();
      return;
    }

    if (this.commentInput) {
      this.commentInput.input.handleInput(data);
      this.tui.requestRender();
      return;
    }

    if (matchesKey(data, this.keymap.close)) {
      if (this.mode === "visual") {
        this.exitVisual();
        this.tui.requestRender();
      } else {
        this.done({ action: "cancel" });
      }
      return;
    }

    if (this.mode === "visual" && matchesKey(data, this.keymap.comment)) {
      this.openCommentInput();
      return;
    }

    if (this.mode === "normal" && matchesKey(data, this.keymap.save)) {
      if (this.annotations.length === 0) {
        this.done({ action: "cancel" });
      } else {
        const text = this.formatAnnotations();
        this.onSave?.(text);
        this.done({ action: "save", text });
      }
      return;
    }

    if (
      this.mode === "normal" &&
      matchesKey(data, this.keymap.characterVisual)
    ) {
      this.enterVisual("character");
      return;
    }

    if (this.mode === "normal" && matchesKey(data, this.keymap.lineVisual)) {
      this.enterVisual("line");
      return;
    }

    if (
      this.mode === "visual" &&
      matchesKey(data, this.keymap.characterVisual)
    ) {
      if (this.visualMode === "character") {
        this.exitVisual();
      } else {
        this.visualMode = "character";
      }
      this.tui.requestRender();
      return;
    }

    if (this.mode === "visual" && matchesKey(data, this.keymap.lineVisual)) {
      if (this.visualMode === "line") {
        this.exitVisual();
      } else {
        this.visualMode = "line";
      }
      this.tui.requestRender();
      return;
    }

    if (this.handleMovement(data)) return;
  }

  render(width: number): string[] {
    const outerWidth = Math.max(1, width);
    if (outerWidth < 3) return [truncateToWidth("Reply", outerWidth)];

    const innerWidth = outerWidth - 2;
    this.lastInnerWidth = innerWidth;
    const viewportHeight = this.getViewportHeight();
    const displayRows = this.buildDisplayRows(innerWidth);
    this.keepCursorVisible(displayRows, viewportHeight);

    const visibleRows = displayRows.slice(
      this.scrollTop,
      this.scrollTop + viewportHeight,
    );
    while (visibleRows.length < viewportHeight) {
      visibleRows.push({
        kind: "source",
        line: -1,
        startGrapheme: 0,
        endGrapheme: 0,
        content: "",
      });
    }

    const lines: string[] = [this.topBorder(innerWidth)];
    for (const row of visibleRows) {
      const content =
        row.kind === "source" && row.line === -1 ? "" : row.content;
      lines.push(this.frameLine(content, innerWidth));
    }
    if (this.commentInput) {
      const inputWidth = Math.max(1, innerWidth - 1);
      const renderedInput = this.commentInput.input.render(inputWidth)[0] ?? "";
      const inputLine = renderedInput.startsWith("> ")
        ? renderedInput.slice(2)
        : renderedInput;
      lines.push(this.frameLine(` # ${inputLine}`, innerWidth));
    }
    lines.push(this.bottomBorder(innerWidth));
    return lines;
  }

  invalidate(): void {
    this.tui.requestRender();
  }

  dispose(): void {
    this.commentInput = null;
  }

  private restart(): void {
    this.annotations.length = 0;
    this.cursor = { line: 0, grapheme: 0 };
    this.preferredColumn = null;
    this.mode = "normal";
    this.visualAnchor = null;
    this.commentInput = null;
    this.scrollTop = 0;
    this.tui.requestRender();
  }

  private getViewportHeight(): number {
    const terminalRows = this.tui.terminal.rows;
    const frameRows = Math.floor(terminalRows * 0.85);
    const fixedRows = this.commentInput ? 3 : 2;
    return Math.max(1, frameRows - fixedRows);
  }

  private handleMovement(data: string): boolean {
    // AI: keep the first milestone to the requested motions so broader Vim commands can be added independently.
    let handled = true;

    if (matchesKey(data, this.keymap.left)) this.moveHorizontal(-1);
    else if (matchesKey(data, this.keymap.right)) this.moveHorizontal(1);
    else if (matchesKey(data, this.keymap.down)) this.moveVertical(1);
    else if (matchesKey(data, this.keymap.up)) this.moveVertical(-1);
    else if (matchesKey(data, this.keymap.halfPageUp)) this.scrollHalfPage(-1);
    else if (matchesKey(data, this.keymap.halfPageDown)) this.scrollHalfPage(1);
    else handled = false;

    if (!handled) return false;

    this.tui.requestRender();
    return true;
  }

  private moveHorizontal(direction: -1 | 1): void {
    const line = this.document.lines[this.cursor.line]!;
    const next = this.cursor.grapheme + direction;
    if (next >= 0 && next < line.graphemes.length) {
      this.cursor.grapheme = next;
      this.preferredColumn = null;
    }
  }

  private moveVertical(direction: -1 | 1): void {
    const nextLine = this.cursor.line + direction;
    if (nextLine < 0 || nextLine >= this.document.lines.length) return;

    const currentLine = this.document.lines[this.cursor.line]!;
    const currentColumn = this.cellColumn(currentLine, this.cursor.grapheme);
    const targetLine = this.document.lines[nextLine]!;
    const targetColumn = this.preferredColumn ?? currentColumn;
    this.cursor = {
      line: nextLine,
      grapheme: this.graphemeAtOrBeforeColumn(targetLine, targetColumn),
    };
    this.preferredColumn = targetColumn;
  }

  private scrollHalfPage(direction: -1 | 1): void {
    const currentLine = this.document.lines[this.cursor.line]!;
    const rows = this.buildDisplayRows(this.lastInnerWidth);
    const step = Math.max(1, Math.floor(this.getViewportHeight() / 2));
    this.scrollTop = Math.max(
      0,
      Math.min(
        Math.max(0, rows.length - this.getViewportHeight()),
        this.scrollTop + direction * step,
      ),
    );

    const sourceRow = this.findCursorRow(rows);
    if (sourceRow >= 0) {
      const targetRow = Math.max(
        0,
        Math.min(rows.length - 1, sourceRow + direction * step),
      );
      const targetSource = rows[targetRow];
      if (targetSource?.kind === "source") {
        const targetLine = this.document.lines[targetSource.line]!;
        const targetColumn =
          this.preferredColumn ??
          this.cellColumn(currentLine, this.cursor.grapheme);
        this.cursor = {
          line: targetSource.line,
          grapheme: this.graphemeAtOrBeforeColumn(targetLine, targetColumn),
        };
        this.preferredColumn = targetColumn;
      }
    }
  }

  private enterVisual(mode: VisualMode): void {
    this.mode = "visual";
    this.visualMode = mode;
    this.visualAnchor = { ...this.cursor };
    this.tui.requestRender();
  }

  private exitVisual(): void {
    this.mode = "normal";
    this.visualAnchor = null;
  }

  private openCommentInput(): void {
    if (!this.visualAnchor) return;
    const selection = getSelectionRange(
      this.document,
      this.visualAnchor,
      this.cursor,
      this.visualMode,
    );
    if (!selection || selection.start === selection.end) {
      this.exitVisual();
      this.tui.requestRender();
      return;
    }

    const input = new Input();
    input.focused = this.focused;
    input.onSubmit = (comment) => {
      if (comment.trim().length === 0) {
        this.commentInput = null;
        this.mode = "visual";
        this.tui.requestRender();
        return;
      }

      this.annotations.push({
        id: this.annotations.length + 1,
        start: selection.start,
        end: selection.end,
        text: selection.text,
        comment,
      });
      this.commentInput = null;
      this.exitVisual();
      this.tui.requestRender();
    };
    input.onEscape = () => {
      this.commentInput = null;
      this.mode = "visual";
      this.tui.requestRender();
    };
    this.commentInput = { annotation: selection, input };
    this.tui.requestRender();
  }

  private buildDisplayRows(width: number): DisplayRow[] {
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
      for (const annotation of comments) {
        rows.push(...this.renderComment(annotation, width));
      }
    }
    return rows;
  }

  private renderSourceLine(
    line: SourceLine,
    lineIndex: number,
    width: number,
  ): Array<{ start: number; end: number; content: string }> {
    const lineNumberWidth = String(this.document.lines.length).length;
    const prefixWidth = lineNumberWidth + 4;
    const textWidth = Math.max(1, width - prefixWidth);
    const chunks: Array<{ start: number; end: number }> = [];
    let chunkStart = 0;
    let chunkCellWidth = 0;

    for (let index = 0; index < line.graphemes.length; index++) {
      const grapheme = line.graphemes[index]!;
      const nextWidth = this.cellWidth(grapheme.text, chunkCellWidth);
      if (chunkCellWidth > 0 && chunkCellWidth + nextWidth > textWidth) {
        chunks.push({ start: chunkStart, end: index });
        chunkStart = index;
        chunkCellWidth = 0;
      }
      chunkCellWidth += this.cellWidth(grapheme.text, chunkCellWidth);
    }

    if (line.graphemes.length > 0) {
      chunks.push({ start: chunkStart, end: line.graphemes.length });
    } else {
      chunks.push({ start: 0, end: 0 });
    }

    return chunks.map((chunk, chunkIndex) => {
      const content = this.renderChunk(
        line,
        lineIndex,
        chunk.start,
        chunk.end,
        width - prefixWidth,
      );
      const lineNumber = String(lineIndex + 1).padStart(lineNumberWidth);
      const gutter =
        chunkIndex === 0
          ? ` ${lineNumber} `
          : ` ${" ".repeat(lineNumberWidth)} `;
      return {
        start: chunk.start,
        end: chunk.end,
        content:
          this.theme.fg("dim", gutter) +
          this.theme.fg("borderMuted", "│ ") +
          content,
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
    const activeSelection = this.getActiveSelection();
    let output = "";
    let cellColumn = 0;

    for (let index = start; index < end; index++) {
      const grapheme = line.graphemes[index]!;
      const globalStart = line.start + grapheme.start;
      const globalEnd = line.start + grapheme.end;
      const annotation = this.annotations.find((candidate) =>
        selectionContainsOffset(candidate, globalStart, globalEnd),
      );
      const selected = activeSelection
        ? selectionContainsOffset(activeSelection, globalStart, globalEnd)
        : false;
      const isCursor =
        this.commentInput === null &&
        this.cursor.line === lineIndex &&
        this.cursor.grapheme === index;

      const displayText =
        grapheme.text === "\t"
          ? " ".repeat(this.cellWidth(grapheme.text, cellColumn))
          : grapheme.text;
      let styled = displayText;
      if (annotation) styled = this.theme.underline(styled);
      if (selected) styled = this.theme.bg("selectedBg", styled);
      if (isCursor) {
        const cursorContent = styled || " ";
        styled = `${this.cursorMarker()}${ANSI_REVERSE_ON}${cursorContent}${ANSI_REVERSE_OFF}`;
      }
      output += styled;
      cellColumn += this.cellWidth(grapheme.text, cellColumn);
    }

    if (
      this.commentInput === null &&
      this.cursor.line === lineIndex &&
      this.cursor.grapheme >= end &&
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

  private getActiveSelection() {
    if (this.mode !== "visual" || !this.visualAnchor) return null;
    return getSelectionRange(
      this.document,
      this.visualAnchor,
      this.cursor,
      this.visualMode,
    );
  }

  private findCursorRow(rows: DisplayRow[]): number {
    return rows.findIndex(
      (row) =>
        row.kind === "source" &&
        row.line === this.cursor.line &&
        (row.startGrapheme === row.endGrapheme ||
          (this.cursor.grapheme >= row.startGrapheme &&
            this.cursor.grapheme < row.endGrapheme)),
    );
  }

  private keepCursorVisible(rows: DisplayRow[], viewportHeight: number): void {
    const cursorRow = this.findCursorRow(rows);
    if (cursorRow < 0) return;
    if (cursorRow < this.scrollTop) this.scrollTop = cursorRow;
    if (cursorRow >= this.scrollTop + viewportHeight) {
      this.scrollTop = cursorRow - viewportHeight + 1;
    }
    this.scrollTop = Math.max(
      0,
      Math.min(this.scrollTop, Math.max(0, rows.length - viewportHeight)),
    );
  }

  private formatAnnotations(): string {
    return formatAnnotatedText(this.annotations);
  }

  private topBorder(width: number): string {
    const title = this.theme.fg("accent", this.theme.bold(" Reply "));
    const titleWidth = visibleWidth(title);
    const leftWidth = Math.floor(Math.max(0, width - titleWidth) / 2);
    const rightWidth = Math.max(0, width - titleWidth - leftWidth);
    return (
      this.theme.fg("border", `╭${"─".repeat(leftWidth)}`) +
      title +
      this.theme.fg("border", `${"─".repeat(rightWidth)}╮`)
    );
  }

  private bottomBorder(width: number): string {
    return this.theme.fg("border", `╰${"─".repeat(width)}╯`);
  }

  private frameLine(content: string, width: number): string {
    const fitted = truncateToWidth(content, width, "", true);
    const padding = " ".repeat(Math.max(0, width - visibleWidth(fitted)));
    return (
      this.theme.fg("border", "│") +
      fitted +
      padding +
      this.theme.fg("border", "│")
    );
  }

  private cursorMarker(): string {
    return this.focused ? CURSOR_MARKER : "";
  }

  private cellColumn(line: SourceLine, graphemeIndex: number): number {
    let column = 0;
    for (let index = 0; index < graphemeIndex; index++) {
      column += this.cellWidth(line.graphemes[index]!.text, column);
    }
    return column;
  }

  private cellWidth(text: string, column: number): number {
    if (text === "\t") return TAB_SIZE - (column % TAB_SIZE);
    return visibleWidth(text);
  }

  private graphemeAtOrBeforeColumn(
    line: SourceLine,
    targetColumn: number,
  ): number {
    if (line.graphemes.length === 0) return 0;
    let column = 0;
    let index = 0;
    for (; index < line.graphemes.length; index++) {
      const width = this.cellWidth(line.graphemes[index]!.text, column);
      if (column + width > targetColumn) return index;
      column += width;
    }
    return line.graphemes.length - 1;
  }
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
