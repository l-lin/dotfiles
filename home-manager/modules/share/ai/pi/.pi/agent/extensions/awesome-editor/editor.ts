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
 * Translate a CSI-u extended ctrl sequence (e.g. "\x1b[101;5u" for Ctrl+E)
 * back to its legacy single-byte form ("\x05").
 * Non-ctrl sequences are returned unchanged.
 */
function normalizeLegacyCtrl(data: string): string {
  const key = parseKey(data);
  if (!key) return data;
  const match = key.match(/^ctrl\+(.+)$/);
  if (!match || match[1]!.length !== 1) return data;
  // ctrl+X → charCode(X) & 0x1f  (covers a–z, [, \\, ], ^, _)
  const code = match[1]!.charCodeAt(0) & 0x1f;
  return code >= 1 && code <= 31 ? String.fromCharCode(code) : data;
}

/**
 * Translate CSI-u extended Alt+Shift sequences to legacy format.
 * Examples:
 *   "\x1b[65;4u" (Alt+Shift+A) → "\x1bA"
 *   "\x1b[73;4u" (Alt+Shift+I) → "\x1bI"
 *   "\x1b[79;4u" (Alt+Shift+O) → "\x1bO"
 *   "\x1b[111;3u" (Alt+o) → "\x1bo"
 * Non-alt sequences are returned unchanged.
 */
