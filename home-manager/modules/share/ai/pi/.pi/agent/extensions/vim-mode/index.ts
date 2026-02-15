/**
 * Modal Editor - vim-like modal editing example
 *
 * Usage: pi --extension ./examples/extensions/modal-editor.ts
 *
 * - Escape: insert → normal mode (in normal mode, aborts agent)
 * - i: normal → insert mode (at cursor)
 * - a: insert after cursor
 * - A: insert at end of line
 * - I: insert at start of line
 * - hjkl: navigation in normal mode
 * - 0/$: line start/end
 * - x: delete char under cursor
 * - D: delete to end of line
 * - S: substitute line (delete line content + insert mode)
 * - s: substitute char (delete char + insert mode)
 * - d{motion}: delete with motion (dw, db, de, d$, d0, dd, df/dt/dF/dT{char})
 * - f{char}: jump to next {char} on line
 * - F{char}: jump to previous {char} on line
 * - t{char}: jump to just before next {char} on line
 * - T{char}: jump to just after previous {char} on line
 * - ;: repeat last f/F/t/T motion (same direction)
 * - ,: repeat last f/F/t/T motion (reverse direction)
 * - w: move to start of next word
 * - b: move to start of previous word
 * - e: move to end of word
 * - Shift+Alt+A: go to end of line (insert mode shortcut)
 * - Shift+Alt+I: go to start of line (insert mode shortcut)
 * - ctrl+c, ctrl+d, etc. work in both modes
 *
 * src: https://github.com/badlogic/pi-mono/blob/34878e7cc8074f42edff6c2cdcc9828aa9b6afde/packages/coding-agent/examples/extensions/modal-editor.ts
 * Renamed and adapted to support more vim navigation.
 */

import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
} from "@mariozechner/pi-tui";

import type {
  Mode,
  CharMotion,
  PendingMotion,
  PendingOperator,
  LastCharMotion,
} from "./types.js";
import {
  NORMAL_KEYS,
  CHAR_MOTION_KEYS,
  ESC_LEFT,
  ESC_RIGHT,
  ESC_DELETE,
  CTRL_A,
  CTRL_E,
  CTRL_K,
} from "./types.js";
import {
  reverseCharMotion,
  findCharMotionTarget,
  findWordMotionTarget,
} from "./motions.js";

class ModalEditor extends CustomEditor {
  private mode: Mode = "insert";
  private pendingMotion: PendingMotion = null;
  private pendingOperator: PendingOperator = null;
  private lastCharMotion: LastCharMotion | null = null;

  handleInput(data: string): void {
    if (matchesKey(data, "escape")) {
      return this.handleEscape();
    }

    if (this.mode === "insert") {
      // Shift+Alt+A: go to end of line (like Esc -> A but stay in insert)
      if (matchesKey(data, Key.shiftAlt("a")) || data === "\x1bA") {
        return super.handleInput(CTRL_E);
      }
      // Shift+Alt+I: go to start of line (like Esc -> I but stay in insert)
      if (matchesKey(data, Key.shiftAlt("i")) || data === "\x1bI") {
        return super.handleInput(CTRL_A);
      }
      return super.handleInput(data);
    }


    if (this.pendingMotion) {
      return this.handlePendingMotion(data);
    }

    if (this.pendingOperator === "d") {
      return this.handlePendingDelete(data);
    }

    if (this.pendingOperator === "c") {
      return this.handlePendingChange(data);
    }

    this.handleNormalMode(data);
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
      super.handleInput("\x1b"); // pass escape to abort agent
    }
  }

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
      this.pendingMotion = data as PendingMotion;
      return;
    }
    if (this.deleteWithMotion(data)) {
      this.pendingOperator = null;
    }
  }

  private handlePendingChange(data: string): void {
    if (data === "c") {
      this.deleteLine();
      this.pendingOperator = null;
      this.mode = "insert";
      return;
    }
    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as PendingMotion;
      return;
    }
    if (this.deleteWithMotion(data)) {
      this.pendingOperator = null;
      this.mode = "insert";
    }
  }

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
      this.pendingMotion = data as PendingMotion;
      return;
    }

    if (data === ";" && this.lastCharMotion) {
      this.executeCharMotion(this.lastCharMotion.motion, this.lastCharMotion.char, false);
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

    if (data === "w") return this.moveWord("forward", "start");
    if (data === "b") return this.moveWord("backward", "start");
    if (data === "e") return this.moveWord("forward", "end");

    if (data in NORMAL_KEYS) {
      return this.handleMappedKey(data);
    }

    // Pass control sequences (ctrl+c, etc.) to super, ignore printable chars
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

  private executeCharMotion(motion: CharMotion, targetChar: string, saveMotion: boolean = true): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const targetCol = findCharMotionTarget(line, col, motion, targetChar, !saveMotion);

    if (targetCol !== null && saveMotion) {
      this.lastCharMotion = { motion, char: targetChar };
    }

    if (targetCol !== null && targetCol !== col) {
      this.moveCursorBy(targetCol - col);
    }
  }

  private moveCursorBy(delta: number): void {
    const seq = delta > 0 ? ESC_RIGHT : ESC_LEFT;
    for (let i = 0; i < Math.abs(delta); i++) {
      super.handleInput(seq);
    }
  }

  private moveWord(direction: "forward" | "backward", target: "start" | "end"): void {
    const line = this.getLines()[this.getCursor().line] ?? "";
    const col = this.getCursor().col;
    const targetCol = findWordMotionTarget(line, col, direction, target);
    if (targetCol !== col) {
      this.moveCursorBy(targetCol - col);
    }
  }

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
    const isForward = motion === "f" || motion === "t";
    const isTill = motion === "t" || motion === "T";

    let targetCol: number | null = null;

    if (isForward) {
      const idx = line.indexOf(targetChar, col + 1);
      if (idx !== -1) targetCol = isTill ? idx - 1 : idx;
    } else {
      const idx = line.lastIndexOf(targetChar, col - 1);
      if (idx !== -1) targetCol = isTill ? idx + 1 : idx;
    }

    if (targetCol === null) return;

    this.lastCharMotion = { motion, char: targetChar };
    this.deleteRange(col, targetCol, true); // char motions are inclusive
  }

  private deleteRange(col: number, targetCol: number, inclusive: boolean): void {
    if (targetCol > col) {
      const count = targetCol - col + (inclusive ? 1 : 0);
      for (let i = 0; i < count; i++) {
        super.handleInput(ESC_DELETE);
      }
    } else if (targetCol < col) {
      const count = col - targetCol + (inclusive ? 1 : 0);
      this.moveCursorBy(targetCol - col);
      for (let i = 0; i < count; i++) {
        super.handleInput(ESC_DELETE);
      }
    }
  }

  render(width: number): string[] {
    const lines = super.render(width);
    if (lines.length === 0) return lines;

    const label = this.getModeLabel();
    const last = lines.length - 1;
    if (visibleWidth(lines[last]!) >= label.length) {
      lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
    }
    return lines;
  }

  private getModeLabel(): string {
    if (this.mode === "insert") return " INSERT ";
    if (this.pendingOperator && this.pendingMotion) {
      return ` NORMAL ${this.pendingOperator}${this.pendingMotion}_ `;
    }
    if (this.pendingOperator) return ` NORMAL ${this.pendingOperator}_ `;
    if (this.pendingMotion) return ` NORMAL ${this.pendingMotion}_ `;
    return " NORMAL ";
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setEditorComponent((tui, theme, kb) => new ModalEditor(tui, theme, kb));
  });
}
