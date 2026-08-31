import type { KeyId } from "@earendil-works/pi-tui";
import { readExtensionSettings } from "../tool-settings/index.js";
import type { ReplyKeymap } from "./component.js";

type ReplySettings = Partial<Record<keyof ReplyKeymap, unknown>>;

export const DEFAULT_REPLY_KEYMAP: ReplyKeymap = {
  open: "ctrl+r",
  save: "ctrl+s",
  close: "q",
  comment: "alt+c",
  left: "h",
  down: "j",
  up: "k",
  right: "l",
  halfPageUp: "ctrl+u",
  halfPageDown: "ctrl+d",
  characterVisual: "v",
  lineVisual: "shift+v",
};

export function loadReplyKeymap(): ReplyKeymap {
  const settings = readExtensionSettings<ReplySettings>("reply");
  return {
    open: readKey(settings.open, DEFAULT_REPLY_KEYMAP.open),
    save: readKey(settings.save, DEFAULT_REPLY_KEYMAP.save),
    close: readKey(settings.close, DEFAULT_REPLY_KEYMAP.close),
    comment: readKey(settings.comment, DEFAULT_REPLY_KEYMAP.comment),
    left: readKey(settings.left, DEFAULT_REPLY_KEYMAP.left),
    down: readKey(settings.down, DEFAULT_REPLY_KEYMAP.down),
    up: readKey(settings.up, DEFAULT_REPLY_KEYMAP.up),
    right: readKey(settings.right, DEFAULT_REPLY_KEYMAP.right),
    halfPageUp: readKey(settings.halfPageUp, DEFAULT_REPLY_KEYMAP.halfPageUp),
    halfPageDown: readKey(
      settings.halfPageDown,
      DEFAULT_REPLY_KEYMAP.halfPageDown,
    ),
    characterVisual: readKey(
      settings.characterVisual,
      DEFAULT_REPLY_KEYMAP.characterVisual,
    ),
    lineVisual: readKey(settings.lineVisual, DEFAULT_REPLY_KEYMAP.lineVisual),
  };
}

function readKey(value: unknown, fallback: KeyId): KeyId {
  return typeof value === "string" && value.length > 0
    ? (value as KeyId)
    : fallback;
}
