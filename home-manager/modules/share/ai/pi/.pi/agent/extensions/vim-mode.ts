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
 * - f{char}: jump to next {char} on line
 * - F{char}: jump to previous {char} on line
 * - t{char}: jump to just before next {char} on line
 * - T{char}: jump to just after previous {char} on line
 * - ;: repeat last f/F/t/T motion (same direction)
 * - ,: repeat last f/F/t/T motion (reverse direction)
 * - w: move to start of next word
 * - b: move to start of previous word
 * - e: move to end of word
 * - ctrl+c, ctrl+d, etc. work in both modes
 *
 * src: https://github.com/badlogic/pi-mono/blob/34878e7cc8074f42edff6c2cdcc9828aa9b6afde/packages/coding-agent/examples/extensions/modal-editor.ts
 * Renamed and adapted to support more vim navigation.
 */

import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  matchesKey,
  truncateToWidth,
  visibleWidth,
} from "@mariozechner/pi-tui";

// Normal mode key mappings: key -> escape sequence (or null for mode switch)
const NORMAL_KEYS: Record<string, string | null> = {
  h: "\x1b[D", // left
  j: "\x1b[B", // down
  k: "\x1b[A", // up
  l: "\x1b[C", // right
  "0": "\x01", // line start
  $: "\x05", // line end
  x: "\x1b[3~", // delete char
  i: null, // insert mode
  a: null, // append (insert + right)
  A: null, // append at end of line
  I: null, // insert at start of line
};

// Character motion keys that wait for a target character
const CHAR_MOTION_KEYS = new Set(["f", "F", "t", "T"]);

type PendingMotion = "f" | "F" | "t" | "T" | null;
type CharMotion = "f" | "F" | "t" | "T";

// Word character regex (alphanumeric + underscore)
const isWordChar = (c: string) => /\w/.test(c);

class ModalEditor extends CustomEditor {
  private mode: "normal" | "insert" = "insert";
  private pendingMotion: PendingMotion = null;
  private lastCharMotion: { motion: CharMotion; char: string } | null = null;

  handleInput(data: string): void {
    // Escape toggles to normal mode, or passes through for app handling
    if (matchesKey(data, "escape")) {
      if (this.pendingMotion) {
        this.pendingMotion = null; // cancel pending motion
        return;
      }
      if (this.mode === "insert") {
        this.mode = "normal";
      } else {
        super.handleInput(data); // abort agent, etc.
      }
      return;
    }

    // Insert mode: pass everything through
    if (this.mode === "insert") {
      super.handleInput(data);
      return;
    }

    // Handle pending character motion (waiting for target char)
    if (this.pendingMotion) {
      if (data.length === 1 && data.charCodeAt(0) >= 32) {
        this.executeCharMotion(this.pendingMotion, data);
      }
      this.pendingMotion = null;
      return;
    }

    // Check for character motion triggers (f, F, t, T)
    if (CHAR_MOTION_KEYS.has(data)) {
      this.pendingMotion = data as PendingMotion;
      return;
    }

    // Repeat last character motion with ; (same direction) or , (reverse)
    if (data === ";") {
      if (this.lastCharMotion) {
        this.executeCharMotion(
          this.lastCharMotion.motion,
          this.lastCharMotion.char,
          false,
        );
      }
      return;
    }
    if (data === ",") {
      if (this.lastCharMotion) {
        this.executeCharMotion(
          this.reverseMotion(this.lastCharMotion.motion),
          this.lastCharMotion.char,
          false,
        );
      }
      return;
    }

    // Word motions (w, b, e)
    if (data === "w") {
      this.moveWord("forward", "start");
      return;
    }
    if (data === "b") {
      this.moveWord("backward", "start");
      return;
    }
    if (data === "e") {
      this.moveWord("forward", "end");
      return;
    }

    // Normal mode: check mapped keys
    if (data in NORMAL_KEYS) {
      const seq = NORMAL_KEYS[data];
      if (data === "i") {
        this.mode = "insert";
      } else if (data === "a") {
        this.mode = "insert";
        super.handleInput("\x1b[C"); // move right first
      } else if (data === "A") {
        this.mode = "insert";
        super.handleInput("\x05"); // move to end of line first
      } else if (data === "I") {
        this.mode = "insert";
        super.handleInput("\x01"); // move to start of line first
      } else if (seq) {
        super.handleInput(seq);
      }
      return;
    }

    // Pass control sequences (ctrl+c, etc.) to super, ignore printable chars
    if (data.length === 1 && data.charCodeAt(0) >= 32) return;
    super.handleInput(data);
  }

