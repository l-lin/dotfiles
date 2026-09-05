import type { Theme } from "@earendil-works/pi-coding-agent";
import { Input, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { getSelectionRange, type SelectionRange } from "./model.js";
import { ReplyRenderer, type DisplayRow } from "./render.js";
import type { ReplyInteraction, ReplyModel } from "./state.js";

export interface ReplyViewContext {
  theme: Theme;
  focused: boolean;
  viewportHeight: number;
  promptInput: Input | null;
}

export interface ReplyViewResult {
  lines: string[];
  scrollTop: number;
}

export function renderReplyView(
  model: ReplyModel,
  width: number,
  context: ReplyViewContext,
): ReplyViewResult {
  const innerWidth = Math.max(1, width - 2);
  const renderer = createRenderer(model, context.theme, context.focused);
  const displayRows = renderer.buildDisplayRows(innerWidth);
  const scrollTop = keepCursorVisible(
    renderer,
    displayRows,
    model.scrollTop,
    context.viewportHeight,
  );
  const visibleRows = displayRows.slice(
    scrollTop,
    scrollTop + context.viewportHeight,
  );

  while (visibleRows.length < context.viewportHeight) {
    visibleRows.push({
      kind: "source",
      line: -1,
      startGrapheme: 0,
      endGrapheme: 0,
      content: "",
    });
  }

  const lines: string[] = [topBorder(context.theme, innerWidth)];
  for (const row of visibleRows) {
    const content =
      row.kind === "source" && row.line === -1
        ? ""
        : row.kind === "source"
          ? ` ${row.content}`
          : row.content;
    lines.push(frameLine(context.theme, content, innerWidth));
  }

  if (model.interaction.kind === "comment") {
    // AI: render Pi's Input here so its IME cursor marker stays in the popup.
    const inputWidth = Math.max(1, innerWidth - 1);
    const renderedInput = context.promptInput?.render(inputWidth)[0] ?? "";
    lines.push(
      frameLine(
        context.theme,
        ` # ${stripInputPrompt(renderedInput)}`,
        innerWidth,
      ),
    );
  }

  const searchStatus = renderSearchStatus(
    model,
    innerWidth,
    context.promptInput,
  );
  if (searchStatus !== null) {
    lines.push(frameLine(context.theme, searchStatus, innerWidth));
  }
  lines.push(bottomBorder(context.theme, innerWidth));

  return { lines, scrollTop };
}

export function getReplyViewportHeight(
  model: ReplyModel,
  terminalRows: number,
): number {
  const frameRows = Math.floor(terminalRows * 0.85);
  const fixedRows =
    2 +
    (model.interaction.kind === "comment" ? 1 : 0) +
    (model.interaction.kind === "search" || model.search !== null ? 1 : 0);
  return Math.max(1, frameRows - fixedRows);
}

function createRenderer(
  model: ReplyModel,
  theme: Theme,
  focused: boolean,
): ReplyRenderer {
  return new ReplyRenderer(
    theme,
    model.layout.document,
    model.annotations,
    {
      cursor: model.cursor,
      activeSelection: activeSelection(model),
      searchMatches: model.search?.matches ?? [],
      currentSearchMatch:
        model.search && model.search.currentIndex >= 0
          ? model.search.matches[model.search.currentIndex]!
          : null,
      yankHighlight: model.yank.highlight,
      hasCommentInput: model.interaction.kind === "comment",
      focused,
    },
    model.layout.renderedLines,
  );
}

function activeSelection(model: ReplyModel): SelectionRange | null {
  const interaction = activeEditingInteraction(model);
  return interaction.kind === "visual"
    ? getSelectionRange(
        model.layout.document,
        interaction.anchor,
        model.cursor,
        interaction.visualMode,
      )
    : interaction.kind === "comment"
      ? interaction.selection
      : null;
}

function activeEditingInteraction(
  model: ReplyModel,
):
  | Extract<ReplyInteraction, { kind: "normal" | "visual" }>
  | Extract<ReplyInteraction, { kind: "comment" }> {
  if (model.interaction.kind === "search") {
    return model.interaction.before.interaction;
  }
  return model.interaction;
}

function keepCursorVisible(
  renderer: ReplyRenderer,
  rows: DisplayRow[],
  currentScrollTop: number,
  viewportHeight: number,
): number {
  let scrollTop = currentScrollTop;
  const cursorRow = renderer.findCursorRow(rows);
  if (cursorRow >= 0) {
    if (cursorRow < scrollTop) scrollTop = cursorRow;
    if (cursorRow >= scrollTop + viewportHeight) {
      scrollTop = cursorRow - viewportHeight + 1;
    }
  }
  return Math.max(
    0,
    Math.min(scrollTop, Math.max(0, rows.length - viewportHeight)),
  );
}

function renderSearchStatus(
  model: ReplyModel,
  width: number,
  promptInput: Input | null,
): string | null {
  if (model.interaction.kind === "search") {
    const query = promptInput?.getValue() ?? "";
    const prefix = model.interaction.prefix;
    if (query.length === 0) {
      const renderedInput =
        promptInput?.render(Math.max(3, width - prefix.length))[0] ?? "";
      return `${prefix}${stripInputPrompt(renderedInput)}`;
    }

    const search = model.search;
    if (!search) return null;
    const index =
      search.currentIndex < 0 ? "-" : String(search.currentIndex + 1);
    const count = `[${index}/${search.matches.length}]`;
    const queryWidth = Math.max(1, width - prefix.length - count.length - 1);
    const renderedInput = promptInput?.render(queryWidth + 2)[0] ?? "";
    const renderedQuery = stripInputPrompt(renderedInput).replace(/ +$/u, "");
    return `${prefix}${renderedQuery}${count}`;
  }

  if (!model.search) return null;
  const index =
    model.search.currentIndex < 0 ? "-" : String(model.search.currentIndex + 1);
  return `${model.search.prefix}${model.search.query} [${index}/${model.search.matches.length}]`;
}

function topBorder(theme: Theme, width: number): string {
  const title = theme.fg("accent", theme.bold(" Reply "));
  const titleWidth = visibleWidth(title);
  const leftWidth = Math.floor(Math.max(0, width - titleWidth) / 2);
  const rightWidth = Math.max(0, width - titleWidth - leftWidth);
  return (
    theme.fg("border", `╭${"─".repeat(leftWidth)}`) +
    title +
    theme.fg("border", `${"─".repeat(rightWidth)}╮`)
  );
}

function bottomBorder(theme: Theme, width: number): string {
  return theme.fg("border", `╰${"─".repeat(width)}╯`);
}

function frameLine(theme: Theme, content: string, width: number): string {
  const fitted = truncateToWidth(content, width, "", true);
  const padding = " ".repeat(Math.max(0, width - visibleWidth(fitted)));
  return theme.fg("border", "│") + fitted + padding + theme.fg("border", "│");
}

function stripInputPrompt(renderedInput: string): string {
  return renderedInput.startsWith("> ")
    ? renderedInput.slice(2)
    : renderedInput;
}
