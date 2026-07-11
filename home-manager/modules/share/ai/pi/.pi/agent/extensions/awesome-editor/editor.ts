/**
 * AwesomeEditor — CustomEditor subclass combining:
 *   - Vim modal editing (normal / insert modes)
 *   - Snippet trigger autocomplete ($date, $tdd, ?q, …)
 */

import {
  CustomEditor,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import {
  Key,
  matchesKey,
  parseKey,
  truncateToWidth,
  visibleWidth,
  type AutocompleteProvider,
  type EditorTheme,
  type TUI,
} from "@earendil-works/pi-tui";

import { withSnippets } from "./snippets.js";
import type { AwesomeEditorMode } from "./settings.js";
import { SNIPPETS, type SnippetDef } from "../snippet/snippets.js";
import {
  formatParsedSnippetExpansion,
  parseSnippetExpansion,
  type ParsedSnippetExpansion,
} from "../snippet/tabstops.js";
import {
  type Mode,
  type CharMotion,
  type PendingMotion,
  type PendingOperator,
  type PendingG,
  type LastCharMotion,
  NORMAL_KEYS,
  CHAR_MOTION_KEYS,
  ESC_LEFT,
  ESC_RIGHT,
  ESC_DELETE,
  CTRL_A,
  CTRL_E,
  CTRL_K,
  NEWLINE,
  ESC_UP,
  ESC_DOWN,
} from "./vim/types.js";
import {
  reverseCharMotion,
  findCharMotionTarget,
  findWordMotionTarget,
} from "./vim/motions.js";

/**
 * Normalize CSI-u extended sequences to legacy format for both Ctrl and Alt modifiers.
 * Examples:
 *   "\x1b[101;5u" (Ctrl+E) → "\x05"
 *   "\x1b[65;4u" (Alt+Shift+A) → "\x1bA"
 */
function normalizeExtendedSequences(data: string): string {
  const csiMatch = data.match(/^\x1b\[(\d+);(\d+)u$/);
  if (csiMatch) {
    const code = parseInt(csiMatch[1]!, 10);
    const modifiers = parseInt(csiMatch[2]!, 10);

    // Alt (3) or Alt+Shift (4)
    if (modifiers === 3 || modifiers === 4) {
      return `\x1b${String.fromCharCode(code)}`;
    }

    // Ctrl (5)
    if (modifiers === 5) {
      const ctrlCode = code & 0x1f;
      if (ctrlCode >= 1 && ctrlCode <= 31) {
        return String.fromCharCode(ctrlCode);
      }
    }
  }

  // Fallback: check if it's a ctrl+<key> pattern
  const key = parseKey(data);
  if (key) {
    const match = key.match(/^ctrl\+(.+)$/);
    if (match && match[1]!.length === 1) {
      const ctrlCode = match[1]!.charCodeAt(0) & 0x1f;
      if (ctrlCode >= 1 && ctrlCode <= 31) {
        return String.fromCharCode(ctrlCode);
      }
    }
  }

  return data;
}

interface PlaceholderRange {
  index: number;
  start: number;
  end: number;
}

interface PlaceholderSession {
  line: number;
  ranges: PlaceholderRange[];
  activeRangeIndex: number;
  finalStop: number;
  pendingReplacement: boolean;
}

interface PlaceholderSnapshot {
  session: PlaceholderSession;
  beforeLine: string;
  beforeLinesLength: number;
  beforeCursor: { line: number; col: number };
}

export class AwesomeEditor extends CustomEditor {
  private editorMode: AwesomeEditorMode;
  private viMode: Mode = "insert";
  private pendingMotion: PendingMotion = null;
  private pendingOperator: PendingOperator = null;
  private pendingG: PendingG = null;
  private lastCharMotion: LastCharMotion | null = null;
  private placeholderSession: PlaceholderSession | null = null;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    editorMode: AwesomeEditorMode = "vi",
  ) {
    super(tui, theme, keybindings);
    this.editorMode = editorMode;
  }

  // InteractiveMode calls this after construction with its CombinedAutocompleteProvider.
  // We wrap it to prepend snippet suggestions while preserving slash-commands + file paths.
  setAutocompleteProvider(base: AutocompleteProvider): void {
    super.setAutocompleteProvider(withSnippets(base));
  }

  handleInput(data: string): void {
    // Normalize CSI-u extended sequences for both Ctrl and Alt modifiers
    // so all downstream checks and readline passthrough use the expected bytes.
    data = normalizeExtendedSequences(data);

    if (this.editorMode === "emacs") {
      this.handleStandardInputMode(data);
      return;
    }

    if (matchesKey(data, "escape")) return this.handleEscape();

    if (this.viMode === "insert") {
      const placeholderInput = this.preparePlaceholderInput(data);
      if (placeholderInput.handled) {
        return;
      }

      // Ctrl-E in autocomplete mode: apply + expand snippet
      if (data === "\x05" && (this as any).autocompleteState) {
        this.applyAndExpandSnippet();
        return;
      }

      // Alt shortcuts for insert mode
      if (this.handleInsertModeShortcut(data)) {
        this.reconcilePlaceholderInput(placeholderInput.snapshot);
        return;
      }

      super.handleInput(data);

      // Auto-trigger snippet autocomplete as soon as "$" is typed.
      if (data === "$" && !(this as any).autocompleteState) {
        (this as any).tryTriggerAutocomplete();
      }

      this.reconcilePlaceholderInput(placeholderInput.snapshot);
      return;
    }

    if (this.pendingG) return this.handlePendingG(data);
    if (this.pendingMotion) return this.handlePendingMotion(data);
    if (this.pendingOperator === "d") return this.handlePendingDelete(data);
    if (this.pendingOperator === "c") return this.handlePendingChange(data);

    this.handleNormalMode(data);
  }

  private handleStandardInputMode(data: string): void {
    const placeholderInput = this.preparePlaceholderInput(data);
    if (placeholderInput.handled) {
      return;
    }

    if (data === "\x05" && (this as any).autocompleteState) {
      this.applyAndExpandSnippet();
      return;
    }

    super.handleInput(data);

    if (data === "$" && !(this as any).autocompleteState) {
      (this as any).tryTriggerAutocomplete();
    }

    this.reconcilePlaceholderInput(placeholderInput.snapshot);
  }

  // ─── Placeholder navigation ──────────────────────────────────────────────────

  private preparePlaceholderInput(data: string): {
    handled: boolean;
    snapshot: PlaceholderSnapshot | null;
  } {
    const session = this.placeholderSession;
    if (!session) {
      return { handled: false, snapshot: null };
    }

    if (matchesKey(data, "tab")) {
      this.advancePlaceholderSession();
      return { handled: true, snapshot: null };
    }

    const replacementText = this.getDirectPlaceholderText(data);
    if (session.pendingReplacement && replacementText !== null) {
      this.replacePendingPlaceholderWithText(replacementText);
      return { handled: true, snapshot: null };
    }

    return {
      handled: false,
      snapshot: this.capturePlaceholderSnapshot(),
    };
  }

  private getDirectPlaceholderText(data: string): string | null {
    if (matchesKey(data, "shift+space")) {
      return " ";
    }

    if (data.includes("\x1b") || data.includes("\n") || data.includes("\r")) {
      return null;
    }

    return [...data].every((character) => character.charCodeAt(0) >= 32)
      ? data
      : null;
  }

  private capturePlaceholderSnapshot(): PlaceholderSnapshot | null {
    const session = this.placeholderSession;
    if (!session) {
      return null;
    }

    const activeRange = session.ranges[session.activeRangeIndex];
    const cursor = this.getCursor();
    if (
      !activeRange ||
      cursor.line !== session.line ||
      cursor.col < activeRange.start ||
      cursor.col > activeRange.end
    ) {
      this.placeholderSession = null;
      return null;
    }

    const lines = this.getLines();

    return {
      session: {
        line: session.line,
        ranges: session.ranges.map((range) => ({ ...range })),
        activeRangeIndex: session.activeRangeIndex,
        finalStop: session.finalStop,
        pendingReplacement: session.pendingReplacement,
      },
      beforeLine: lines[session.line] ?? "",
      beforeLinesLength: lines.length,
      beforeCursor: cursor,
    };
  }

  private replacePendingPlaceholderWithText(text: string): void {
    const session = this.placeholderSession;
    const activeRange = session?.ranges[session.activeRangeIndex];
    if (!session || !activeRange) {
      this.placeholderSession = null;
      return;
    }

    const editor = this as any;
    const previousRange = { ...activeRange };
    const currentLine = editor.state.lines[session.line] ?? "";

    editor.exitHistoryBrowsing();
    editor.pushUndoSnapshot();
    editor.lastAction = "type-word";
    editor.state.lines[session.line] =
      currentLine.slice(0, previousRange.start) +
      text +
      currentLine.slice(previousRange.end);
    editor.state.cursorLine = session.line;
    editor.setCursorCol(previousRange.start + text.length);

    this.updatePlaceholderSessionAfterEdit(
      previousRange,
      text.length - (previousRange.end - previousRange.start),
    );
    session.pendingReplacement = false;

    if (editor.onChange) {
      editor.onChange(this.getText());
    }
  }

  private reconcilePlaceholderInput(
    snapshot: PlaceholderSnapshot | null,
  ): void {
    if (!snapshot || !this.placeholderSession) {
      return;
    }

    const session = this.placeholderSession;
    const currentCursor = this.getCursor();
    const lines = this.getLines();
    if (
      lines.length !== snapshot.beforeLinesLength ||
      currentCursor.line !== session.line
    ) {
      this.placeholderSession = null;
      return;
    }

    const currentLine = lines[session.line] ?? "";
    if (currentLine === snapshot.beforeLine) {
      if (currentCursor.col !== snapshot.beforeCursor.col) {
        this.placeholderSession = null;
      }
      return;
    }

    const previousRange =
      snapshot.session.ranges[snapshot.session.activeRangeIndex];
    if (
      !previousRange ||
      snapshot.beforeCursor.col < previousRange.start ||
      snapshot.beforeCursor.col > previousRange.end
    ) {
      this.placeholderSession = null;
      return;
    }

    const change = this.findSingleLineChange(snapshot.beforeLine, currentLine);
    if (
      !change ||
      change.beforeStart < previousRange.start ||
      change.beforeEnd > previousRange.end
    ) {
      this.placeholderSession = null;
      return;
    }

    const delta =
      change.afterEnd -
      change.afterStart -
      (change.beforeEnd - change.beforeStart);
    this.updatePlaceholderSessionAfterEdit(previousRange, delta);
    session.pendingReplacement = false;

    const activeRange = session.ranges[session.activeRangeIndex];
    if (
      !activeRange ||
      currentCursor.col < activeRange.start ||
      currentCursor.col > activeRange.end
    ) {
      this.placeholderSession = null;
    }
  }

  private findSingleLineChange(
    beforeLine: string,
    afterLine: string,
  ): {
    beforeStart: number;
    beforeEnd: number;
    afterStart: number;
    afterEnd: number;
  } | null {
    if (beforeLine === afterLine) {
      return null;
    }

    let prefixLength = 0;
    while (
      prefixLength < beforeLine.length &&
      prefixLength < afterLine.length &&
      beforeLine[prefixLength] === afterLine[prefixLength]
    ) {
      prefixLength += 1;
    }

    let suffixLength = 0;
    while (
      suffixLength < beforeLine.length - prefixLength &&
      suffixLength < afterLine.length - prefixLength &&
      beforeLine[beforeLine.length - 1 - suffixLength] ===
        afterLine[afterLine.length - 1 - suffixLength]
    ) {
      suffixLength += 1;
    }

    return {
      beforeStart: prefixLength,
      beforeEnd: beforeLine.length - suffixLength,
      afterStart: prefixLength,
      afterEnd: afterLine.length - suffixLength,
    };
  }

  private updatePlaceholderSessionAfterEdit(
    previousRange: PlaceholderRange,
    delta: number,
  ): void {
    const session = this.placeholderSession;
    const activeRange = session?.ranges[session.activeRangeIndex];
    if (!session || !activeRange) {
      this.placeholderSession = null;
      return;
    }

    activeRange.end = previousRange.end + delta;

    for (
      let rangeIndex = session.activeRangeIndex + 1;
      rangeIndex < session.ranges.length;
      rangeIndex += 1
    ) {
      session.ranges[rangeIndex]!.start += delta;
      session.ranges[rangeIndex]!.end += delta;
    }

    if (session.finalStop >= previousRange.end) {
      session.finalStop += delta;
    }
  }

  private advancePlaceholderSession(): void {
    const session = this.placeholderSession;
    if (!session) {
      return;
    }

    const nextRange = session.ranges[session.activeRangeIndex + 1];
    if (!nextRange) {
      this.setCursorPosition(session.line, session.finalStop);
      this.placeholderSession = null;
      return;
    }

    session.activeRangeIndex += 1;
    session.pendingReplacement = true;
    this.setCursorPosition(
      session.line,
      this.getPlaceholderCursorCol(nextRange),
    );
  }

  private getPlaceholderCursorCol(range: PlaceholderRange): number {
    return Math.min(range.end - 1, range.start + 1);
  }

  private setCursorPosition(line: number, col: number): void {
    const editor = this as any;
    editor.state.cursorLine = line;
    editor.setCursorCol(col);
  }

  // ─── Escape / mode transitions ───────────────────────────────────────────────

  private handleInsertModeShortcut(data: string): boolean {
    if (matchesKey(data, Key.shiftAlt("a")) || data === "\x1bA") {
      super.handleInput(CTRL_E);
      return true;
    }
    if (matchesKey(data, Key.shiftAlt("i")) || data === "\x1bI") {
      super.handleInput(CTRL_A);
      return true;
    }
    if (matchesKey(data, Key.alt("o")) || data === "\x1bo") {
      super.handleInput(CTRL_E);
      super.handleInput(NEWLINE);
      return true;
    }
    if (matchesKey(data, Key.shiftAlt("o")) || data === "\x1bO") {
      super.handleInput(CTRL_A);
      super.handleInput(NEWLINE);
      super.handleInput(ESC_UP);
      return true;
    }
    return false;
  }

  private handleEscape(): void {
    if (this.pendingMotion || this.pendingOperator) {
      this.pendingMotion = null;
      this.pendingOperator = null;
      return;
    }
    if (this.viMode === "insert") {
      this.viMode = "normal";
      this.placeholderSession = null;
    } else {
      super.handleInput("\x1b"); // pass through to abort agent
    }
  }

  // ─── Pending state handlers ──────────────────────────────────────────────────

  private handlePendingMotion(data: string): void {
    if (data.length === 1 && data.charCodeAt(0) >= 32) {
      if (this.pendingOperator === "d") {
        this.deleteWithCharMotion(this.pendingMotion!, data);
        this.pendingOperator = null;
      } else if (this.pendingOperator === "c") {
        this.deleteWithCharMotion(this.pendingMotion!, data);
        this.pendingOperator = null;
        this.viMode = "insert";
      } else {
        this.executeCharMotion(this.pendingMotion!, data);
      }
    }
    this.pendingMotion = null;
  }

  private handlePendingDelete(data: string): void {
    if (data === "d") {
      this.deleteLine();
      this.pendingOperator = null;
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as CharMotion;
      return;
    }

    // Unknown motion: cancel operator (vim behaviour)
    this.pendingOperator = null;
    this.deleteWithMotion(data);
  }

  private handlePendingChange(data: string): void {
    if (data === "c") {
      this.deleteLine();
      this.pendingOperator = null;
      this.viMode = "insert";
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as CharMotion;
      return;
    }

    // Unknown motion: cancel operator (vim behaviour)
    this.pendingOperator = null;
    if (this.deleteWithMotion(data)) {
      this.viMode = "insert";
    }
  }

  private handlePendingG(data: string): void {
    this.pendingG = null;
    // gg → jump to first line
    if (data === "g") this.moveToLine(0);
    // Any other key: cancel silently (vim behaviour)
  }

  // ─── Normal mode dispatch ────────────────────────────────────────────────────

  private handleNormalMode(data: string): void {
    if (data === "d") {
      this.pendingOperator = "d";
      return;
    }

    if (data === "c") {
      this.pendingOperator = "c";
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as CharMotion;
      return;
    }

    if (this.handleCharMotionRepeat(data)) return;
    if (this.handleGCommand(data)) return;
    if (this.handleWordMotion(data)) return;
    if (data in NORMAL_KEYS) {
      this.handleMappedKey(data);
      return;
    }

    // Swallow printable chars; pass control sequences through
    if (data.length === 1 && data.charCodeAt(0) >= 32) return;
    super.handleInput(data);
  }

  private handleCharMotionRepeat(data: string): boolean {
    if (!this.lastCharMotion) return false;

    if (data === ";") {
      this.executeCharMotion(
        this.lastCharMotion.motion,
        this.lastCharMotion.char,
        false,
      );
      return true;
    }

    if (data === ",") {
      this.executeCharMotion(
        reverseCharMotion(this.lastCharMotion.motion),
        this.lastCharMotion.char,
        false,
      );
      return true;
    }

    return false;
  }

  private handleGCommand(data: string): boolean {
    if (data === "g") {
      this.pendingG = "g";
      return true;
    }

    if (data === "G") {
      this.moveToLine(this.getLines().length - 1);
      return true;
    }

    return false;
  }

  private handleWordMotion(data: string): boolean {
    if (data === "w") {
      this.moveWord("forward", "start");
      return true;
    }

    if (data === "b") {
      this.moveWord("backward", "start");
      return true;
    }

    if (data === "e") {
      this.moveWord("forward", "end");
      return true;
    }

    return false;
  }

  private handleMappedKey(key: string): void {
    const enterInsertMode = () => {
      this.viMode = "insert";
    };

    switch (key) {
      case "i":
        enterInsertMode();
        break;
      case "a":
        enterInsertMode();
        super.handleInput(ESC_RIGHT);
        break;
      case "A":
        enterInsertMode();
        super.handleInput(CTRL_E);
        break;
      case "I":
        enterInsertMode();
        super.handleInput(CTRL_A);
        break;
      case "o":
        super.handleInput(CTRL_E);
        super.handleInput(NEWLINE);
        enterInsertMode();
        break;
      case "O":
        super.handleInput(CTRL_A);
        super.handleInput(NEWLINE);
        super.handleInput(ESC_UP);
        enterInsertMode();
        break;
      case "C":
        super.handleInput(CTRL_K);
        enterInsertMode();
        break;
      case "S":
        super.handleInput(CTRL_A);
        super.handleInput(CTRL_K);
        enterInsertMode();
        break;
      case "s":
        super.handleInput(ESC_DELETE);
        enterInsertMode();
        break;
      default: {
        const seq = NORMAL_KEYS[key];
        if (seq) super.handleInput(seq);
      }
    }
  }

  // ─── Motion execution ────────────────────────────────────────────────────────

  private executeCharMotion(
    motion: CharMotion,
    targetChar: string,
    saveMotion = true,
  ): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const targetCol = findCharMotionTarget(
      line,
      col,
      motion,
      targetChar,
      !saveMotion,
    );

    if (targetCol === null) return;

    if (saveMotion) {
      this.lastCharMotion = { motion, char: targetChar };
    }

    if (targetCol !== col) {
      this.moveCursorBy(targetCol - col);
    }
  }

  private moveCursorBy(delta: number): void {
    const seq = delta > 0 ? ESC_RIGHT : ESC_LEFT;
    for (let i = 0; i < Math.abs(delta); i++) super.handleInput(seq);
  }

  /** Move cursor to the start of the given line (0-indexed). */
  private moveToLine(targetLine: number): void {
    const currentLine = this.getCursor().line;
    const delta = targetLine - currentLine;
    const seq = delta > 0 ? ESC_DOWN : ESC_UP;
    for (let i = 0; i < Math.abs(delta); i++) super.handleInput(seq);
    // Move to start of line
    super.handleInput(CTRL_A);
  }

  private moveWord(
    direction: "forward" | "backward",
    target: "start" | "end",
  ): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const targetCol = findWordMotionTarget(line, col, direction, target);
    if (targetCol !== col) this.moveCursorBy(targetCol - col);
  }

  // ─── Delete helpers ──────────────────────────────────────────────────────────

  private deleteLine(): void {
    super.handleInput(CTRL_A);
    super.handleInput(CTRL_K);
  }

  private deleteWithMotion(motion: string): boolean {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    let targetCol: number | null = null;
    let inclusive = false;

    switch (motion) {
      case "w":
        targetCol = findWordMotionTarget(line, col, "forward", "start");
        break;
      case "e":
        targetCol = findWordMotionTarget(line, col, "forward", "end");
        inclusive = true;
        break;
      case "b":
        targetCol = findWordMotionTarget(line, col, "backward", "start");
        break;
      case "$":
        targetCol = line.length;
        break;
      case "0":
        targetCol = 0;
        break;
      default:
        return false;
    }
    this.deleteRange(col, targetCol, inclusive);
    return true;
  }

  private deleteWithCharMotion(motion: CharMotion, targetChar: string): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const targetCol = findCharMotionTarget(line, col, motion, targetChar);
    if (targetCol === null) return;
    this.lastCharMotion = { motion, char: targetChar };
    this.deleteRange(col, targetCol, true);
  }

  private deleteRange(
    col: number,
    targetCol: number,
    inclusive: boolean,
  ): void {
    if (targetCol === col) return;

    const isForward = targetCol > col;
    const count = Math.abs(targetCol - col) + (inclusive ? 1 : 0);

    if (!isForward) {
      this.moveCursorBy(targetCol - col);
    }

    for (let i = 0; i < count; i++) {
      super.handleInput(ESC_DELETE);
    }
  }

  // ─── Rendering ───────────────────────────────────────────────────────────────

  render(width: number): string[] {
    const lines = super.render(width);
    if (this.editorMode === "emacs" || lines.length === 0) return lines;
    const label = this.getModeLabel();
    if (visibleWidth(lines[0]!) >= label.length) {
      lines[0] = label + truncateToWidth(lines[0]!, width - label.length, "");
    }
    return lines;
  }

  private getModeLabel(): string {
    if (this.viMode === "insert") return "❯ ";
    if (this.pendingOperator && this.pendingMotion)
      return `❮ ${this.pendingOperator}${this.pendingMotion}_ `;
    if (this.pendingOperator) return `❮ ${this.pendingOperator}_ `;
    if (this.pendingMotion) return `❮ ${this.pendingMotion}_ `;
    if (this.pendingG) return `❮ g_ `;
    return "❮ ";
  }

  // ─── Snippet expansion ───────────────────────────────────────────────────────

  /**
   * Apply selected autocomplete item AND expand the snippet to its final value.
   * Used by Ctrl-E: type `$da` → Ctrl-E → get `2026-03-07` directly.
   *
   * NOTE: Uses `(this as any)` to access CustomEditor internals — fragile coupling.
   */
  private applyAndExpandSnippet(): void {
    const state = this.getAutocompleteState();
    if (!state) return;

    const selectedItem = state.list.getSelectedItem() ?? state.list.items?.[0];
    if (!selectedItem) return;

    const completionResult = this.applyCompletion(selectedItem, state);
    const snippet = SNIPPETS.find((s) => s.trigger === selectedItem.value);

    if (!snippet) {
      this.notifyChange();
      return;
    }

    this.expandSnippet(snippet, completionResult, selectedItem.value);
  }

  private getAutocompleteState() {
    const list = (this as any).autocompleteList;
    const provider = (this as any).autocompleteProvider;
    const prefix = (this as any).autocompletePrefix;

    if (!list || !provider) return null;

    return { list, provider, prefix };
  }

  private applyCompletion(item: any, state: any) {
    (this as any).pushUndoSnapshot();
    (this as any).lastAction = null;

    const result = state.provider.applyCompletion(
      this.getLines(),
      this.getCursor().line,
      this.getCursor().col,
      item,
      state.prefix,
    );

    (this as any).state.lines = result.lines;
    (this as any).state.cursorLine = result.cursorLine;
    (this as any).setCursorCol(result.cursorCol);
    (this as any).cancelAutocomplete();

    return result;
  }

  private expandSnippet(
    snippet: SnippetDef,
    completionResult: any,
    triggerValue: string,
  ): void {
    try {
      const expansion =
        typeof snippet.expansion === "function"
          ? snippet.expansion()
          : snippet.expansion;

      if (expansion == null) {
        this.notifyChange();
        return;
      }

      if (!this.isValidCursorPosition(completionResult)) {
        this.notifyChange();
        return;
      }

      const triggerStart = completionResult.cursorCol - triggerValue.length;
      if (triggerStart < 0) {
        this.notifyChange();
        return;
      }

      const parsedExpansion = parseSnippetExpansion(expansion);
      const formattedExpansion =
        parsedExpansion.kind === "parsed"
          ? formatParsedSnippetExpansion(parsedExpansion, "bracketed")
          : parsedExpansion;

      this.placeholderSession = null;
      this.replaceTextAtCursor(
        completionResult,
        triggerStart,
        triggerValue.length,
        formattedExpansion.text,
      );
      if (formattedExpansion.kind === "parsed") {
        this.startPlaceholderSession(
          completionResult.cursorLine,
          triggerStart,
          formattedExpansion,
        );
      }
      this.notifyChange();
    } catch (error) {
      console.error("Snippet expansion failed:", error);
      this.notifyChange();
    }
  }

  private startPlaceholderSession(
    line: number,
    startCol: number,
    expansion: ParsedSnippetExpansion,
  ): void {
    if (expansion.tabstops.length === 0) {
      if (expansion.hasExplicitFinalStop) {
        this.setCursorPosition(line, startCol + expansion.finalStop);
      }
      return;
    }

    this.placeholderSession = {
      line,
      ranges: expansion.tabstops.map((tabstop) => ({
        index: tabstop.index,
        start: startCol + tabstop.start,
        end: startCol + tabstop.end,
      })),
      activeRangeIndex: 0,
      finalStop: startCol + expansion.finalStop,
      pendingReplacement: true,
    };

    this.setCursorPosition(
      line,
      this.getPlaceholderCursorCol(
        this.placeholderSession.ranges[
          this.placeholderSession.activeRangeIndex
        ]!,
      ),
    );
  }

  private isValidCursorPosition(result: any): boolean {
    return result.cursorLine >= 0 && result.cursorLine < result.lines.length;
  }

  private replaceTextAtCursor(
    result: any,
    start: number,
    deleteCount: number,
    replacement: string,
  ): void {
    const currentLine = result.lines[result.cursorLine] ?? "";
    const newLine =
      currentLine.slice(0, start) +
      replacement +
      currentLine.slice(start + deleteCount);

    (this as any).state.lines[result.cursorLine] = newLine;
    (this as any).setCursorCol(start + replacement.length);
  }

  private notifyChange(): void {
    if ((this as any).onChange) {
      (this as any).onChange(this.getText());
    }
  }
}
