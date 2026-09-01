import type { ReplyKeymap } from "./component.js";

export const REPLY_KEYMAP: ReplyKeymap = {
  // Popup lifecycle.
  open: "ctrl+r",
  save: "ctrl+s",
  close: "q",
  escape: "escape",

  // Visual selection and annotation.
  comment: "alt+c",
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
