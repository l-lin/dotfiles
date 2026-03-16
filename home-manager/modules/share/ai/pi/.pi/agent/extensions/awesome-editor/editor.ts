/**
 * AwesomeEditor — CustomEditor subclass combining:
 *   - Vim modal editing (normal / insert modes)
 *   - Snippet trigger autocomplete ($date, $tdd, ?q, …)
 */

import { CustomEditor } from "@mariozechner/pi-coding-agent";
import {
  Key,
  matchesKey,
  parseKey,
  truncateToWidth,
  visibleWidth,
} from "@mariozechner/pi-tui";
import type { AutocompleteProvider } from "@mariozechner/pi-tui";

import { withSnippets } from "./snippets.js";
import { SNIPPETS } from "../snippet/snippets.js";
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

export class AwesomeEditor extends CustomEditor {
  private mode: Mode = "insert";
  private pendingMotion: PendingMotion = null;
  private pendingOperator: PendingOperator = null;
  private pendingG: PendingG = null;
  private lastCharMotion: LastCharMotion | null = null;

  // InteractiveMode calls this after construction with its CombinedAutocompleteProvider.
  // We wrap it to prepend snippet suggestions while preserving slash-commands + file paths.
  setAutocompleteProvider(base: AutocompleteProvider): void {
    super.setAutocompleteProvider(withSnippets(base));
  }

  handleInput(data: string): void {
    // Normalize CSI-u extended sequences for both Ctrl and Alt modifiers
    // so all downstream checks and readline passthrough use the expected bytes.
    data = normalizeExtendedSequences(data);

    if (matchesKey(data, "escape")) return this.handleEscape();

    if (this.mode === "insert") {
      // Ctrl-E in autocomplete mode: apply + expand snippet
      if (data === "\x05" && (this as any).autocompleteState) {
        this.applyAndExpandSnippet();
        return;
      }

      // Alt shortcuts for insert mode
      if (this.handleInsertModeShortcut(data)) return;

      super.handleInput(data);

      // Auto-trigger snippet autocomplete as soon as "$" is typed.
      if (data === "$" && !(this as any).autocompleteState) {
        (this as any).tryTriggerAutocomplete();
      }
      return;
    }

    if (this.pendingG) return this.handlePendingG(data);
    if (this.pendingMotion) return this.handlePendingMotion(data);
    if (this.pendingOperator === "d") return this.handlePendingDelete(data);
    if (this.pendingOperator === "c") return this.handlePendingChange(data);

    this.handleNormalMode(data);
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
    if (this.mode === "insert") {
      this.mode = "normal";
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
        this.mode = "insert";
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
      this.mode = "insert";
      return;
    }

    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as CharMotion;
      return;
    }

    // Unknown motion: cancel operator (vim behaviour)
    this.pendingOperator = null;
    if (this.deleteWithMotion(data)) {
      this.mode = "insert";
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
      this.mode = "insert";
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
    if (lines.length === 0) return lines;
    const label = this.getModeLabel();
    if (visibleWidth(lines[0]!) >= label.length) {
      lines[0] = label + truncateToWidth(lines[0]!, width - label.length, "");
    }
    return lines;
  }

  private getModeLabel(): string {
    if (this.mode === "insert") return "❯ ";
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
    snippet: any,
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

      this.replaceTextAtCursor(
        completionResult,
        triggerStart,
        triggerValue.length,
        expansion,
      );
      this.notifyChange();
    } catch (error) {
      console.error("Snippet expansion failed:", error);
      this.notifyChange();
    }
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
