/**
 * Vim mode types, key maps, and escape sequences.
 */

export type Mode            = "normal" | "insert";
export type CharMotion      = "f" | "F" | "t" | "T";
export type PendingMotion   = CharMotion | null;
export type PendingOperator = "d" | "c" | null;
export type PendingG        = "g" | null;

export interface LastCharMotion {
  motion: CharMotion;
  char: string;
}

/** Normal mode key → escape sequence (null = handled in code, not via sendInput) */
export const NORMAL_KEYS: Record<string, string | null> = {
  h:   "\x1b[D",   // left
  j:   "\x1b[B",   // down
  k:   "\x1b[A",   // up
  l:   "\x1b[C",   // right
  "0": "\x01",     // line start
  $:   "\x05",     // line end
  x:   "\x1b[3~",  // delete char
  D:   "\x0b",     // delete to end of line (Ctrl+K)
  C:   null,       // change to end of line
  S:   null,       // substitute line
  s:   null,       // substitute char
  i:   null,       // insert mode
  a:   null,       // append
  A:   null,       // append at end of line
  I:   null,       // insert at start of line
  o:   null,       // open line below
  O:   null,       // open line above
};

export const CHAR_MOTION_KEYS = new Set<string>(["f", "F", "t", "T"]);

export const ESC_LEFT   = "\x1b[D";
export const ESC_RIGHT  = "\x1b[C";
export const ESC_DELETE = "\x1b[3~";
export const CTRL_A     = "\x01";
export const CTRL_E     = "\x05";
export const CTRL_K     = "\x0b";
export const NEWLINE    = "\n";
export const ESC_UP     = "\x1b[A";
export const ESC_DOWN   = "\x1b[B";
