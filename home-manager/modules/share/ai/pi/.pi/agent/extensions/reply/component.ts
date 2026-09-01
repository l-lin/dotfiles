import type { Theme } from "@earendil-works/pi-coding-agent";
import {
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
  createSourceDocument,
  formatAnnotatedText,
  getSelectionRange,
  type Annotation,
  type CursorPosition,
  type SourceDocument,
  type VisualMode,
} from "./model.js";
import {
  findCharMotionTarget,
  findWordMotionTarget,
  firstNonBlankColumn,
  isPrintableAscii,
  reverseCharMotion,
} from "../vim/motions.js";
import type { CharMotion, LastCharMotion } from "../vim/types.js";
import {
  cellColumn,
  graphemeAtOrBeforeColumn,
  ReplyRenderer,
  type DisplayRow,
} from "./render.js";

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

type CommentInputState = {
  input: Input;
};

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
  private pendingG = false;
  private pendingCharMotion: CharMotion | null = null;
  private lastCharMotion: LastCharMotion | null = null;
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
    if (this.pendingG) {
      this.handlePendingG(data);
      return;
    }

    if (this.pendingCharMotion) {
      this.handlePendingCharMotion(data);
      return;
    }

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
        const text = formatAnnotatedText(this.annotations);
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

    if (this.mode === "visual" && data === "o") {
      this.swapVisualCursor();
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
    const renderer = this.createRenderer();
    const displayRows = renderer.buildDisplayRows(innerWidth);
    this.keepCursorVisible(renderer, displayRows, viewportHeight);

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
    this.pendingG = false;
    this.pendingCharMotion = null;
    this.lastCharMotion = null;
    this.scrollTop = 0;
    this.tui.requestRender();
  }

  private getViewportHeight(): number {
    const terminalRows = this.tui.terminal.rows;
    const frameRows = Math.floor(terminalRows * 0.85);
    const fixedRows = this.commentInput ? 3 : 2;
    return Math.max(1, frameRows - fixedRows);
  }

  private handlePendingG(data: string): void {
    this.pendingG = false;
    if (matchesKey(data, "escape")) {
      this.tui.requestRender();
      return;
    }

    if (data === "g") {
      this.moveToLine(0);
      this.tui.requestRender();
      return;
    }

    // A non-g key cancels the sequence, then starts its own normal command.
    this.handleInput(data);
  }

  private handlePendingCharMotion(data: string): void {
    const motion = this.pendingCharMotion;
    this.pendingCharMotion = null;
    if (!motion || matchesKey(data, "escape") || !isPrintableAscii(data)) {
      this.tui.requestRender();
      return;
    }

    this.executeCharMotion(motion, data);
    this.tui.requestRender();
  }

  private handleMovement(data: string): boolean {
    if (matchesKey(data, this.keymap.left)) this.moveHorizontal(-1);
    else if (matchesKey(data, this.keymap.right)) this.moveHorizontal(1);
    else if (matchesKey(data, this.keymap.down)) this.moveVertical(1);
    else if (matchesKey(data, this.keymap.up)) this.moveVertical(-1);
    else if (matchesKey(data, this.keymap.halfPageUp)) this.scrollHalfPage(-1);
    else if (matchesKey(data, this.keymap.halfPageDown)) this.scrollHalfPage(1);
    else if (data === "g") this.pendingG = true;
    else if (data === "G") this.moveToLine(this.document.lines.length - 1);
    else if (data === "w") this.moveWord("forward", "start");
    else if (data === "b") this.moveWord("backward", "start");
    else if (data === "e") this.moveWord("forward", "end");
    else if (data === "0") this.moveToColumn(0);
    else if (data === "_")
      this.moveToColumn(firstNonBlankColumn(this.currentLineGraphemes()));
    else if (data === "$")
      this.moveToColumn(this.currentLineGraphemes().length - 1);
    else if (data === "f" || data === "F" || data === "t" || data === "T") {
      this.pendingCharMotion = data;
    } else if (data === ";" || data === ",") {
      if (!this.lastCharMotion) return false;
      const motion =
        data === ";"
          ? this.lastCharMotion.motion
          : reverseCharMotion(this.lastCharMotion.motion);
      this.executeCharMotion(motion, this.lastCharMotion.char, false);
    } else return false;

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

  private currentLineGraphemes(): string[] {
    return this.document.lines[this.cursor.line]!.graphemes.map(
      (grapheme) => grapheme.text,
    );
  }

  private moveToColumn(column: number): void {
    const line = this.document.lines[this.cursor.line]!;
    this.cursor.grapheme = Math.max(
      0,
      Math.min(column, Math.max(0, line.graphemes.length - 1)),
    );
    this.preferredColumn = null;
  }

  private moveToLine(line: number): void {
    const targetLine = Math.max(
      0,
      Math.min(line, this.document.lines.length - 1),
    );
    const target = this.document.lines[targetLine]!;
    this.cursor = {
      line: targetLine,
      grapheme: firstNonBlankColumn(
        target.graphemes.map((grapheme) => grapheme.text),
      ),
    };
    this.preferredColumn = null;
  }

  private moveWord(
    direction: "forward" | "backward",
    target: "start" | "end",
  ): void {
    const motion = findWordMotionTarget(
      this.document.lines.map((line) =>
        line.graphemes.map((grapheme) => grapheme.text),
      ),
      { line: this.cursor.line, column: this.cursor.grapheme },
      direction,
      target,
    );
    this.cursor = { line: motion.line, grapheme: motion.column };
    this.preferredColumn = null;
  }

  private executeCharMotion(
    motion: CharMotion,
    targetChar: string,
    saveMotion = true,
  ): void {
    const line = this.currentLineGraphemes();
    const target = findCharMotionTarget(
      line,
      this.cursor.grapheme,
      motion,
      targetChar,
      !saveMotion,
    );
    if (target === null) return;

    if (saveMotion) this.lastCharMotion = { motion, char: targetChar };
    this.moveToColumn(target);
  }

  private moveVertical(direction: -1 | 1): void {
    const nextLine = this.cursor.line + direction;
    if (nextLine < 0 || nextLine >= this.document.lines.length) return;

    const currentLine = this.document.lines[this.cursor.line]!;
    const currentColumn = cellColumn(currentLine, this.cursor.grapheme);
    const targetLine = this.document.lines[nextLine]!;
    const targetColumn = this.preferredColumn ?? currentColumn;
    this.cursor = {
      line: nextLine,
      grapheme: graphemeAtOrBeforeColumn(targetLine, targetColumn),
    };
    this.preferredColumn = targetColumn;
  }

  private scrollHalfPage(direction: -1 | 1): void {
    const currentLine = this.document.lines[this.cursor.line]!;
    const renderer = this.createRenderer();
    const rows = renderer.buildDisplayRows(this.lastInnerWidth);
    const step = Math.max(1, Math.floor(this.getViewportHeight() / 2));
    this.scrollTop = Math.max(
      0,
      Math.min(
        Math.max(0, rows.length - this.getViewportHeight()),
        this.scrollTop + direction * step,
      ),
    );

    const sourceRow = renderer.findCursorRow(rows);
    if (sourceRow >= 0) {
      const targetRow = Math.max(
        0,
        Math.min(rows.length - 1, sourceRow + direction * step),
      );
      const targetSource = rows[targetRow];
      if (targetSource?.kind === "source") {
        const targetLine = this.document.lines[targetSource.line]!;
        const targetColumn =
          this.preferredColumn ?? cellColumn(currentLine, this.cursor.grapheme);
        this.cursor = {
          line: targetSource.line,
          grapheme: graphemeAtOrBeforeColumn(targetLine, targetColumn),
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

  private swapVisualCursor(): void {
    if (!this.visualAnchor) return;

    const anchor = this.visualAnchor;
    this.visualAnchor = { ...this.cursor };
    this.cursor = { ...anchor };
    this.preferredColumn = null;
    this.tui.requestRender();
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
    this.commentInput = { input };
    this.tui.requestRender();
  }

  private createRenderer(): ReplyRenderer {
    return new ReplyRenderer(this.theme, this.document, this.annotations, {
      cursor: this.cursor,
      activeSelection:
        this.mode === "visual" && this.visualAnchor
          ? getSelectionRange(
              this.document,
              this.visualAnchor,
              this.cursor,
              this.visualMode,
            )
          : null,
      hasCommentInput: this.commentInput !== null,
      focused: this.focused,
    });
  }

  private keepCursorVisible(
    renderer: ReplyRenderer,
    rows: DisplayRow[],
    viewportHeight: number,
  ): void {
    const cursorRow = renderer.findCursorRow(rows);
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
}
