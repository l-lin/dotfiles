import type { KeyId } from "@earendil-works/pi-tui";

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

export const REPLY_KEYMAP: ReplyKeymap = {
  // Popup lifecycle.
  open: "ctrl+r",
  save: "ctrl+s",
  close: "q",
  escape: "escape",

  // Visual selection and annotation.
  comment: "alt+c",
  yank: "y",
  lineYank: "shift+y",
  edit: "alt+e",
  delete: "alt+d",
  visualSwapCursor: "o",
  characterVisual: "v",
  lineVisual: "shift+v",

  // Basic cursor movement and paging.
  left: "h",
  down: "j",
  up: "k",
  right: "l",
  halfPageUp: "ctrl+u",
  halfPageDown: "ctrl+d",

  // Line movement.
  lineMotionPrefix: "g",
  lastLine: "shift+g",
  lineStart: "0",
  firstNonBlank: "_",
  lineEnd: "$",

  // Word movement.
  wordForward: "w",
  wordBackward: "b",
  wordEnd: "e",

  // Character search and repeats.
  findForward: "f",
  findBackward: "shift+f",
  tillForward: "t",
  tillBackward: "shift+t",
  repeatForward: ";",
  repeatBackward: ",",

  // Text search.
  searchForward: "/",
  searchBackward: "?",
  searchNext: "n",
  searchPrevious: "shift+n",
  wordSearchForward: "*",
  wordSearchBackward: "#",
};
