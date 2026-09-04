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
  cursorOffset,
  cursorPositionAtSearchMatch,
  decodeSearchQuery,
  findKeywordAtCursor,
  findKeywordSearchMatches,
  findLiteralSearchMatches,
  formatAnnotatedText,
  getSelectionRange,
  normalizePlatformLineEndings,
  selectionContainsOffset,
  searchMatchContainsCursor,
  type Annotation,
  type CursorPosition,
  type SearchDirection,
  type SearchMatch,
  type SelectionRange,
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
  displayRowColumn,
  graphemeAtOrBeforeColumn,
  graphemeAtOrBeforeDisplayColumn,
  renderMarkdownDocument,
  ReplyRenderer,
  type DisplayRow,
} from "./render.js";

export interface ReplyKeymap {
  open: KeyId;
  save: KeyId;
  close: KeyId;
  escape: KeyId;
  comment: KeyId;
  yank: KeyId;
  lineYank: KeyId;
  edit: KeyId;
  delete: KeyId;
  visualSwapCursor: KeyId;
  left: KeyId;
  down: KeyId;
  up: KeyId;
  right: KeyId;
  halfPageUp: KeyId;
  halfPageDown: KeyId;
  characterVisual: KeyId;
  lineVisual: KeyId;
  lineMotionPrefix: KeyId;
  lastLine: KeyId;
  wordForward: KeyId;
  wordBackward: KeyId;
  wordEnd: KeyId;
  lineStart: KeyId;
  firstNonBlank: KeyId;
  lineEnd: KeyId;
  findForward: KeyId;
  findBackward: KeyId;
  tillForward: KeyId;
  tillBackward: KeyId;
  repeatForward: KeyId;
  repeatBackward: KeyId;
  searchForward: KeyId;
  searchBackward: KeyId;
  searchNext: KeyId;
  searchPrevious: KeyId;
  wordSearchForward: KeyId;
  wordSearchBackward: KeyId;
}

export interface ReplyComponentResult {
  action: "save" | "cancel";
  text?: string;
}

type CommentInputState = {
  input: Input;
};

type SearchState = {
  query: string;
  prefix: "/" | "?";
  direction: SearchDirection;
  kind: "literal" | "word";
  matches: SearchMatch[];
  currentIndex: number;
};

type SearchInputState = {
  input: Input;
  direction: SearchDirection;
  prefix: "/" | "?";
  before: SearchSnapshot;
};

type PendingYank =
  | { kind: "operator" }
  | { kind: "g" }
  | { kind: "char"; motion: CharMotion }
  | { kind: "text-object"; outer: boolean };

type YankCallback = (text: string) => void | Promise<void>;

type SearchSnapshot = {
  cursor: CursorPosition;
  preferredColumn: number | null;
  mode: "normal" | "visual";
  visualAnchor: CursorPosition | null;
  search: SearchState | null;
};

type SearchStateSnapshot = {
  query: string;
  prefix: "/" | "?";
  direction: SearchDirection;
  kind: "literal" | "word";
  matchOrdinals: number[];
  currentMatchOrdinal: number | null;
};

type DisplayStateSnapshot = {
  cursorOrdinal: number;
  preferredColumn: number | null;
  mode: "normal" | "visual";
  visualAnchorOrdinal: number | null;
  annotations: Array<{
    annotation: Annotation;
    startOrdinal: number;
    endOrdinal: number;
  }>;
  search: SearchStateSnapshot | null;
  searchInputBefore: {
    cursorOrdinal: number;
    preferredColumn: number | null;
    mode: "normal" | "visual";
    visualAnchorOrdinal: number | null;
    search: SearchStateSnapshot | null;
  } | null;
  yankHighlight: {
    startOrdinal: number;
    endOrdinal: number;
  } | null;
};

export class ReplyComponent implements Component, Focusable {
  focused = false;

  private readonly tui: TUI;
  private readonly theme: Theme;
  private readonly done: (result: ReplyComponentResult) => void;
  private rawSourceText: string;
  private document: SourceDocument;
  private renderedLines: readonly string[] = [];
  private renderedWidth: number | null = null;
  private readonly keymap: ReplyKeymap;
  private readonly annotations: Annotation[] = [];
  private nextAnnotationId = 1;
  private readonly onSave?: (text: string) => void;
  private readonly onRefresh?: () => string | null;
  private readonly onYank?: YankCallback;
  private readonly onYankError?: (error: unknown) => void;

  private cursor: CursorPosition = { line: 0, grapheme: 0 };
  private preferredColumn: number | null = null;
  private mode: "normal" | "visual" = "normal";
  private visualMode: VisualMode = "character";
  private visualAnchor: CursorPosition | null = null;
  private commentInput: CommentInputState | null = null;
  private searchInput: SearchInputState | null = null;
  private search: SearchState | null = null;
  private pendingG = false;
  private pendingCharMotion: CharMotion | null = null;
  private pendingYank: PendingYank | null = null;
  private lastCharMotion: LastCharMotion | null = null;
  private yankHighlight: SelectionRange | null = null;
  private yankHighlightTimer: ReturnType<typeof setTimeout> | null = null;
  private yankHighlightGeneration = 0;
  private yankOperationId = 0;
  private latestSuccessfulYankId = 0;
  private yankSessionId = 0;
  private disposed = false;
  private scrollTop = 0;
  private lastInnerWidth = 80;

