/**
 * AwesomeEditor — CustomEditor subclass combining:
 *   - Vim modal editing (normal / insert modes)
 *   - Snippet trigger autocomplete ($date, $tdd, ?q, …)
 */

import { CustomEditor } from "@mariozechner/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import type { AutocompleteProvider } from "@mariozechner/pi-tui";

import { withSnippets } from "./snippets.js";
import {
  type Mode,
  type CharMotion,
  type PendingMotion,
  type PendingOperator,
  type LastCharMotion,
  NORMAL_KEYS,
  CHAR_MOTION_KEYS,
  ESC_LEFT, ESC_RIGHT, ESC_DELETE,
  CTRL_A, CTRL_E, CTRL_K,
  NEWLINE, ESC_UP,
} from "./vim/types.js";
import { reverseCharMotion, findCharMotionTarget, findWordMotionTarget } from "./vim/motions.js";

export class AwesomeEditor extends CustomEditor {
  private mode: Mode                   = "insert";
  private pendingMotion: PendingMotion   = null;
  private pendingOperator: PendingOperator = null;
  private lastCharMotion: LastCharMotion | null = null;

  // InteractiveMode calls this after construction with its CombinedAutocompleteProvider.
  // We wrap it to prepend snippet suggestions while preserving slash-commands + file paths.
  setAutocompleteProvider(base: AutocompleteProvider): void {
    super.setAutocompleteProvider(withSnippets(base));
  }

