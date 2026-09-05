import { ReplyComponent } from "./component.js";
import { REPLY_KEYMAP } from "./settings.js";
import type { CursorPosition, SelectionRange } from "./model.js";
import type { ReplyInteraction, ReplyModel } from "./state.js";

export function given_tui(rows = 24) {
  let renderRequests = 0;
  return {
    tui: {
      terminal: { rows },
      requestRender() {
        renderRequests++;
      },
    },
    getRenderRequests() {
      return renderRequests;
    },
  };
}

export function given_theme() {
  return {
    fg(_color: string, text: string) {
      return text;
    },
    bg(_color: string, text: string) {
      return text;
    },
    bold(text: string) {
      return text;
    },
    underline(text: string) {
      return `\x1b[4m${text}\x1b[24m`;
    },
  };
}

export function given_component(
  source: string,
  rows = 24,
  onYank?: (text: string) => void | Promise<void>,
  onYankError?: (error: unknown) => void,
) {
  const tui = given_tui(rows);
  let actualResult: unknown;
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    source,
    REPLY_KEYMAP,
    (result) => {
      actualResult = result;
    },
    undefined,
    undefined,
    onYank,
    onYankError,
  );
  return {
    component,
    tui,
    getResult() {
      return actualResult;
    },
  };
}

export function when_typing(component: ReplyComponent, text: string): void {
  for (const character of text) component.handleInput(character);
}

export function when_backspacing(
  component: ReplyComponent,
  text: string,
): void {
  for (const _character of text) component.handleInput("\x7f");
}

function then_model(component: ReplyComponent): ReplyModel {
  return (component as unknown as { model: ReplyModel }).model;
}

export function then_cursor(component: ReplyComponent): CursorPosition {
  return { ...then_model(component).cursor };
}

export function then_scroll_top(component: ReplyComponent): number {
  return then_model(component).scrollTop;
}

function then_editing_interaction(component: ReplyComponent): ReplyInteraction {
  const interaction = then_model(component).interaction;
  return interaction.kind === "search"
    ? interaction.before.interaction
    : interaction;
}

export function then_mode(component: ReplyComponent): "normal" | "visual" {
  const interaction = then_editing_interaction(component);
  return interaction.kind === "visual" ? "visual" : "normal";
}

export function then_visual_anchor(
  component: ReplyComponent,
): CursorPosition | null {
  const interaction = then_editing_interaction(component);
  return interaction.kind === "visual" ? { ...interaction.anchor } : null;
}

export function then_yank_highlight(
  component: ReplyComponent,
): SelectionRange | null {
  const highlight = then_model(component).yank.highlight;
  return highlight ? { ...highlight } : null;
}

export function then_render_text(component: ReplyComponent): string {
  return component
    .render(50)
    .join("\n")
    .replace(/\x1b\[[0-9;]*m/gu, "");
}

export async function when_yank_settles(): Promise<void> {
  await new Promise<void>((resolve) => setTimeout(resolve, 0));
}