  /**
   * Reverse a character motion direction (f ↔ F, t ↔ T).
   */
  private reverseMotion(motion: CharMotion): CharMotion {
    const reverseMap: Record<CharMotion, CharMotion> = {
      f: "F",
      F: "f",
      t: "T",
      T: "t",
    };
    return reverseMap[motion];
  }

  /**
   * Execute a character motion (f/F/t/T) to the target character.
   * @param saveMotion - if true, saves to lastCharMotion for ; repeat (false for ; and , repeats)
   */
  private executeCharMotion(
    motion: CharMotion,
    targetChar: string,
    saveMotion: boolean = true,
  ): void {
    const lines = this.getLines();
    const cursor = this.getCursor();
    const line = lines[cursor.line] ?? "";
    const col = cursor.col;

    const isForward = motion === "f" || motion === "t";
    const isTill = motion === "t" || motion === "T";

    let targetCol: number | null = null;

    // For till repeats (;/,), we need extra offset to skip past the character we stopped before/after
    const tillRepeatOffset = isTill && !saveMotion ? 1 : 0;

    if (isForward) {
      // Search right from cursor+1 (+2 on till repeat to skip current target)
      const searchStart = col + 1 + tillRepeatOffset;
      const idx = line.indexOf(targetChar, searchStart);
      if (idx !== -1) {
        targetCol = isTill ? idx - 1 : idx;
      }
    } else {
      // Search left from cursor-1 (-2 on till repeat to skip current target)
      const searchStart = col - 1 - tillRepeatOffset;
      const idx = line.lastIndexOf(targetChar, searchStart);
      if (idx !== -1) {
        targetCol = isTill ? idx + 1 : idx;
      }
    }

    // Save motion for ; repeat (only on fresh f/F/t/T, not on ; or , repeats)
    // Save even if cursor doesn't move (e.g., tx when already at position before target)
    if (targetCol !== null && saveMotion) {
      this.lastCharMotion = { motion, char: targetChar };
    }

    // Move cursor if target found and position changed
    if (targetCol !== null && targetCol !== col) {
      const delta = targetCol - col;
      this.moveCursorBy(delta);
    }
  }

  /**
   * Move cursor by delta columns (positive = right, negative = left).
   */
  private moveCursorBy(delta: number): void {
    const moveSeq = delta > 0 ? "\x1b[C" : "\x1b[D";
    const moves = Math.abs(delta);
    for (let i = 0; i < moves; i++) {
      super.handleInput(moveSeq);
    }
  }

  /**
   * Move by word (w, b, e motions).
   */
  private moveWord(
    direction: "forward" | "backward",
    target: "start" | "end",
  ): void {
    const lines = this.getLines();
    const cursor = this.getCursor();
    const line = lines[cursor.line] ?? "";
    const col = cursor.col;

    if (direction === "forward") {
      if (target === "start") {
        // w: move to start of next word
        let i = col;
        // Skip current word chars
        while (i < line.length && isWordChar(line[i]!)) i++;
        // Skip non-word chars (whitespace/punctuation)
        while (i < line.length && !isWordChar(line[i]!)) i++;
        if (i > col) this.moveCursorBy(i - col);
      } else {
        // e: move to end of current/next word
        let i = col;
        // If on word char, skip to end; if on non-word, find next word first
        if (i < line.length - 1) i++; // move at least one
        // Skip non-word chars
        while (i < line.length && !isWordChar(line[i]!)) i++;
        // Move to end of word
        while (i < line.length - 1 && isWordChar(line[i + 1]!)) i++;
        if (i > col) this.moveCursorBy(i - col);
      }
    } else {
      // b: move to start of previous word
      let i = col;
      // Move back at least one
      if (i > 0) i--;
      // Skip non-word chars
      while (i > 0 && !isWordChar(line[i]!)) i--;
      // Move to start of word
      while (i > 0 && isWordChar(line[i - 1]!)) i--;
      if (i < col) this.moveCursorBy(i - col);
    }
  }

  render(width: number): string[] {
    const lines = super.render(width);
    if (lines.length === 0) return lines;

    // Add mode indicator to bottom border
    let label: string;
    if (this.mode === "insert") {
      label = " INSERT ";
    } else if (this.pendingMotion) {
      label = ` NORMAL ${this.pendingMotion}_ `;
    } else {
      label = " NORMAL ";
    }
    const last = lines.length - 1;
    if (visibleWidth(lines[last]!) >= label.length) {
      lines[last] =
        truncateToWidth(lines[last]!, width - label.length, "") + label;
    }
    return lines;
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setEditorComponent(
      (tui, theme, kb) => new ModalEditor(tui, theme, kb),
    );
  });
}
