import type { Theme } from "@earendil-works/pi-coding-agent";
import {
  Input,
  matchesKey,
  truncateToWidth,
  type Component,
  type Focusable,
  type TUI,
} from "@earendil-works/pi-tui";
import {
  createReplyModel,
  type ReplyComponentResult,
  type ReplyModel,
} from "./state.js";
import type { ReplyKeymap } from "./settings.js";
import { updateReply, type ReplyEffect, type ReplyMessage } from "./update.js";
import { getReplyViewportHeight, renderReplyView } from "./view.js";

export type { ReplyComponentResult } from "./state.js";
export type { ReplyKeymap } from "./settings.js";

export class ReplyComponent implements Component, Focusable {
  private model: ReplyModel;
  private promptInput: Input | null = null;
  private yankHighlightTimer: ReturnType<typeof setTimeout> | null = null;

  private _focused = false;
  private readonly tui: TUI;
  private readonly theme: Theme;
  private readonly keymap: ReplyKeymap;
  private readonly done: (result: ReplyComponentResult) => void;
  private readonly onSave?: (text: string) => void;
  private readonly onRefresh?: () => string | null;
  private readonly onYank?: (text: string) => void | Promise<void>;
  private readonly onYankError?: (error: unknown) => void;

  constructor(
    tui: TUI,
    theme: Theme,
    sourceText: string,
    keymap: ReplyKeymap,
    done: (result: ReplyComponentResult) => void,
    onSave?: (text: string) => void,
    onRefresh?: () => string | null,
    onYank?: (text: string) => void | Promise<void>,
    onYankError?: (error: unknown) => void,
  ) {
    this.tui = tui;
    this.theme = theme;
    this.keymap = keymap;
    this.done = done;
    this.onSave = onSave;
    this.onRefresh = onRefresh;
    this.onYank = onYank;
    this.onYankError = onYankError;
    this.model = createReplyModel(sourceText, 80);
  }

  get focused(): boolean {
    return this._focused;
  }

  set focused(value: boolean) {
    this._focused = value;
    if (this.promptInput) this.promptInput.focused = value;
  }

  handleInput(data: string, allowWindowCommands = true): void {
    if (this.model.interaction.kind === "search") {
      if (matchesKey(data, this.keymap.open)) {
        this.dispatch({ type: "key", data });
        return;
      }
      const input = this.promptInput;
      if (!input) return;
      const before = input.getValue();
      input.handleInput(encodePastedNewlines(data));
      if (this.promptInput !== input) return;
      const query = input.getValue();
      if (query !== before) this.dispatch({ type: "search-change", query });
      else this.tui.requestRender();
      return;
    }

    if (this.model.interaction.kind === "comment") {
      this.promptInput?.handleInput(data);
      this.tui.requestRender();
      return;
    }

    this.dispatch({ type: "key", data, allowWindowCommands });
  }

  render(width: number): string[] {
    const outerWidth = Math.max(1, width);
    if (outerWidth < 3) return [truncateToWidth("Reply", outerWidth)];

    const innerWidth = outerWidth - 2;
    if (innerWidth !== this.model.lastInnerWidth) {
      this.dispatch({ type: "resize", innerWidth });
    }
    const result = renderReplyView(this.model, outerWidth, {
      theme: this.theme,
      focused: this.focused,
      viewportHeight: getReplyViewportHeight(
        this.model,
        this.tui.terminal.rows,
      ),
      promptInput: this.promptInput,
    });
    this.model.scrollTop = result.scrollTop;
    return result.lines;
  }

  invalidate(): void {
    this.tui.requestRender();
  }

  dispose(): void {
    this.dispatch({ type: "dispose" });
    if (this.yankHighlightTimer !== null) {
      clearTimeout(this.yankHighlightTimer);
      this.yankHighlightTimer = null;
    }
    this.promptInput = null;
  }

  private dispatch(message: ReplyMessage): void {
    const result = updateReply(this.model, message, {
      keymap: this.keymap,
      viewportHeight: getReplyViewportHeight(
        this.model,
        this.tui.terminal.rows,
      ),
    });
    this.model = result.model;
    if (
      this.model.interaction.kind !== "comment" &&
      this.model.interaction.kind !== "search"
    ) {
      this.promptInput = null;
    }
    for (const effect of result.effects) this.runEffect(effect);
  }

  private runEffect(effect: ReplyEffect): void {
    switch (effect.type) {
      case "request-render":
        this.tui.requestRender();
        return;
      case "open-comment-input":
        this.openCommentInput(effect.initialValue);
        return;
      case "open-search-input":
        this.openSearchInput();
        return;
      case "close":
        this.done(effect.result);
        return;
      case "save":
        this.onSave?.(effect.text);
        return;
      case "refresh": {
        const sourceText = this.onRefresh
          ? this.onRefresh()
          : this.model.rawSourceText;
        this.dispatch({ type: "refresh-result", sourceText });
        return;
      }
      case "copy":
        void Promise.resolve()
          .then(() => this.onYank?.(effect.text))
          .then(
            () =>
              this.dispatch({
                type: "yank-succeeded",
                operationId: effect.operationId,
                sessionId: effect.sessionId,
              }),
            (error: unknown) =>
              this.dispatch({
                type: "yank-failed",
                operationId: effect.operationId,
                sessionId: effect.sessionId,
                error,
              }),
          );
        return;
      case "notify-yank-error":
        this.onYankError?.(effect.error);
        return;
      case "schedule-yank-highlight-clear":
        if (this.yankHighlightTimer !== null) {
          clearTimeout(this.yankHighlightTimer);
        }
        this.yankHighlightTimer = setTimeout(() => {
          this.yankHighlightTimer = null;
          this.dispatch({
            type: "yank-highlight-expired",
            generation: effect.generation,
          });
        }, effect.delayMs);
        return;
    }
  }

  private openCommentInput(initialValue: string): void {
    const input = new Input();
    input.focused = this.focused;
    input.onSubmit = (comment) => {
      this.dispatch({ type: "comment-submit", comment });
    };
    input.onEscape = () => {
      this.dispatch({ type: "comment-cancel" });
    };
    if (initialValue.length > 0) {
      input.setValue(initialValue);
      input.handleInput("\x05");
    }
    this.promptInput = input;
  }

  private openSearchInput(): void {
    const input = new Input();
    input.focused = this.focused;
    input.onSubmit = (query) => {
      this.dispatch({ type: "search-submit", query });
    };
    input.onEscape = () => {
      this.dispatch({ type: "search-cancel" });
    };
    this.promptInput = input;
  }
}

function encodePastedNewlines(data: string): string {
  return data.replace(
    /\x1b\[200~([\s\S]*?)\x1b\[201~/g,
    (_match, content: string) =>
      `\x1b[200~${content.replace(/\r\n?|\n/g, "\\n")}\x1b[201~`,
  );
}
