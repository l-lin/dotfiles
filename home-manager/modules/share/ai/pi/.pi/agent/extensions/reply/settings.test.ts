import assert from "node:assert/strict";
import test from "node:test";
import { REPLY_KEYMAP } from "./settings.js";

test("reply settings GIVEN the built-in keymap WHEN reading it THEN returns every reply binding", () => {
  const actual = REPLY_KEYMAP;
  const expected = {
    open: "ctrl+r",
    save: "ctrl+s",
    close: "q",
    escape: "escape",
    comment: "alt+c",
    visualSwapCursor: "o",
    left: "h",
    down: "j",
    up: "k",
    right: "l",
    halfPageUp: "ctrl+u",
    halfPageDown: "ctrl+d",
    characterVisual: "v",
    lineVisual: "shift+v",
    lineMotionPrefix: "g",
    lastLine: "shift+g",
    wordForward: "w",
    wordBackward: "b",
    wordEnd: "e",
    lineStart: "0",
    firstNonBlank: "_",
    lineEnd: "$",
    findForward: "f",
    findBackward: "shift+f",
    tillForward: "t",
    tillBackward: "shift+t",
    repeatForward: ";",
    repeatBackward: ",",
    searchForward: "/",
    searchBackward: "?",
    searchNext: "n",
    searchPrevious: "shift+n",
    wordSearchForward: "*",
    wordSearchBackward: "#",
  };

  assert.deepEqual(actual, expected);
});