function normalizeAltSequences(data: string): string {
  // Match CSI-u format: \x1b[<code>;<modifiers>u
  const match = data.match(/^\x1b\[(\d+);(\d+)u$/);
  if (!match) return data;

  const code = parseInt(match[1]!, 10);
  const modifiers = parseInt(match[2]!, 10);

  // Modifier values: 3=Alt, 4=Shift+Alt
  if (modifiers === 3 || modifiers === 4) {
    const char = String.fromCharCode(code);
    return `\x1b${char}`;
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
    data = normalizeAltSequences(data);
    data = normalizeLegacyCtrl(data);

    if (matchesKey(data, "escape")) return this.handleEscape();

    if (this.mode === "insert") {
      // Ctrl-E in autocomplete mode: apply + expand snippet
      if (data === "\x05" && (this as any).autocompleteState) {
        this.applyAndExpandSnippet();
        return;
      }
      if (matchesKey(data, Key.shiftAlt("a")) || data === "\x1bA")
        return super.handleInput(CTRL_E);
      if (matchesKey(data, Key.shiftAlt("i")) || data === "\x1bI")
        return super.handleInput(CTRL_A);
      if (matchesKey(data, Key.alt("o")) || data === "\x1bo") {
        super.handleInput(CTRL_E);
        super.handleInput(NEWLINE);
        return;
      }
      if (matchesKey(data, Key.shiftAlt("o")) || data === "\x1bO") {
        super.handleInput(CTRL_A);
        super.handleInput(NEWLINE);
        super.handleInput(ESC_UP);
        return;
      }
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
    if (this.deleteWithMotion(data)) return;
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
    if (this.deleteWithMotion(data)) this.mode = "insert";
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
    if (data === ";" && this.lastCharMotion) {
      this.executeCharMotion(
        this.lastCharMotion.motion,
        this.lastCharMotion.char,
        false,
      );
      return;
    }
    if (data === "," && this.lastCharMotion) {
      this.executeCharMotion(
        reverseCharMotion(this.lastCharMotion.motion),
        this.lastCharMotion.char,
        false,
      );
      return;
    }
    if (data === "g") {
      this.pendingG = "g";
      return;
    }
    if (data === "G") return this.moveToLine(this.getLines().length - 1);
    if (data === "w") return this.moveWord("forward", "start");
    if (data === "b") return this.moveWord("backward", "start");
    if (data === "e") return this.moveWord("forward", "end");
    if (data in NORMAL_KEYS) return this.handleMappedKey(data);

    // Swallow printable chars; pass control sequences through
    if (data.length === 1 && data.charCodeAt(0) >= 32) return;
    super.handleInput(data);
  }

  private handleMappedKey(key: string): void {
    const seq = NORMAL_KEYS[key];
    switch (key) {
      case "i":
        this.mode = "insert";
        break;
      case "a":
        this.mode = "insert";
        super.handleInput(ESC_RIGHT);
        break;
      case "A":
        this.mode = "insert";
        super.handleInput(CTRL_E);
        break;
      case "I":
        this.mode = "insert";
        super.handleInput(CTRL_A);
        break;
      case "o":
        super.handleInput(CTRL_E);
        super.handleInput(NEWLINE);
        this.mode = "insert";
        break;
      case "O":
        super.handleInput(CTRL_A);
        super.handleInput(NEWLINE);
        super.handleInput(ESC_UP);
        this.mode = "insert";
        break;
      case "C":
        super.handleInput(CTRL_K);
        this.mode = "insert";
        break;
      case "S":
        super.handleInput(CTRL_A);
        super.handleInput(CTRL_K);
        this.mode = "insert";
        break;
      case "s":
        super.handleInput(ESC_DELETE);
        this.mode = "insert";
        break;
      default:
        if (seq) super.handleInput(seq);
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
    if (targetCol !== null && saveMotion)
      this.lastCharMotion = { motion, char: targetChar };
    if (targetCol !== null && targetCol !== col)
      this.moveCursorBy(targetCol - col);
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
    if (targetCol > col) {
      const count = targetCol - col + (inclusive ? 1 : 0);
      for (let i = 0; i < count; i++) super.handleInput(ESC_DELETE);
    } else if (targetCol < col) {
      const count = col - targetCol + (inclusive ? 1 : 0);
      this.moveCursorBy(targetCol - col);
      for (let i = 0; i < count; i++) super.handleInput(ESC_DELETE);
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
    try {
      const autocompleteList = (this as any).autocompleteList;
      const autocompleteProvider = (this as any).autocompleteProvider;
      const autocompletePrefix = (this as any).autocompletePrefix;

      if (!autocompleteList || !autocompleteProvider) return;

      // 1. Get selected (or first) item
      const selected =
        autocompleteList.getSelectedItem() ?? autocompleteList.items?.[0];
      if (!selected) return;

      // 2. Apply the completion (insert trigger like "$date")
      (this as any).pushUndoSnapshot();
      (this as any).lastAction = null;

      const result = autocompleteProvider.applyCompletion(
        this.getLines(),
        this.getCursor().line,
        this.getCursor().col,
        selected,
        autocompletePrefix,
      );

      // Update editor state
      (this as any).state.lines = result.lines;
      (this as any).state.cursorLine = result.cursorLine;
      (this as any).setCursorCol(result.cursorCol);

      // Cancel autocomplete
      (this as any).cancelAutocomplete();

      // 3. Now expand the snippet trigger to its final value
      const snippet = SNIPPETS.find((s) => s.trigger === selected.value);
      if (!snippet) {
        // Not a snippet trigger, just a regular completion
        if ((this as any).onChange) (this as any).onChange(this.getText());
        return;
      }

      const expansion =
        typeof snippet.expansion === "function"
          ? snippet.expansion()
          : snippet.expansion;

      // Validate expansion result
      if (expansion == null) {
        if ((this as any).onChange) (this as any).onChange(this.getText());
        return;
      }

      // Validate cursor position and bounds
      if (result.cursorLine < 0 || result.cursorLine >= result.lines.length) {
        if ((this as any).onChange) (this as any).onChange(this.getText());
        return;
      }

      const triggerStart = result.cursorCol - selected.value.length;
      if (triggerStart < 0) {
        // Trigger position invalid — abort expansion
        if ((this as any).onChange) (this as any).onChange(this.getText());
        return;
      }

      // Replace the trigger with expansion on current line
      const currentLine = result.lines[result.cursorLine] ?? "";
      const newLine =
        currentLine.slice(0, triggerStart) +
        expansion +
        currentLine.slice(result.cursorCol);

      (this as any).state.lines[result.cursorLine] = newLine;
      (this as any).setCursorCol(triggerStart + expansion.length);

      if ((this as any).onChange) (this as any).onChange(this.getText());
    } catch (error) {
      // If snippet expansion fails, ensure editor state remains consistent
      console.error("Snippet expansion failed:", error);
      if ((this as any).onChange) (this as any).onChange(this.getText());
    }
  }
}