  constructor(
    tui: TUI,
    theme: Theme,
    sourceText: string,
    keymap: ReplyKeymap,
    done: (result: ReplyComponentResult) => void,
    onSave?: (text: string) => void,
    onRefresh?: () => string | null,
    onYank?: YankCallback,
    onYankError?: (error: unknown) => void,
  ) {
    this.tui = tui;
    this.theme = theme;
    this.rawSourceText = sourceText;
    this.document = createSourceDocument(sourceText);
    this.keymap = keymap;
    this.done = done;
    this.onSave = onSave;
    this.onRefresh = onRefresh;
    this.onYank = onYank;
    this.onYankError = onYankError;
    this.ensureRenderedDocument(this.markdownWidth(this.lastInnerWidth));
  }

  handleInput(data: string): void {
    if (this.searchInput) {
      if (matchesKey(data, this.keymap.open)) {
        this.restart();
      } else {
        this.handleSearchInput(data);
      }
      return;
    }

    if (this.pendingYank) {
      this.handlePendingYank(data);
      return;
    }

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

    if (this.mode === "normal" && matchesKey(data, this.keymap.edit)) {
      const annotation = this.findAnnotationAtCursor();
      if (annotation) this.openCommentInput(annotation);
      return;
    }

    if (this.mode === "normal" && matchesKey(data, this.keymap.delete)) {
      const annotation = this.findAnnotationAtCursor();
      if (!annotation) return;

      const annotationIndex = this.annotations.indexOf(annotation);
      if (annotationIndex >= 0) {
        this.annotations.splice(annotationIndex, 1);
        this.tui.requestRender();
      }
      return;
    }

    if (matchesKey(data, this.keymap.searchForward)) {
      this.beginSearch("forward", "/");
      return;
    }

    if (matchesKey(data, this.keymap.searchBackward)) {
      this.beginSearch("backward", "?");
      return;
    }

    if (matchesKey(data, this.keymap.wordSearchForward)) {
      this.searchWord("forward");
      return;
    }

    if (matchesKey(data, this.keymap.wordSearchBackward)) {
      this.searchWord("backward");
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

    if (
      this.mode === "visual" &&
      (matchesKey(data, this.keymap.yank) ||
        matchesKey(data, this.keymap.lineYank))
    ) {
      this.yankVisualSelection();
      return;
    }

    if (this.mode === "visual" && matchesKey(data, this.keymap.comment)) {
      this.openCommentInput();
      return;
    }

    if (this.mode === "normal" && matchesKey(data, this.keymap.lineYank)) {
      this.startYank(this.linewiseSelection(this.cursor), false);
      return;
    }

    if (this.mode === "normal" && matchesKey(data, this.keymap.yank)) {
      this.pendingYank = { kind: "operator" };
      this.tui.requestRender();
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

    if (
      this.mode === "visual" &&
      matchesKey(data, this.keymap.visualSwapCursor)
    ) {
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
    this.ensureRenderedDocument(this.markdownWidth(innerWidth));
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
        row.kind === "source" && row.line === -1
          ? ""
          : row.kind === "source"
            ? ` ${row.content}`
            : row.content;
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
    const searchStatus = this.renderSearchStatus(innerWidth);
    if (searchStatus !== null)
      lines.push(this.frameLine(searchStatus, innerWidth));
    lines.push(this.bottomBorder(innerWidth));
    return lines;
  }

  invalidate(): void {
    this.renderedWidth = null;
    this.tui.requestRender();
  }

  dispose(): void {
    this.disposed = true;
    this.yankSessionId++;
    this.clearYankHighlight();
    this.commentInput = null;
  }

  private restart(): void {
    const refreshedSource = this.onRefresh
      ? this.onRefresh()
      : this.rawSourceText;
    if (refreshedSource === null) {
      this.done({ action: "cancel" });
      return;
    }

    this.rawSourceText = refreshedSource;
    this.document = createSourceDocument(refreshedSource);
    this.renderedLines = [];
    this.renderedWidth = null;
    this.annotations.length = 0;
    this.nextAnnotationId = 1;
    this.cursor = { line: 0, grapheme: 0 };
    this.preferredColumn = null;
    this.mode = "normal";
    this.visualAnchor = null;
    this.commentInput = null;
    this.searchInput = null;
    this.search = null;
    this.pendingG = false;
    this.pendingCharMotion = null;
    this.pendingYank = null;
    this.lastCharMotion = null;
    this.clearYankHighlight();
    this.yankSessionId++;
    this.scrollTop = 0;
    this.ensureRenderedDocument(this.markdownWidth(this.lastInnerWidth));
    this.tui.requestRender();
  }

  private getViewportHeight(): number {
    const terminalRows = this.tui.terminal.rows;
    const frameRows = Math.floor(terminalRows * 0.85);
    const fixedRows =
      2 +
      (this.commentInput ? 1 : 0) +
      (this.renderSearchStatus(this.lastInnerWidth) !== null ? 1 : 0);
    return Math.max(1, frameRows - fixedRows);
  }

  private handleSearchInput(data: string): void {
    const searchInput = this.searchInput;
    if (!searchInput) return;

    const before = searchInput.input.getValue();
    searchInput.input.handleInput(encodePastedNewlines(data));
    if (!this.searchInput) return;

    const query = searchInput.input.getValue();
    if (query.length === 0) {
      this.restoreSearchSnapshot(searchInput.before);
    } else if (query !== before) {
      this.updateLiveSearch(query);
    }
    this.tui.requestRender();
  }

  private beginSearch(direction: SearchDirection, prefix: "/" | "?"): void {
    const input = new Input();
    input.focused = this.focused;
    const searchInput: SearchInputState = {
      input,
      direction,
      prefix,
      before: this.createSearchSnapshot(),
    };
    input.onSubmit = (query) => {
      if (query.length === 0) {
        this.clearSearch();
        return;
      }
      this.updateLiveSearch(query);
      this.searchInput = null;
      this.tui.requestRender();
    };
    input.onEscape = () => this.cancelSearch();
    this.searchInput = searchInput;
    this.tui.requestRender();
  }

  private cancelSearch(): void {
    const searchInput = this.searchInput;
    if (!searchInput) return;
    this.searchInput = null;
    this.restoreSearchSnapshot(searchInput.before);
    this.tui.requestRender();
  }

  private clearSearch(): void {
    this.searchInput = null;
    this.search = null;
    this.tui.requestRender();
  }

  private updateLiveSearch(query: string): void {
    const searchInput = this.searchInput;
    if (!searchInput) return;

    const decodedQuery = decodeSearchQuery(query);
    const matches = findLiteralSearchMatches(this.document.text, decodedQuery);
    const currentIndex = this.findSearchMatchIndex(
      matches,
      searchInput.direction,
      cursorOffset(this.document, searchInput.before.cursor),
      true,
    );
    this.search = {
      query,
      prefix: searchInput.prefix,
      direction: searchInput.direction,
      kind: "literal",
      matches,
      currentIndex,
    };
    if (currentIndex >= 0) this.moveToSearchMatch(matches[currentIndex]!);
  }

  private repeatSearch(direction: "same" | "opposite"): void {
    if (!this.search || this.search.matches.length === 0) return;

    const searchDirection =
      direction === "same"
        ? this.search.direction
        : this.search.direction === "forward"
          ? "backward"
          : "forward";
    const currentIndex = this.findSearchMatchIndex(
      this.search.matches,
      searchDirection,
      cursorOffset(this.document, this.cursor),
      false,
    );
    if (currentIndex < 0) return;

    this.search.currentIndex = currentIndex;
    this.moveToSearchMatch(this.search.matches[currentIndex]!);
  }

  private searchWord(direction: SearchDirection): void {
    const keyword = findKeywordAtCursor(this.document, this.cursor);
    if (keyword === null) return;

    const matches = findKeywordSearchMatches(this.document, keyword);
    const currentIndex = matches.findIndex((match) =>
      searchMatchContainsCursor(this.document, match, this.cursor),
    );
    if (currentIndex < 0) return;

    this.search = {
      query: keyword,
      prefix: direction === "forward" ? "/" : "?",
      direction,
      kind: "word",
      matches,
      currentIndex,
    };
    this.moveToSearchMatch(matches[currentIndex]!);
    this.tui.requestRender();
  }

  private findSearchMatchIndex(
    matches: readonly SearchMatch[],
    direction: SearchDirection,
    offset: number,
    includeCurrent: boolean,
  ): number {
    if (matches.length === 0) return -1;

    if (includeCurrent) {
      const currentIndex = matches.findIndex(
        (match) => match.start <= offset && offset < match.end,
      );
      if (currentIndex >= 0) return currentIndex;
    }

    if (direction === "forward") {
      const comparison = includeCurrent
        ? (match: SearchMatch) => match.start >= offset
        : (match: SearchMatch) => match.start > offset;
      const nextIndex = matches.findIndex(comparison);
      return nextIndex >= 0 ? nextIndex : 0;
    }

    const comparison = includeCurrent
      ? (match: SearchMatch) => match.start <= offset
      : (match: SearchMatch) => match.start < offset;
    for (let index = matches.length - 1; index >= 0; index--) {
      if (comparison(matches[index]!)) return index;
    }
    return matches.length - 1;
  }

  private moveToSearchMatch(match: SearchMatch): void {
    this.cursor = cursorPositionAtSearchMatch(this.document, match);
    this.preferredColumn = null;
  }

  private createSearchSnapshot(): SearchSnapshot {
    return {
      cursor: { ...this.cursor },
      preferredColumn: this.preferredColumn,
      mode: this.mode,
      visualAnchor: this.visualAnchor ? { ...this.visualAnchor } : null,
      search: this.cloneSearch(this.search),
    };
  }

  private restoreSearchSnapshot(snapshot: SearchSnapshot): void {
    this.cursor = { ...snapshot.cursor };
    this.preferredColumn = snapshot.preferredColumn;
    this.mode = snapshot.mode;
    this.visualAnchor = snapshot.visualAnchor
      ? { ...snapshot.visualAnchor }
      : null;
    this.search = this.cloneSearch(snapshot.search);
  }

  private cloneSearch(search: SearchState | null): SearchState | null {
    return search
      ? { ...search, matches: search.matches.map((match) => ({ ...match })) }
      : null;
  }

  private renderSearchStatus(width: number): string | null {
    const searchInput = this.searchInput;
    if (searchInput) {
      const query = searchInput.input.getValue();
      const prefix = searchInput.prefix;
      if (query.length === 0) {
        const renderedInput =
          searchInput.input.render(Math.max(3, width - prefix.length))[0] ?? "";
        return `${prefix}${stripInputPrompt(renderedInput)}`;
      }

      const search = this.search;
      if (!search) return null;
      const index =
        search.currentIndex < 0 ? "-" : String(search.currentIndex + 1);
      const count = `[${index}/${search.matches.length}]`;
      const queryWidth = Math.max(1, width - prefix.length - count.length - 1);
      const renderedInput = searchInput.input.render(queryWidth + 2)[0] ?? "";
      const renderedQuery = stripInputPrompt(renderedInput).replace(/ +$/u, "");
      return `${prefix}${renderedQuery}${count}`;
    }

    if (!this.search) return null;
    const index =
      this.search.currentIndex < 0 ? "-" : String(this.search.currentIndex + 1);
    return `${this.search.prefix}${this.search.query} [${index}/${this.search.matches.length}]`;
  }

  private handlePendingYank(data: string): void {
    const pending = this.pendingYank;
    if (!pending) return;

    if (matchesKey(data, this.keymap.escape)) {
      this.pendingYank = null;
      this.tui.requestRender();
      return;
    }

    if (pending.kind === "operator") {
      if (matchesKey(data, this.keymap.yank)) {
        this.pendingYank = null;
        this.startYank(this.linewiseSelection(this.cursor), false);
        return;
      }
      if (matchesKey(data, this.keymap.lineMotionPrefix)) {
        this.pendingYank = { kind: "g" };
        this.tui.requestRender();
        return;
      }
      if (data === "i" || data === "a") {
        this.pendingYank = { kind: "text-object", outer: data === "a" };
        this.tui.requestRender();
        return;
      }

      const charMotion = this.getCharMotion(data);
      if (charMotion) {
        this.pendingYank = { kind: "char", motion: charMotion };
        this.tui.requestRender();
        return;
      }

      this.pendingYank = null;
      const selection = this.selectionForYankMotion(data);
      if (selection !== undefined) {
        this.startYank(selection, false);
        return;
      }

      // A non-motion key cancels the sequence, then starts its own command.
      this.handleInput(data);
      return;
    }

    if (pending.kind === "g") {
      this.pendingYank = null;
      if (matchesKey(data, this.keymap.lineMotionPrefix)) {
        this.startYank(
          this.linewiseSelection(
            this.previewMotion(() => {
              this.moveToLine(0);
            }),
          ),
          false,
        );
        return;
      }
      if (matchesKey(data, this.keymap.down)) {
        const destination = this.previewMotion(() => {
          this.moveDisplayRow(1);
        });
        this.startYank(
          sameCursor(this.cursor, destination)
            ? null
            : this.characterwiseSelection(this.cursor, destination),
          false,
        );
        return;
      }
      if (matchesKey(data, this.keymap.up)) {
        const destination = this.previewMotion(() => {
          this.moveDisplayRow(-1);
        });
        this.startYank(
          sameCursor(this.cursor, destination)
            ? null
            : this.characterwiseSelection(this.cursor, destination),
          false,
        );
        return;
      }

      this.handleInput(data);
      return;
    }

    if (pending.kind === "char") {
      this.pendingYank = null;
      if (!isPrintableAscii(data)) {
        this.tui.requestRender();
        return;
      }

      const target = findCharMotionTarget(
        this.currentLineGraphemes(),
        this.cursor.grapheme,
        pending.motion,
        data,
      );
      if (target === null) {
        this.tui.requestRender();
        return;
      }

      this.startYank(
        this.characterwiseSelection(this.cursor, {
          line: this.cursor.line,
          grapheme: target,
        }),
        false,
        () => {
          this.lastCharMotion = { motion: pending.motion, char: data };
        },
      );
      return;
    }

    this.pendingYank = null;
    if (!matchesKey(data, this.keymap.wordForward)) {
      this.handleInput(data);
      return;
    }

    this.startYank(this.wordObjectSelection(pending.outer), false);
  }

  private selectionForYankMotion(
    data: string,
  ): SelectionRange | null | undefined {
    if (matchesKey(data, this.keymap.left)) {
      if (this.cursor.grapheme === 0) return null;
      const previous = {
        line: this.cursor.line,
        grapheme: this.cursor.grapheme - 1,
      };
      return this.graphemeSelection(previous);
    }
    if (matchesKey(data, this.keymap.right)) {
      return this.graphemeSelection(this.cursor);
    }
    if (matchesKey(data, this.keymap.down)) {
      const destination = this.previewMotion(() => this.moveVertical(1));
      return sameCursor(this.cursor, destination)
        ? null
        : this.linewiseSelection(destination);
    }
    if (matchesKey(data, this.keymap.up)) {
      const destination = this.previewMotion(() => this.moveVertical(-1));
      return sameCursor(this.cursor, destination)
        ? null
        : this.linewiseSelection(destination);
    }
    if (matchesKey(data, this.keymap.lastLine)) {
      return this.linewiseSelection(
        this.previewMotion(() =>
          this.moveToLine(this.document.lines.length - 1),
        ),
      );
    }
    if (matchesKey(data, this.keymap.wordForward)) {
      return this.wordMotionSelection("forward", "start");
    }
    if (matchesKey(data, this.keymap.wordBackward)) {
      return this.wordMotionSelection("backward", "start");
    }
    if (matchesKey(data, this.keymap.wordEnd)) {
      return this.wordMotionSelection("forward", "end");
    }
    if (matchesKey(data, this.keymap.lineStart)) {
      const target = this.previewMotion(() => this.moveToColumn(0));
      return this.backwardSelection(target, this.cursor);
    }
    if (matchesKey(data, this.keymap.firstNonBlank)) {
      return this.linewiseSelection(this.cursor);
    }
    if (matchesKey(data, this.keymap.lineEnd)) {
      return this.characterwiseSelection(
        this.cursor,
        this.previewMotion(() =>
          this.moveToColumn(this.currentLineGraphemes().length - 1),
        ),
      );
    }

    return undefined;
  }

  private wordMotionSelection(
    direction: "forward" | "backward",
    target: "start" | "end",
  ): SelectionRange | null {
    const start = { ...this.cursor };
    const destination = this.previewMotion(() =>
      this.moveWord(direction, target),
    );
    const startOffset = cursorOffset(this.document, start);
    const destinationOffset = cursorOffset(this.document, destination);

    if (target === "start" && direction === "backward") {
      return this.selectionFromOffsets(destinationOffset, startOffset);
    }
    if (target === "start") {
      const end =
        !sameCursor(start, destination) &&
        isWordStart(this.document, destination)
          ? destinationOffset
          : graphemeEndOffset(this.document, destination);
      return this.selectionFromOffsets(startOffset, end);
    }

    return this.selectionFromOffsets(
      startOffset,
      graphemeEndOffset(this.document, destination),
    );
  }

  private wordObjectSelection(outer: boolean): SelectionRange | null {
    const line = this.document.lines[this.cursor.line];
    if (!line || line.graphemes.length === 0) return null;

    const kind = wordKind(line.graphemes[this.cursor.grapheme]!.text);
    let start = this.cursor.grapheme;
    let end = this.cursor.grapheme + 1;
    while (start > 0 && wordKind(line.graphemes[start - 1]!.text) === kind)
      start--;
    while (
      end < line.graphemes.length &&
      wordKind(line.graphemes[end]!.text) === kind
    )
      end++;

    let startOffset = line.start + line.graphemes[start]!.start;
    let endOffset = line.start + line.graphemes[end - 1]!.end;

    if (outer && kind !== "whitespace") {
      if (
        end < line.graphemes.length &&
        wordKind(line.graphemes[end]!.text) === "whitespace"
      ) {
        while (
          end < line.graphemes.length &&
          wordKind(line.graphemes[end]!.text) === "whitespace"
        )
          end++;
        endOffset = line.start + line.graphemes[end - 1]!.end;
      } else {
        while (
          start > 0 &&
          wordKind(line.graphemes[start - 1]!.text) === "whitespace"
        )
          start--;
        startOffset = line.start + line.graphemes[start]!.start;
      }
    } else if (outer && kind === "whitespace") {
      const hasFollowingUnit = end < line.graphemes.length;
      while (
        end < line.graphemes.length &&
        wordKind(line.graphemes[end]!.text) !== "whitespace"
      )
        end++;
      if (hasFollowingUnit) {
        endOffset = line.start + line.graphemes[end - 1]!.end;
      } else {
        const nextWord = this.firstNonWhitespaceUnit(this.cursor.line + 1);
        if (nextWord) endOffset = graphemeEndOffset(this.document, nextWord);
      }
    }

    return this.selectionFromOffsets(startOffset, endOffset);
  }

  private firstNonWhitespaceUnit(startLine: number): CursorPosition | null {
    for (
      let lineIndex = startLine;
      lineIndex < this.document.lines.length;
      lineIndex++
    ) {
      const line = this.document.lines[lineIndex]!;
      const grapheme = line.graphemes.findIndex(
        (candidate) => wordKind(candidate.text) !== "whitespace",
      );
      if (grapheme >= 0) return { line: lineIndex, grapheme };
    }
    return null;
  }

  private previewMotion(move: () => void): CursorPosition {
    const previousCursor = { ...this.cursor };
    const previousPreferredColumn = this.preferredColumn;
    move();
    const destination = { ...this.cursor };
    this.cursor = previousCursor;
    this.preferredColumn = previousPreferredColumn;
    return destination;
  }

  private linewiseSelection(
    destination: CursorPosition,
  ): SelectionRange | null {
    return getSelectionRange(this.document, this.cursor, destination, "line");
  }

  private characterwiseSelection(
    start: CursorPosition,
    destination: CursorPosition,
  ): SelectionRange | null {
    return getSelectionRange(this.document, start, destination, "character");
  }

  private backwardSelection(
    destination: CursorPosition,
    current: CursorPosition,
  ): SelectionRange | null {
    return this.selectionFromOffsets(
      cursorOffset(this.document, destination),
      cursorOffset(this.document, current),
    );
  }

  private graphemeSelection(position: CursorPosition): SelectionRange | null {
    const line = this.document.lines[position.line];
    const grapheme = line?.graphemes[position.grapheme];
    if (!line || !grapheme) return null;
    return this.selectionFromOffsets(
      line.start + grapheme.start,
      line.start + grapheme.end,
    );
  }

  private selectionFromOffsets(
    start: number,
    end: number,
  ): SelectionRange | null {
    if (end <= start) return null;
    return { start, end, text: this.document.text.slice(start, end) };
  }

  private yankVisualSelection(): void {
    if (!this.visualAnchor) return;
    const selection = getSelectionRange(
      this.document,
      this.visualAnchor,
      this.cursor,
      this.visualMode,
    );
    if (!selection || selection.start === selection.end) return;
    this.startYank(selection, true);
  }

  private startYank(
    selection: SelectionRange | null,
    startedVisual: boolean,
    onSuccess?: () => void,
  ): void {
    if (!selection || selection.start === selection.end) return;

    const operationId = ++this.yankOperationId;
    const sessionId = this.yankSessionId;
    const text = normalizePlatformLineEndings(selection.text);

    void Promise.resolve()
      .then(() => this.onYank?.(text))
      .then(
        () => {
          if (this.disposed || sessionId !== this.yankSessionId) return;
          onSuccess?.();
          if (startedVisual) this.exitVisual();
          if (operationId >= this.latestSuccessfulYankId) {
            this.latestSuccessfulYankId = operationId;
            this.showYankHighlight(selection);
          }
          this.tui.requestRender();
        },
        (error: unknown) => {
          if (this.disposed || sessionId !== this.yankSessionId) return;
          if (operationId >= this.latestSuccessfulYankId)
            this.clearYankHighlight();
          if (startedVisual) this.exitVisual();
          this.onYankError?.(error);
          this.tui.requestRender();
        },
      );
  }

  private showYankHighlight(selection: SelectionRange): void {
    this.clearYankHighlight();
    this.yankHighlight = { ...selection };
    const generation = this.yankHighlightGeneration;
    this.yankHighlightTimer = setTimeout(() => {
      if (this.disposed || generation !== this.yankHighlightGeneration) return;
      this.yankHighlight = null;
      this.yankHighlightTimer = null;
      this.tui.requestRender();
    }, 500);
  }

  private clearYankHighlight(): void {
    this.yankHighlightGeneration++;
    if (this.yankHighlightTimer !== null) {
      clearTimeout(this.yankHighlightTimer);
      this.yankHighlightTimer = null;
    }
    this.yankHighlight = null;
  }

  private handlePendingG(data: string): void {
    this.pendingG = false;
    if (matchesKey(data, this.keymap.escape)) {
      this.tui.requestRender();
      return;
    }

    if (matchesKey(data, this.keymap.lineMotionPrefix)) {
      this.moveToLine(0);
      this.tui.requestRender();
      return;
    }

    if (matchesKey(data, this.keymap.down)) {
      this.moveDisplayRow(1);
      this.tui.requestRender();
      return;
    }

    if (matchesKey(data, this.keymap.up)) {
      this.moveDisplayRow(-1);
      this.tui.requestRender();
      return;
    }

    // A non-g key cancels the sequence, then starts its own normal command.
    this.handleInput(data);
  }

  private handlePendingCharMotion(data: string): void {
    const motion = this.pendingCharMotion;
    this.pendingCharMotion = null;
    if (
      !motion ||
      matchesKey(data, this.keymap.escape) ||
      !isPrintableAscii(data)
    ) {
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
    else if (matchesKey(data, this.keymap.lineMotionPrefix))
      this.pendingG = true;
    else if (matchesKey(data, this.keymap.lastLine))
      this.moveToLine(this.document.lines.length - 1);
    else if (matchesKey(data, this.keymap.wordForward))
      this.moveWord("forward", "start");
    else if (matchesKey(data, this.keymap.wordBackward))
      this.moveWord("backward", "start");
    else if (matchesKey(data, this.keymap.wordEnd))
      this.moveWord("forward", "end");
    else if (matchesKey(data, this.keymap.searchNext))
      this.repeatSearch("same");
    else if (matchesKey(data, this.keymap.searchPrevious))
      this.repeatSearch("opposite");
    else if (matchesKey(data, this.keymap.lineStart)) this.moveToColumn(0);
    else if (matchesKey(data, this.keymap.firstNonBlank))
      this.moveToColumn(firstNonBlankColumn(this.currentLineGraphemes()));
    else if (matchesKey(data, this.keymap.lineEnd))
      this.moveToColumn(this.currentLineGraphemes().length - 1);
    else {
      const charMotion = this.getCharMotion(data);
      if (charMotion) this.pendingCharMotion = charMotion;
      else if (
        matchesKey(data, this.keymap.repeatForward) ||
        matchesKey(data, this.keymap.repeatBackward)
      ) {
        if (!this.lastCharMotion) return false;
        const motion = matchesKey(data, this.keymap.repeatForward)
          ? this.lastCharMotion.motion
          : reverseCharMotion(this.lastCharMotion.motion);
        this.executeCharMotion(motion, this.lastCharMotion.char, false);
      } else return false;
    }

    this.tui.requestRender();
    return true;
  }

  private getCharMotion(data: string): CharMotion | null {
    if (matchesKey(data, this.keymap.findForward)) return "f";
    if (matchesKey(data, this.keymap.findBackward)) return "F";
    if (matchesKey(data, this.keymap.tillForward)) return "t";
    if (matchesKey(data, this.keymap.tillBackward)) return "T";
    return null;
  }

  private moveHorizontal(direction: -1 | 1): void {
    this.preferredColumn = null;
    const line = this.document.lines[this.cursor.line]!;
    const next = this.cursor.grapheme + direction;
    if (next >= 0 && next < line.graphemes.length) {
      this.cursor.grapheme = next;
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

  private moveDisplayRow(direction: -1 | 1): void {
    const renderer = this.createRenderer();
    const sourceRows = renderer
      .buildDisplayRows(this.lastInnerWidth)
      .filter(
        (row): row is Extract<DisplayRow, { kind: "source" }> =>
          row.kind === "source",
      );
    const currentRowIndex = sourceRows.findIndex(
      (row) =>
        row.line === this.cursor.line &&
        (row.startGrapheme === row.endGrapheme
          ? this.cursor.grapheme === 0
          : this.cursor.grapheme >= row.startGrapheme &&
            this.cursor.grapheme < row.endGrapheme),
    );
    if (currentRowIndex < 0) return;

    const targetRowIndex = Math.max(
      0,
      Math.min(sourceRows.length - 1, currentRowIndex + direction),
    );
    if (targetRowIndex === currentRowIndex) return;

    const currentRow = sourceRows[currentRowIndex]!;
    const targetRow = sourceRows[targetRowIndex]!;
    const currentLine = this.document.lines[this.cursor.line]!;
    const currentColumn = displayRowColumn(
      currentLine,
      currentRow,
      this.cursor.grapheme,
    );
    const targetColumn = this.preferredColumn ?? currentColumn;
    const targetLine = this.document.lines[targetRow.line]!;

    this.cursor = {
      line: targetRow.line,
      grapheme: graphemeAtOrBeforeDisplayColumn(
        targetLine,
        targetRow,
        targetColumn,
      ),
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

  private openCommentInput(annotation: Annotation | null = null): void {
    const selection = annotation
      ? annotation
      : this.visualAnchor
        ? getSelectionRange(
            this.document,
            this.visualAnchor,
            this.cursor,
            this.visualMode,
          )
        : null;
    if (!selection || selection.start === selection.end) {
      if (!annotation) this.exitVisual();
      this.tui.requestRender();
      return;
    }

    const input = new Input();
    input.focused = this.focused;
    if (annotation) {
      input.setValue(annotation.comment);
      input.handleInput("\x05");
    }
    input.onSubmit = (comment) => {
      if (comment.trim().length === 0) {
        this.commentInput = null;
        this.mode = annotation ? "normal" : "visual";
        this.tui.requestRender();
        return;
      }

      if (annotation) {
        annotation.comment = comment;
      } else {
        this.annotations.push({
          id: this.nextAnnotationId++,
          start: selection.start,
          end: selection.end,
          text: selection.text,
          comment,
        });
      }
      this.commentInput = null;
      if (annotation) this.mode = "normal";
      else this.exitVisual();
      this.tui.requestRender();
    };
    input.onEscape = () => {
      this.commentInput = null;
      this.mode = annotation ? "normal" : "visual";
      this.tui.requestRender();
    };
    this.commentInput = { input };
    this.tui.requestRender();
  }

  private findAnnotationAtCursor(): Annotation | null {
    const line = this.document.lines[this.cursor.line];
    const grapheme = line?.graphemes[this.cursor.grapheme];
    if (!line || !grapheme) return null;

    const start = line.start + grapheme.start;
    const end = line.start + grapheme.end;
    for (let index = this.annotations.length - 1; index >= 0; index--) {
      const annotation = this.annotations[index]!;
      if (selectionContainsOffset(annotation, start, end)) return annotation;
    }
    return null;
  }

  private markdownWidth(innerWidth: number): number {
    return Math.max(3, innerWidth);
  }

  private ensureRenderedDocument(width: number): void {
    if (this.renderedWidth === width) return;

    const previousDocument = this.document;
    const snapshot = this.captureDisplayState(previousDocument);
    const rendered = renderMarkdownDocument(this.rawSourceText, width);
    this.document = rendered.document;
    this.renderedLines = rendered.renderedLines;
    this.renderedWidth = width;
    this.restoreDisplayState(snapshot);
  }

  private captureDisplayState(document: SourceDocument): DisplayStateSnapshot {
    return {
      cursorOrdinal: visibleGraphemeOrdinal(
        document,
        cursorOffset(document, this.cursor),
      ),
      preferredColumn: this.preferredColumn,
      mode: this.mode,
      visualAnchorOrdinal: this.visualAnchor
        ? visibleGraphemeOrdinal(
            document,
            cursorOffset(document, this.visualAnchor),
          )
        : null,
      annotations: this.annotations.map((annotation) => ({
        annotation,
        startOrdinal: visibleGraphemeOrdinal(document, annotation.start),
        endOrdinal: visibleGraphemeOrdinal(document, annotation.end),
      })),
      search: this.captureSearchState(document, this.search),
      searchInputBefore: this.searchInput
        ? this.captureSearchSnapshot(document, this.searchInput.before)
        : null,
      yankHighlight: this.yankHighlight
        ? {
            startOrdinal: visibleGraphemeOrdinal(
              document,
              this.yankHighlight.start,
            ),
            endOrdinal: visibleGraphemeOrdinal(
              document,
              this.yankHighlight.end,
            ),
          }
        : null,
    };
  }

  private restoreDisplayState(snapshot: DisplayStateSnapshot): void {
    this.cursor = cursorAtVisibleOrdinal(this.document, snapshot.cursorOrdinal);
    this.preferredColumn = snapshot.preferredColumn;
    this.mode = snapshot.mode;
    this.visualAnchor =
      snapshot.visualAnchorOrdinal === null
        ? null
        : cursorAtVisibleOrdinal(this.document, snapshot.visualAnchorOrdinal);
    this.yankHighlight = snapshot.yankHighlight
      ? this.selectionFromOffsets(
          boundaryOffsetAtVisibleOrdinal(
            this.document,
            snapshot.yankHighlight.startOrdinal,
          ),
          endOffsetAtVisibleOrdinal(
            this.document,
            snapshot.yankHighlight.endOrdinal,
          ),
        )
      : null;

    for (const annotationState of snapshot.annotations) {
      const annotation = annotationState.annotation;
      annotation.start = boundaryOffsetAtVisibleOrdinal(
        this.document,
        annotationState.startOrdinal,
      );
      annotation.end = boundaryOffsetAtVisibleOrdinal(
        this.document,
        annotationState.endOrdinal,
      );
      annotation.text = this.document.text.slice(
        annotation.start,
        annotation.end,
      );
    }

    this.search = this.restoreSearchState(snapshot.search);
    if (this.searchInput && snapshot.searchInputBefore) {
      this.searchInput.before = this.restoreDisplaySearchSnapshot(
        snapshot.searchInputBefore,
      );
    }
  }

  private captureSearchState(
    document: SourceDocument,
    search: SearchState | null,
  ): SearchStateSnapshot | null {
    if (!search) return null;

    return {
      query: search.query,
      prefix: search.prefix,
      direction: search.direction,
      kind: search.kind,
      matchOrdinals: search.matches.map((match) =>
        visibleGraphemeOrdinal(document, match.start),
      ),
      currentMatchOrdinal:
        search.currentIndex >= 0
          ? visibleGraphemeOrdinal(
              document,
              search.matches[search.currentIndex]!.start,
            )
          : null,
    };
  }

  private captureSearchSnapshot(
    document: SourceDocument,
    snapshot: SearchSnapshot,
  ): NonNullable<DisplayStateSnapshot["searchInputBefore"]> {
    return {
      cursorOrdinal: visibleGraphemeOrdinal(
        document,
        cursorOffset(document, snapshot.cursor),
      ),
      preferredColumn: snapshot.preferredColumn,
      mode: snapshot.mode,
      visualAnchorOrdinal: snapshot.visualAnchor
        ? visibleGraphemeOrdinal(
            document,
            cursorOffset(document, snapshot.visualAnchor),
          )
        : null,
      search: this.captureSearchState(document, snapshot.search),
    };
  }

  private restoreSearchState(
    snapshot: SearchStateSnapshot | null,
  ): SearchState | null {
    if (!snapshot) return null;

    const allMatches =
      snapshot.kind === "word"
        ? findKeywordSearchMatches(this.document, snapshot.query)
        : findLiteralSearchMatches(
            this.document.text,
            decodeSearchQuery(snapshot.query),
          );
    const matches = snapshot.matchOrdinals
      .map((ordinal) =>
        allMatches.find(
          (match) =>
            visibleGraphemeOrdinal(this.document, match.start) === ordinal,
        ),
      )
      .filter((match): match is SearchMatch => match !== undefined);
    const currentIndex =
      snapshot.currentMatchOrdinal === null
        ? -1
        : matches.findIndex(
            (match) =>
              visibleGraphemeOrdinal(this.document, match.start) ===
              snapshot.currentMatchOrdinal,
          );

    return {
      query: snapshot.query,
      prefix: snapshot.prefix,
      direction: snapshot.direction,
      kind: snapshot.kind,
      matches,
      currentIndex,
    };
  }

  private restoreDisplaySearchSnapshot(
    snapshot: NonNullable<DisplayStateSnapshot["searchInputBefore"]>,
  ): SearchSnapshot {
    return {
      cursor: cursorAtVisibleOrdinal(this.document, snapshot.cursorOrdinal),
      preferredColumn: snapshot.preferredColumn,
      mode: snapshot.mode,
      visualAnchor:
        snapshot.visualAnchorOrdinal === null
          ? null
          : cursorAtVisibleOrdinal(this.document, snapshot.visualAnchorOrdinal),
      search: this.restoreSearchState(snapshot.search),
    };
  }

  private createRenderer(): ReplyRenderer {
    return new ReplyRenderer(
      this.theme,
      this.document,
      this.annotations,
      {
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
        searchMatches: this.search?.matches ?? [],
        currentSearchMatch:
          this.search && this.search.currentIndex >= 0
            ? this.search.matches[this.search.currentIndex]!
            : null,
        yankHighlight: this.yankHighlight,
        hasCommentInput: this.commentInput !== null,
        focused: this.focused,
      },
      this.renderedLines,
    );
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

function visibleGraphemeOrdinal(
  document: SourceDocument,
  offset: number,
): number {
  const boundedOffset = Math.max(0, Math.min(offset, document.text.length));
  let ordinal = 0;

  for (const line of document.lines) {
    for (const grapheme of line.graphemes) {
      if (line.start + grapheme.start >= boundedOffset) return ordinal;
      ordinal++;
    }
  }

  return ordinal;
}

function boundaryOffsetAtVisibleOrdinal(
  document: SourceDocument,
  ordinal: number,
): number {
  const target = Math.max(0, ordinal);
  let current = 0;

  for (const line of document.lines) {
    for (const grapheme of line.graphemes) {
      if (current === target) return line.start + grapheme.start;
      current++;
    }
  }

  return document.text.length;
}

function endOffsetAtVisibleOrdinal(
  document: SourceDocument,
  ordinal: number,
): number {
  const target = Math.max(0, ordinal);
  let current = 0;
  let lastEnd = 0;

  for (const line of document.lines) {
    for (const grapheme of line.graphemes) {
      if (current === target) return lastEnd;
      lastEnd = line.start + grapheme.end;
      current++;
    }
  }

  return document.text.length;
}

function cursorAtVisibleOrdinal(
  document: SourceDocument,
  ordinal: number,
): CursorPosition {
  const target = Math.max(0, ordinal);
  let current = 0;
  let last: CursorPosition = { line: 0, grapheme: 0 };

  for (let lineIndex = 0; lineIndex < document.lines.length; lineIndex++) {
    const line = document.lines[lineIndex]!;
    for (
      let graphemeIndex = 0;
      graphemeIndex < line.graphemes.length;
      graphemeIndex++
    ) {
      last = { line: lineIndex, grapheme: graphemeIndex };
      if (current === target) return last;
      current++;
    }
  }

  return last;
}

function sameCursor(first: CursorPosition, second: CursorPosition): boolean {
  return first.line === second.line && first.grapheme === second.grapheme;
}

function graphemeEndOffset(
  document: SourceDocument,
  position: CursorPosition,
): number {
  const line = document.lines[position.line];
  const grapheme = line?.graphemes[position.grapheme];
  return line && grapheme
    ? line.start + grapheme.end
    : cursorOffset(document, position);
}

function isWordStart(
  document: SourceDocument,
  position: CursorPosition,
): boolean {
  const line = document.lines[position.line];
  const grapheme = line?.graphemes[position.grapheme];
  if (!line || !grapheme || wordKind(grapheme.text) === "whitespace")
    return false;
  if (position.grapheme === 0) return true;
  return (
    wordKind(line.graphemes[position.grapheme - 1]!.text) !==
    wordKind(grapheme.text)
  );
}

function wordKind(unit: string): "keyword" | "other" | "whitespace" {
  if (/^\s+$/u.test(unit)) return "whitespace";
  return /^[A-Za-z0-9_]$/.test(unit) ? "keyword" : "other";
}

function stripInputPrompt(renderedInput: string): string {
  return renderedInput.startsWith("> ")
    ? renderedInput.slice(2)
    : renderedInput;
}

function encodePastedNewlines(data: string): string {
  return data.replace(
    /\x1b\[200~([\s\S]*?)\x1b\[201~/g,
    (_match, content: string) =>
      `\x1b[200~${content.replace(/\r\n?|\n/g, "\\n")}\x1b[201~`,
  );
}