  handleInput(data: string): void {
    if (matchesKey(data, "escape")) return this.handleEscape();

    if (this.mode === "insert") {
      if (matchesKey(data, Key.shiftAlt("a")) || data === "\x1bA") return super.handleInput(CTRL_E);
      if (matchesKey(data, Key.shiftAlt("i")) || data === "\x1bI") return super.handleInput(CTRL_A);
      if (matchesKey(data, Key.alt("o"))       || data === "\x1bo") {
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

    if (this.pendingMotion)             return this.handlePendingMotion(data);
    if (this.pendingOperator === "d")   return this.handlePendingDelete(data);
    if (this.pendingOperator === "c")   return this.handlePendingChange(data);

    this.handleNormalMode(data);
  }

  // ─── Escape / mode transitions ───────────────────────────────────────────────

  private handleEscape(): void {
    if (this.pendingMotion || this.pendingOperator) {
      this.pendingMotion   = null;
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
    if (data === "d")                { this.deleteLine(); this.pendingOperator = null; return; }
    if (CHAR_MOTION_KEYS.has(data))  { this.pendingMotion = data as CharMotion; return; }
    // Unknown motion: cancel operator (vim behaviour)
    this.pendingOperator = null;
    if (this.deleteWithMotion(data)) return;
  }

  private handlePendingChange(data: string): void {
    if (data === "c")               { this.deleteLine(); this.pendingOperator = null; this.mode = "insert"; return; }
    if (CHAR_MOTION_KEYS.has(data)) { this.pendingMotion = data as CharMotion; return; }
    // Unknown motion: cancel operator (vim behaviour)
    this.pendingOperator = null;
    if (this.deleteWithMotion(data)) this.mode = "insert";
  }

  // ─── Normal mode dispatch ────────────────────────────────────────────────────

  private handleNormalMode(data: string): void {
    if (data === "d")                        { this.pendingOperator = "d"; return; }
    if (data === "c")                        { this.pendingOperator = "c"; return; }
    if (CHAR_MOTION_KEYS.has(data))          { this.pendingMotion = data as CharMotion; return; }
    if (data === ";" && this.lastCharMotion) {
      this.executeCharMotion(this.lastCharMotion.motion, this.lastCharMotion.char, false);
      return;
    }
    if (data === "," && this.lastCharMotion) {
      this.executeCharMotion(reverseCharMotion(this.lastCharMotion.motion), this.lastCharMotion.char, false);
      return;
    }
    if (data === "w") return this.moveWord("forward",  "start");
    if (data === "b") return this.moveWord("backward", "start");
    if (data === "e") return this.moveWord("forward",  "end");
    if (data in NORMAL_KEYS) return this.handleMappedKey(data);

    // Swallow printable chars; pass control sequences through
    if (data.length === 1 && data.charCodeAt(0) >= 32) return;
    super.handleInput(data);
  }

  private handleMappedKey(key: string): void {
    const seq = NORMAL_KEYS[key];
    switch (key) {
      case "i": this.mode = "insert"; break;
      case "a": this.mode = "insert"; super.handleInput(ESC_RIGHT); break;
      case "A": this.mode = "insert"; super.handleInput(CTRL_E); break;
      case "I": this.mode = "insert"; super.handleInput(CTRL_A); break;
      case "o": super.handleInput(CTRL_E); super.handleInput(NEWLINE); this.mode = "insert"; break;
      case "O":
        super.handleInput(CTRL_A);
        super.handleInput(NEWLINE);
        super.handleInput(ESC_UP);
        this.mode = "insert";
        break;
      case "C": super.handleInput(CTRL_K); this.mode = "insert"; break;
      case "S": super.handleInput(CTRL_A); super.handleInput(CTRL_K); this.mode = "insert"; break;
      case "s": super.handleInput(ESC_DELETE); this.mode = "insert"; break;
      default:  if (seq) super.handleInput(seq);
    }
  }

  // ─── Motion execution ────────────────────────────────────────────────────────

  private executeCharMotion(motion: CharMotion, targetChar: string, saveMotion = true): void {
    const line      = this.getLines()[this.getCursor().line] ?? "";
    const col       = this.getCursor().col;
    const targetCol = findCharMotionTarget(line, col, motion, targetChar, !saveMotion);
    if (targetCol !== null && saveMotion) this.lastCharMotion = { motion, char: targetChar };
    if (targetCol !== null && targetCol !== col) this.moveCursorBy(targetCol - col);
  }

  private moveCursorBy(delta: number): void {
    const seq = delta > 0 ? ESC_RIGHT : ESC_LEFT;
    for (let i = 0; i < Math.abs(delta); i++) super.handleInput(seq);
  }

  private moveWord(direction: "forward" | "backward", target: "start" | "end"): void {
    const line      = this.getLines()[this.getCursor().line] ?? "";
    const col       = this.getCursor().col;
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
    const col  = this.getCursor().col;
    let targetCol: number | null = null;
    let inclusive = false;

    switch (motion) {
      case "w": targetCol = findWordMotionTarget(line, col, "forward",  "start"); break;
      case "e": targetCol = findWordMotionTarget(line, col, "forward",  "end");   inclusive = true; break;
      case "b": targetCol = findWordMotionTarget(line, col, "backward", "start"); break;
      case "$": targetCol = line.length; break;
      case "0": targetCol = 0; break;
      default:  return false;
    }
    this.deleteRange(col, targetCol, inclusive);
    return true;
  }

  private deleteWithCharMotion(motion: CharMotion, targetChar: string): void {
    const line      = this.getLines()[this.getCursor().line] ?? "";
    const col       = this.getCursor().col;
    const targetCol = findCharMotionTarget(line, col, motion, targetChar);
    if (targetCol === null) return;
    this.lastCharMotion = { motion, char: targetChar };
    this.deleteRange(col, targetCol, true);
  }

  private deleteRange(col: number, targetCol: number, inclusive: boolean): void {
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
    const last  = lines.length - 1;
    if (visibleWidth(lines[last]!) >= label.length) {
      lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
    }
    return lines;
  }

  private getModeLabel(): string {
    if (this.mode === "insert")                          return " INSERT ";
    if (this.pendingOperator && this.pendingMotion)      return ` NORMAL ${this.pendingOperator}${this.pendingMotion}_ `;
    if (this.pendingOperator)                            return ` NORMAL ${this.pendingOperator}_ `;
    if (this.pendingMotion)                              return ` NORMAL ${this.pendingMotion}_ `;
    return " NORMAL ";
  }
}
