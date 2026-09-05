import { matchesKey, visibleWidth } from "@earendil-works/pi-tui";
import type { Theme } from "@earendil-works/pi-coding-agent";
import {
  cursorOffset,
  cursorPositionAtSearchMatch,
  decodeSearchQuery,
  findKeywordAtCursor,
  findKeywordSearchMatches,
  findLiteralSearchMatches,
  formatAnnotatedText,
  getSelectionRange,
  normalizePlatformLineEndings,
  searchMatchContainsCursor,
  selectionContainsOffset,
  type Annotation,
  type CursorPosition,
  type SearchDirection,
  type SearchMatch,
  type SelectionRange,
  type VisualMode,
} from "./model.js";
import {
  findCharMotionTarget,
  findWordMotionTarget,
  firstNonBlankColumn,
  isPrintableAscii,
  reverseCharMotion,
} from "../vim/motions.js";
import type { CharMotion } from "../vim/types.js";
import {
  displayRowColumn,
  graphemeAtOrBeforeColumn,
  graphemeAtOrBeforeDisplayColumn,
  ReplyRenderer,
  type DisplayRow,
} from "./render.js";
import type { ReplyKeymap } from "./settings.js";
import type {
  MotionPending,
  NormalPending,
  ReplyComponentResult,
  ReplyInteraction,
  ReplyModel,
  SearchSnapshot,
  SearchState,
} from "./state.js";
import { createReplyModel } from "./state.js";
import { reflowReplyModel } from "./layout.js";

export type ReplyMessage =
  | { type: "key"; data: string; allowWindowCommands?: boolean }
  | { type: "comment-submit"; comment: string }
  | { type: "comment-cancel" }
  | { type: "search-change"; query: string }
  | { type: "search-submit"; query: string }
  | { type: "search-cancel" }
  | { type: "refresh-result"; sourceText: string | null }
  | { type: "yank-succeeded"; operationId: number; sessionId: number }
  | {
      type: "yank-failed";
      operationId: number;
      sessionId: number;
      error: unknown;
    }
  | { type: "yank-highlight-expired"; generation: number }
  | { type: "resize"; innerWidth: number }
  | { type: "dispose" };

export type ReplyEffect =
  | { type: "request-render" }
  | { type: "open-comment-input"; initialValue: string }
  | { type: "open-search-input" }
  | { type: "close"; result: ReplyComponentResult }
  | { type: "save"; text: string }
  | { type: "refresh" }
  | {
      type: "copy";
      text: string;
      selection: SelectionRange;
      startedVisual: boolean;
      operationId: number;
      sessionId: number;
    }
  | { type: "notify-yank-error"; error: unknown }
  | {
      type: "schedule-yank-highlight-clear";
      generation: number;
      delayMs: number;
    };

export interface UpdateContext {
  keymap: ReplyKeymap;
  viewportHeight: number;
}

export interface UpdateResult {
  model: ReplyModel;
  effects: ReplyEffect[];
}

export function updateReply(
  model: ReplyModel,
  message: ReplyMessage,
  context: UpdateContext,
): UpdateResult {
  if (model.disposed && message.type !== "dispose") {
    return { model, effects: [] };
  }

  switch (message.type) {
    case "key":
      return { model, effects: handleKey(model, message, context) };
    case "comment-submit":
      return { model, effects: submitComment(model, message.comment) };
    case "comment-cancel":
      return { model, effects: cancelComment(model) };
    case "search-change":
      return { model, effects: changeSearch(model, message.query) };
    case "search-submit":
      return { model, effects: submitSearch(model, message.query) };
    case "search-cancel":
      return { model, effects: cancelSearch(model) };
    case "refresh-result":
      return refreshModel(model, message.sourceText);
    case "yank-succeeded":
      return { model, effects: yankSucceeded(model, message) };
    case "yank-failed":
      return { model, effects: yankFailed(model, message) };
    case "yank-highlight-expired":
      return { model, effects: expireYankHighlight(model, message.generation) };
    case "resize":
      reflowReplyModel(model, message.innerWidth);
      return { model, effects: requestRender() };
    case "dispose":
      model.disposed = true;
      model.yank.sessionId++;
      model.yank.highlight = null;
      model.yank.pendingSelection = null;
      model.yank.pendingSelections.clear();
      return { model, effects: [] };
  }
}

function handleKey(
  model: ReplyModel,
  message: Extract<ReplyMessage, { type: "key" }>,
  context: UpdateContext,
): ReplyEffect[] {
  const { data } = message;
  const allowWindowCommands = message.allowWindowCommands ?? true;

  if (matchesKey(data, context.keymap.open)) return [{ type: "refresh" }];

  if (
    model.interaction.kind === "comment" ||
    model.interaction.kind === "search"
  ) {
    return [];
  }

  if (model.interaction.kind === "normal") {
    if (model.interaction.pending.kind === "yank") {
      return handlePendingYank(model, data, context);
    }
    if (model.interaction.pending.kind === "motion") {
      return handlePendingMotion(model, data, context);
    }
  } else if (model.interaction.pending.kind !== "none") {
    return handlePendingMotion(model, data, context);
  }

  if (isNormal(model) && matchesKey(data, context.keymap.edit)) {
    const annotation = findAnnotationAtCursor(model);
    if (annotation) return openComment(model, annotation);
    return [];
  }

  if (isNormal(model) && matchesKey(data, context.keymap.delete)) {
    const annotation = findAnnotationAtCursor(model);
    if (!annotation) return [];
    const index = model.annotations.indexOf(annotation);
    if (index >= 0) model.annotations.splice(index, 1);
    return requestRender();
  }

  if (matchesKey(data, context.keymap.searchForward)) {
    return beginSearch(model, "forward", "/");
  }
  if (matchesKey(data, context.keymap.searchBackward)) {
    return beginSearch(model, "backward", "?");
  }
  if (matchesKey(data, context.keymap.wordSearchForward)) {
    return searchWord(model, "forward");
  }
  if (matchesKey(data, context.keymap.wordSearchBackward)) {
    return searchWord(model, "backward");
  }

  if (matchesKey(data, context.keymap.close)) {
    if (isVisual(model)) {
      setNormal(model);
      return requestRender();
    }
    return [{ type: "close", result: { action: "cancel" } }];
  }

  if (
    isVisual(model) &&
    (matchesKey(data, context.keymap.yank) ||
      matchesKey(data, context.keymap.lineYank))
  ) {
    return beginYankVisual(model);
  }

  if (isVisual(model) && matchesKey(data, context.keymap.comment)) {
    return openComment(model);
  }

  if (isNormal(model) && matchesKey(data, context.keymap.lineYank)) {
    return beginYank(model, linewiseSelection(model, model.cursor), false);
  }

  if (isNormal(model) && matchesKey(data, context.keymap.yank)) {
    model.interaction.pending = { kind: "yank", yank: { kind: "operator" } };
    return requestRender();
  }

  if (isNormal(model) && matchesKey(data, context.keymap.save)) {
    if (model.annotations.length === 0) {
      return [{ type: "close", result: { action: "cancel" } }];
    }
    const text = formatAnnotatedText(model.annotations);
    return [
      { type: "save", text },
      { type: "close", result: { action: "save", text } },
    ];
  }

  if (isNormal(model) && matchesKey(data, context.keymap.characterVisual)) {
    enterVisual(model, "character");
    return requestRender();
  }
  if (isNormal(model) && matchesKey(data, context.keymap.lineVisual)) {
    enterVisual(model, "line");
    return requestRender();
  }
  if (isVisual(model) && matchesKey(data, context.keymap.characterVisual)) {
    if (model.interaction.visualMode === "character") setNormal(model);
    else model.interaction.visualMode = "character";
    return requestRender();
  }
  if (isVisual(model) && matchesKey(data, context.keymap.lineVisual)) {
    if (model.interaction.visualMode === "line") setNormal(model);
    else model.interaction.visualMode = "line";
    return requestRender();
  }
  if (isVisual(model) && matchesKey(data, context.keymap.visualSwapCursor)) {
    swapVisualCursor(model);
    return requestRender();
  }

  return handleMovement(model, data, allowWindowCommands, context);
}

function handlePendingMotion(
  model: ReplyModel,
  data: string,
  context: UpdateContext,
): ReplyEffect[] {
  const pending = getMotionPending(model);
  if (!pending) return [];
  setMotionPending(model, { kind: "none" });

  if (matchesKey(data, context.keymap.escape)) return requestRender();
  if (pending.kind === "g") {
    if (matchesKey(data, context.keymap.lineMotionPrefix)) {
      moveToLine(model, 0);
      return requestRender();
    }
    if (matchesKey(data, context.keymap.down)) {
      moveDisplayRow(model, 1, context.viewportHeight);
      return requestRender();
    }
    if (matchesKey(data, context.keymap.up)) {
      moveDisplayRow(model, -1, context.viewportHeight);
      return requestRender();
    }
    return handleKey(
      model,
      { type: "key", data, allowWindowCommands: false },
      context,
    );
  }
  if (pending.kind === "char") {
    if (!isPrintableAscii(data)) return requestRender();
    executeCharMotion(model, pending.motion, data);
    return requestRender();
  }
  if (pending.kind === "z") {
    if (data === "z") positionViewport(model, "center", context.viewportHeight);
    else if (data === "t")
      positionViewport(model, "top", context.viewportHeight);
    else if (data === "b")
      positionViewport(model, "bottom", context.viewportHeight);
    else return handleKey(model, { type: "key", data }, context);
    return requestRender();
  }

  return handleKey(model, { type: "key", data }, context);
}

function handlePendingYank(
  model: ReplyModel,
  data: string,
  context: UpdateContext,
): ReplyEffect[] {
  if (
    model.interaction.kind !== "normal" ||
    model.interaction.pending.kind !== "yank"
  ) {
    return [];
  }
  const pending = model.interaction.pending.yank;

  if (matchesKey(data, context.keymap.escape)) {
    setNormalPending(model);
    return requestRender();
  }

  if (pending.kind === "operator") {
    if (matchesKey(data, context.keymap.yank)) {
      setNormalPending(model);
      return beginYank(model, linewiseSelection(model, model.cursor), false);
    }
    if (matchesKey(data, context.keymap.lineMotionPrefix)) {
      model.interaction.pending = { kind: "yank", yank: { kind: "g" } };
      return requestRender();
    }
    if (data === "i" || data === "a") {
      model.interaction.pending = {
        kind: "yank",
        yank: { kind: "text-object", outer: data === "a" },
      };
      return requestRender();
    }

    const charMotion = getCharMotion(data, context.keymap);
    if (charMotion) {
      model.interaction.pending = {
        kind: "yank",
        yank: { kind: "char", motion: charMotion },
      };
      return requestRender();
    }

    setNormalPending(model);
    const selection = selectionForYankMotion(model, data, context);
    if (selection !== undefined) return beginYank(model, selection, false);
    return handleKey(
      model,
      { type: "key", data, allowWindowCommands: false },
      context,
    );
  }

  if (pending.kind === "g") {
    setNormalPending(model);
    if (matchesKey(data, context.keymap.lineMotionPrefix)) {
      const destination = previewMotion(model, () => moveToLine(model, 0));
      return beginYank(model, linewiseSelection(model, destination), false);
    }
    if (matchesKey(data, context.keymap.down)) {
      const destination = previewMotion(model, () =>
        moveDisplayRow(model, 1, context.viewportHeight),
      );
      return beginYank(
        model,
        sameCursor(model.cursor, destination)
          ? null
          : characterwiseSelection(model, model.cursor, destination),
        false,
      );
    }
    if (matchesKey(data, context.keymap.up)) {
      const destination = previewMotion(model, () =>
        moveDisplayRow(model, -1, context.viewportHeight),
      );
      return beginYank(
        model,
        sameCursor(model.cursor, destination)
          ? null
          : characterwiseSelection(model, model.cursor, destination),
        false,
      );
    }
    return handleKey(
      model,
      { type: "key", data, allowWindowCommands: false },
      context,
    );
  }

  if (pending.kind === "char") {
    setNormalPending(model);
    if (!isPrintableAscii(data)) return requestRender();
    const target = findCharMotionTarget(
      currentLineGraphemes(model),
      model.cursor.grapheme,
      pending.motion,
      data,
    );
    if (target === null) return requestRender();
    model.lastCharMotion = { motion: pending.motion, char: data };
    return beginYank(
      model,
      characterwiseSelection(model, model.cursor, {
        line: model.cursor.line,
        grapheme: target,
      }),
      false,
    );
  }

  setNormalPending(model);
  if (!matchesKey(data, context.keymap.wordForward)) {
    return handleKey(
      model,
      { type: "key", data, allowWindowCommands: false },
      context,
    );
  }
  return beginYank(model, wordObjectSelection(model, pending.outer), false);
}

function handleMovement(
  model: ReplyModel,
  data: string,
  allowWindowCommands: boolean,
  context: UpdateContext,
): ReplyEffect[] {
  if (matchesKey(data, context.keymap.left)) moveHorizontal(model, -1);
  else if (matchesKey(data, context.keymap.right)) moveHorizontal(model, 1);
  else if (matchesKey(data, context.keymap.down)) moveLogicalLine(model, 1);
  else if (matchesKey(data, context.keymap.up)) moveLogicalLine(model, -1);
  else if (matchesKey(data, context.keymap.halfPageUp))
    scrollHalfPage(model, -1, context.viewportHeight);
  else if (matchesKey(data, context.keymap.halfPageDown))
    scrollHalfPage(model, 1, context.viewportHeight);
  else if (matchesKey(data, context.keymap.lineMotionPrefix))
    setMotionPending(model, { kind: "g" });
  else if (
    allowWindowCommands &&
    (isNormal(model) || isVisual(model)) &&
    data === "z"
  )
    setMotionPending(model, { kind: "z" });
  else if (matchesKey(data, context.keymap.lastLine))
    moveToLine(model, model.layout.document.lines.length - 1);
  else if (matchesKey(data, context.keymap.wordForward))
    moveWord(model, "forward", "start");
  else if (matchesKey(data, context.keymap.wordBackward))
    moveWord(model, "backward", "start");
  else if (matchesKey(data, context.keymap.wordEnd))
    moveWord(model, "forward", "end");
  else if (matchesKey(data, context.keymap.searchNext))
    repeatSearch(model, "same");
  else if (matchesKey(data, context.keymap.searchPrevious))
    repeatSearch(model, "opposite");
  else if (matchesKey(data, context.keymap.lineStart)) moveToColumn(model, 0);
  else if (matchesKey(data, context.keymap.firstNonBlank))
    moveToColumn(model, firstNonBlankColumn(currentLineGraphemes(model)));
  else if (matchesKey(data, context.keymap.lineEnd))
    moveToColumn(model, currentLineGraphemes(model).length - 1);
  else {
    const charMotion = getCharMotion(data, context.keymap);
    if (charMotion)
      setMotionPending(model, { kind: "char", motion: charMotion });
    else if (
      matchesKey(data, context.keymap.repeatForward) ||
      matchesKey(data, context.keymap.repeatBackward)
    ) {
      if (!model.lastCharMotion) return [];
      const motion = matchesKey(data, context.keymap.repeatForward)
        ? model.lastCharMotion.motion
        : reverseCharMotion(model.lastCharMotion.motion);
      executeCharMotion(model, motion, model.lastCharMotion.char, false);
    } else return [];
  }
  return requestRender();
}

function beginSearch(
  model: ReplyModel,
  direction: SearchDirection,
  prefix: "/" | "?",
): ReplyEffect[] {
  const before = createSearchSnapshot(model);
  model.interaction = { kind: "search", direction, prefix, before };
  return [{ type: "open-search-input" }, ...requestRender()];
}

function changeSearch(model: ReplyModel, query: string): ReplyEffect[] {
  if (model.interaction.kind !== "search") return [];
  if (query.length === 0) {
    restoreSearchSnapshot(model, model.interaction.before);
    return requestRender();
  }
  updateLiveSearch(model, query);
  return requestRender();
}

function submitSearch(model: ReplyModel, query: string): ReplyEffect[] {
  if (model.interaction.kind !== "search") return [];
  if (query.length === 0) {
    model.search = null;
  } else {
    updateLiveSearch(model, query);
  }
  const before = model.interaction.before;
  model.interaction = cloneInteraction(before.interaction);
  return requestRender();
}

function cancelSearch(model: ReplyModel): ReplyEffect[] {
  if (model.interaction.kind !== "search") return [];
  restoreSearchSnapshot(model, model.interaction.before);
  return requestRender();
}

function updateLiveSearch(model: ReplyModel, query: string): void {
  if (model.interaction.kind !== "search") return;
  const decodedQuery = decodeSearchQuery(query);
  const matches = findLiteralSearchMatches(
    model.layout.document.text,
    decodedQuery,
  );
  const currentIndex = findSearchMatchIndex(
    matches,
    model.interaction.direction,
    cursorOffset(model.layout.document, model.interaction.before.cursor),
    true,
  );
  model.search = {
    query,
    prefix: model.interaction.prefix,
    direction: model.interaction.direction,
    kind: "literal",
    matches,
    currentIndex,
  };
  if (currentIndex >= 0) moveToSearchMatch(model, matches[currentIndex]!);
}

function repeatSearch(model: ReplyModel, direction: "same" | "opposite"): void {
  if (!model.search || model.search.matches.length === 0) return;
  const searchDirection =
    direction === "same"
      ? model.search.direction
      : model.search.direction === "forward"
        ? "backward"
        : "forward";
  const currentIndex = findSearchMatchIndex(
    model.search.matches,
    searchDirection,
    cursorOffset(model.layout.document, model.cursor),
    false,
  );
  if (currentIndex < 0) return;
  model.search.currentIndex = currentIndex;
  moveToSearchMatch(model, model.search.matches[currentIndex]!);
}

function searchWord(
  model: ReplyModel,
  direction: SearchDirection,
): ReplyEffect[] {
  const keyword = findKeywordAtCursor(model.layout.document, model.cursor);
  if (keyword === null) return [];
  const matches = findKeywordSearchMatches(model.layout.document, keyword);
  const currentIndex = matches.findIndex((match) =>
    searchMatchContainsCursor(model.layout.document, match, model.cursor),
  );
  if (currentIndex < 0) return [];
  model.search = {
    query: keyword,
    prefix: direction === "forward" ? "/" : "?",
    direction,
    kind: "word",
    matches,
    currentIndex,
  };
  moveToSearchMatch(model, matches[currentIndex]!);
  return requestRender();
}

function findSearchMatchIndex(
  matches: readonly SearchMatch[],
  direction: SearchDirection,
  offset: number,
  includeCurrent: boolean,
): number {
  if (matches.length === 0) return -1;
  if (includeCurrent) {
    const currentIndex = matches.findIndex(
      (match) => match.start <= offset && offset < match.end,
    );
    if (currentIndex >= 0) return currentIndex;
  }
  if (direction === "forward") {
    const comparison = includeCurrent
      ? (match: SearchMatch) => match.start >= offset
      : (match: SearchMatch) => match.start > offset;
    const nextIndex = matches.findIndex(comparison);
    return nextIndex >= 0 ? nextIndex : 0;
  }
  const comparison = includeCurrent
    ? (match: SearchMatch) => match.start <= offset
    : (match: SearchMatch) => match.start < offset;
  for (let index = matches.length - 1; index >= 0; index--) {
    if (comparison(matches[index]!)) return index;
  }
  return matches.length - 1;
}

function moveToSearchMatch(model: ReplyModel, match: SearchMatch): void {
  model.cursor = cursorPositionAtSearchMatch(model.layout.document, match);
  model.preferredColumn = null;
}

function createSearchSnapshot(model: ReplyModel): SearchSnapshot {
  const interaction = editingInteraction(model);
  return {
    cursor: { ...model.cursor },
    preferredColumn: clonePreferredColumn(model.preferredColumn),
    interaction: cloneEditingInteraction(interaction),
    search: cloneSearch(model.search),
  };
}

function restoreSearchSnapshot(
  model: ReplyModel,
  snapshot: SearchSnapshot,
): void {
  model.cursor = { ...snapshot.cursor };
  model.preferredColumn = clonePreferredColumn(snapshot.preferredColumn);
  model.interaction = cloneInteraction(snapshot.interaction);
  model.search = cloneSearch(snapshot.search);
}

function openComment(
  model: ReplyModel,
  annotation: Annotation | null = null,
): ReplyEffect[] {
  const selection = annotation ?? visualSelection(model);
  if (!selection || selection.start === selection.end) {
    if (!annotation) setNormal(model);
    return requestRender();
  }
  const returnTo = annotation ? "normal" : "visual";
  const anchor =
    !annotation && isVisual(model) ? { ...model.interaction.anchor } : null;
  model.interaction = {
    kind: "comment",
    selection,
    annotationId: annotation?.id ?? null,
    returnTo,
    anchor,
  };
  return [
    {
      type: "open-comment-input",
      initialValue: annotation?.comment ?? "",
    },
    ...requestRender(),
  ];
}

function submitComment(model: ReplyModel, comment: string): ReplyEffect[] {
  if (model.interaction.kind !== "comment") return [];
  const { annotationId, selection, returnTo, anchor } = model.interaction;
  if (comment.trim().length === 0) {
    restoreCommentMode(model, returnTo, anchor, selection);
    return requestRender();
  }
  if (annotationId !== null) {
    const annotation = model.annotations.find(
      (item) => item.id === annotationId,
    );
    if (annotation) annotation.comment = comment;
  } else {
    model.annotations.push({
      id: model.nextAnnotationId++,
      start: selection.start,
      end: selection.end,
      text: selection.text,
      comment,
    });
  }
  setNormal(model);
  return requestRender();
}

function cancelComment(model: ReplyModel): ReplyEffect[] {
  if (model.interaction.kind !== "comment") return [];
  const { returnTo, anchor, selection } = model.interaction;
  restoreCommentMode(model, returnTo, anchor, selection);
  return requestRender();
}

function restoreCommentMode(
  model: ReplyModel,
  returnTo: "normal" | "visual",
  anchor: CursorPosition | null,
  selection: SelectionRange,
): void {
  if (returnTo === "normal") {
    setNormal(model);
    return;
  }
  model.interaction = {
    kind: "visual",
    visualMode: "character",
    anchor: anchor ?? cursorPositionAtOffset(model, selection.start),
    pending: { kind: "none" },
  };
}

function cursorPositionAtOffset(
  model: ReplyModel,
  offset: number,
): CursorPosition {
  const boundedOffset = Math.max(
    0,
    Math.min(offset, model.layout.document.text.length),
  );
  const document = model.layout.document;
  for (let lineIndex = 0; lineIndex < document.lines.length; lineIndex++) {
    const line = document.lines[lineIndex]!;
    const lineEnd = line.start + line.text.length;
    if (boundedOffset < lineEnd) {
      const grapheme = line.graphemes.findIndex(
        (item) => line.start + item.end > boundedOffset,
      );
      return { line: lineIndex, grapheme: Math.max(0, grapheme) };
    }
    if (boundedOffset === lineEnd && lineIndex < document.lines.length - 1) {
      return { line: lineIndex + 1, grapheme: 0 };
    }
  }
  const lastLine = document.lines.length - 1;
  return { line: Math.max(0, lastLine), grapheme: 0 };
}

function visualSelection(model: ReplyModel): SelectionRange | null {
  return isVisual(model)
    ? getSelectionRange(
        model.layout.document,
        model.interaction.anchor,
        model.cursor,
        model.interaction.visualMode,
      )
    : null;
}

function beginYankVisual(model: ReplyModel): ReplyEffect[] {
  return beginYank(model, visualSelection(model), true);
}

function beginYank(
  model: ReplyModel,
  selection: SelectionRange | null,
  startedVisual: boolean,
): ReplyEffect[] {
  if (!selection || selection.start === selection.end) return [];
  const operationId = ++model.yank.operationId;
  const sessionId = model.yank.sessionId;
  model.yank.pendingSelection = { ...selection };
  model.yank.pendingSelections.set(operationId, { ...selection });
  const text = normalizePlatformLineEndings(selection.text);
  return [
    {
      type: "copy",
      text,
      selection,
      startedVisual,
      operationId,
      sessionId,
    },
  ];
}

function yankSucceeded(
  model: ReplyModel,
  message: Extract<ReplyMessage, { type: "yank-succeeded" }>,
): ReplyEffect[] {
  if (
    message.sessionId !== model.yank.sessionId ||
    message.operationId > model.yank.operationId
  )
    return [];
  const selection = model.yank.pendingSelections.get(message.operationId);
  model.yank.pendingSelections.delete(message.operationId);
  model.yank.pendingSelection = null;
  if (isVisual(model)) setNormal(model);
  if (
    !selection ||
    message.operationId < model.yank.latestSuccessfulOperationId
  ) {
    return requestRender();
  }
  model.yank.latestSuccessfulOperationId = message.operationId;
  model.yank.generation++;
  model.yank.highlight = { ...selection };
  return [
    {
      type: "schedule-yank-highlight-clear",
      generation: model.yank.generation,
      delayMs: 500,
    },
    ...requestRender(),
  ];
}

function yankFailed(
  model: ReplyModel,
  message: Extract<ReplyMessage, { type: "yank-failed" }>,
): ReplyEffect[] {
  if (
    message.sessionId !== model.yank.sessionId ||
    message.operationId > model.yank.operationId
  )
    return [];
  model.yank.pendingSelections.delete(message.operationId);
  model.yank.pendingSelection = null;
  if (isVisual(model)) setNormal(model);
  if (message.operationId >= model.yank.latestSuccessfulOperationId) {
    model.yank.generation++;
    model.yank.highlight = null;
  }
  return [
    { type: "notify-yank-error", error: message.error },
    ...requestRender(),
  ];
}

function expireYankHighlight(
  model: ReplyModel,
  generation: number,
): ReplyEffect[] {
  if (generation !== model.yank.generation) return [];
  model.yank.highlight = null;
  return requestRender();
}

function refreshModel(
  model: ReplyModel,
  sourceText: string | null,
): UpdateResult {
  if (sourceText === null) {
    return {
      model,
      effects: [{ type: "close", result: { action: "cancel" } }],
    };
  }
  const next = createReplyModel(sourceText, model.lastInnerWidth);
  next.yank.sessionId = model.yank.sessionId + 1;
  return { model: next, effects: requestRender() };
}

function isNormal(model: ReplyModel): model is ReplyModel & {
  interaction: Extract<ReplyInteraction, { kind: "normal" }>;
} {
  return model.interaction.kind === "normal";
}

function isVisual(model: ReplyModel): model is ReplyModel & {
  interaction: Extract<ReplyInteraction, { kind: "visual" }>;
} {
  return model.interaction.kind === "visual";
}

function setNormal(model: ReplyModel): void {
  model.interaction = { kind: "normal", pending: { kind: "none" } };
}

function setNormalPending(model: ReplyModel): void {
  if (isNormal(model)) model.interaction.pending = { kind: "none" };
}

function enterVisual(model: ReplyModel, visualMode: VisualMode): void {
  model.interaction = {
    kind: "visual",
    visualMode,
    anchor: { ...model.cursor },
    pending: { kind: "none" },
  };
}

function swapVisualCursor(model: ReplyModel): void {
  if (!isVisual(model)) return;
  const anchor = model.interaction.anchor;
  model.interaction.anchor = { ...model.cursor };
  model.cursor = { ...anchor };
  model.preferredColumn = null;
}

function editingInteraction(
  model: ReplyModel,
): Extract<ReplyInteraction, { kind: "normal" | "visual" }> {
  if (model.interaction.kind === "search")
    return model.interaction.before.interaction;
  if (model.interaction.kind === "comment") {
    return { kind: "normal", pending: { kind: "none" } };
  }
  return model.interaction;
}

function cloneEditingInteraction(
  interaction: Extract<ReplyInteraction, { kind: "normal" | "visual" }>,
): Extract<ReplyInteraction, { kind: "normal" | "visual" }> {
  return cloneInteraction(interaction) as Extract<
    ReplyInteraction,
    { kind: "normal" | "visual" }
  >;
}

function cloneInteraction(interaction: ReplyInteraction): ReplyInteraction {
  switch (interaction.kind) {
    case "normal":
      return {
        kind: "normal",
        pending: cloneNormalPending(interaction.pending),
      };
    case "visual":
      return {
        kind: "visual",
        visualMode: interaction.visualMode,
        anchor: { ...interaction.anchor },
        pending: cloneMotionPending(interaction.pending),
      };
    case "comment":
      return {
        kind: "comment",
        selection: { ...interaction.selection },
        annotationId: interaction.annotationId,
        returnTo: interaction.returnTo,
        anchor: interaction.anchor ? { ...interaction.anchor } : null,
      };
    case "search":
      return {
        kind: "search",
        direction: interaction.direction,
        prefix: interaction.prefix,
        before: {
          cursor: { ...interaction.before.cursor },
          preferredColumn: clonePreferredColumn(
            interaction.before.preferredColumn,
          ),
          interaction: cloneEditingInteraction(interaction.before.interaction),
          search: cloneSearch(interaction.before.search),
        },
      };
  }
}

function clonePreferredColumn(
  preferredColumn: ReplyModel["preferredColumn"],
): ReplyModel["preferredColumn"] {
  return preferredColumn ? { ...preferredColumn } : null;
}

function cloneSearch(search: SearchState | null): SearchState | null {
  return search
    ? { ...search, matches: search.matches.map((match) => ({ ...match })) }
    : null;
}

function cloneMotionPending(pending: MotionPending): MotionPending {
  return pending.kind === "char" ? { ...pending } : { kind: pending.kind };
}

function cloneNormalPending(pending: NormalPending): NormalPending {
  if (pending.kind === "motion") {
    return {
      kind: "motion",
      motion: cloneMotionPending(pending.motion) as Exclude<
        MotionPending,
        { kind: "none" }
      >,
    };
  }
  if (pending.kind === "yank") {
    return { kind: "yank", yank: { ...pending.yank } };
  }
  return { kind: "none" };
}

function getMotionPending(
  model: ReplyModel,
): Exclude<MotionPending, { kind: "none" }> | null {
  if (isNormal(model) && model.interaction.pending.kind === "motion") {
    return model.interaction.pending.motion;
  }
  if (isVisual(model) && model.interaction.pending.kind !== "none") {
    return model.interaction.pending;
  }
  return null;
}

function setMotionPending(model: ReplyModel, pending: MotionPending): void {
  if (isNormal(model)) {
    model.interaction.pending =
      pending.kind === "none"
        ? { kind: "none" }
        : { kind: "motion", motion: pending };
  } else if (isVisual(model)) {
    model.interaction.pending = pending;
  }
}

function getCharMotion(data: string, keymap: ReplyKeymap): CharMotion | null {
  if (matchesKey(data, keymap.findForward)) return "f";
  if (matchesKey(data, keymap.findBackward)) return "F";
  if (matchesKey(data, keymap.tillForward)) return "t";
  if (matchesKey(data, keymap.tillBackward)) return "T";
  return null;
}

function moveHorizontal(model: ReplyModel, direction: -1 | 1): void {
  model.preferredColumn = null;
  const line = model.layout.document.lines[model.cursor.line]!;
  const next = model.cursor.grapheme + direction;
  if (next >= 0 && next < line.graphemes.length) model.cursor.grapheme = next;
}

function currentLineGraphemes(model: ReplyModel): string[] {
  return model.layout.document.lines[model.cursor.line]!.graphemes.map(
    (grapheme) => grapheme.text,
  );
}

function moveToColumn(model: ReplyModel, column: number): void {
  const line = model.layout.document.lines[model.cursor.line]!;
  model.cursor.grapheme = Math.max(
    0,
    Math.min(column, Math.max(0, line.graphemes.length - 1)),
  );
  model.preferredColumn = null;
}

function moveToLine(model: ReplyModel, line: number): void {
  const targetLine = Math.max(
    0,
    Math.min(line, model.layout.document.lines.length - 1),
  );
  const target = model.layout.document.lines[targetLine]!;
  model.cursor = {
    line: targetLine,
    grapheme: firstNonBlankColumn(
      target.graphemes.map((grapheme) => grapheme.text),
    ),
  };
  model.preferredColumn = null;
}

function moveWord(
  model: ReplyModel,
  direction: "forward" | "backward",
  target: "start" | "end",
): void {
  const motion = findWordMotionTarget(
    model.layout.document.lines.map((line) =>
      line.graphemes.map((grapheme) => grapheme.text),
    ),
    { line: model.cursor.line, column: model.cursor.grapheme },
    direction,
    target,
  );
  model.cursor = { line: motion.line, grapheme: motion.column };
  model.preferredColumn = null;
}

function executeCharMotion(
  model: ReplyModel,
  motion: CharMotion,
  targetChar: string,
  saveMotion = true,
): void {
  const target = findCharMotionTarget(
    currentLineGraphemes(model),
    model.cursor.grapheme,
    motion,
    targetChar,
    !saveMotion,
  );
  if (target === null) return;
  if (saveMotion) model.lastCharMotion = { motion, char: targetChar };
  moveToColumn(model, target);
}

function moveLogicalLine(model: ReplyModel, direction: -1 | 1): void {
  const { logicalLineStartByLine, logicalLineEndByLine } = model.layout;
  const currentStart =
    logicalLineStartByLine[model.cursor.line] ?? model.cursor.line;
  const currentEnd = logicalLineEndByLine[model.cursor.line] ?? model.cursor.line;
  const targetLine = direction === 1 ? currentEnd + 1 : currentStart - 1;
  if (
    targetLine < 0 ||
    targetLine >= model.layout.document.lines.length
  )
    return;

  const targetStart = logicalLineStartByLine[targetLine] ?? targetLine;
  const targetEnd = logicalLineEndByLine[targetLine] ?? targetLine;
  const currentColumn = logicalLineColumn(model);
  const targetColumn =
    model.preferredColumn?.kind === "logical"
      ? model.preferredColumn.column
      : currentColumn;
  model.cursor = cursorAtLogicalColumn(
    model,
    targetStart,
    targetEnd,
    targetColumn,
  );
  model.preferredColumn = { kind: "logical", column: targetColumn };
}

function logicalLineColumn(model: ReplyModel): number {
  const startLine =
    model.layout.logicalLineStartByLine[model.cursor.line] ?? model.cursor.line;
  let column = 0;
  for (let lineIndex = startLine; lineIndex < model.cursor.line; lineIndex++) {
    const line = model.layout.document.lines[lineIndex]!;
    column += cellColumn(line, line.graphemes.length);
  }
  return (
    column +
    cellColumn(
      model.layout.document.lines[model.cursor.line]!,
      model.cursor.grapheme,
    )
  );
}

function cursorAtLogicalColumn(
  model: ReplyModel,
  startLine: number,
  endLine: number,
  targetColumn: number,
): CursorPosition {
  let remainingColumn = Math.max(0, targetColumn);
  for (let lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    const line = model.layout.document.lines[lineIndex]!;
    const lineWidth = cellColumn(line, line.graphemes.length);
    const isLastLine = lineIndex === endLine;
    if (!isLastLine && remainingColumn >= lineWidth) {
      remainingColumn -= lineWidth;
      continue;
    }
    return {
      line: lineIndex,
      grapheme: graphemeAtOrBeforeColumn(line, remainingColumn),
    };
  }

  const lastLine = model.layout.document.lines[endLine]!;
  return {
    line: endLine,
    grapheme: graphemeAtOrBeforeColumn(lastLine, remainingColumn),
  };
}

function moveDisplayRow(
  model: ReplyModel,
  direction: -1 | 1,
  _viewportHeight: number,
): void {
  const renderer = createRenderer(model);
  const sourceRows = renderer
    .buildDisplayRows(model.lastInnerWidth)
    .filter(
      (row): row is Extract<DisplayRow, { kind: "source" }> =>
        row.kind === "source",
    );
  const currentRowIndex = sourceRows.findIndex(
    (row) =>
      row.line === model.cursor.line &&
      (row.startGrapheme === row.endGrapheme
        ? model.cursor.grapheme === 0
        : model.cursor.grapheme >= row.startGrapheme &&
          model.cursor.grapheme < row.endGrapheme),
  );
  if (currentRowIndex < 0) return;
  const targetRowIndex = Math.max(
    0,
    Math.min(sourceRows.length - 1, currentRowIndex + direction),
  );
  if (targetRowIndex === currentRowIndex) return;
  const currentRow = sourceRows[currentRowIndex]!;
  const targetRow = sourceRows[targetRowIndex]!;
  const currentLine = model.layout.document.lines[model.cursor.line]!;
  const currentColumn = displayRowColumn(
    currentLine,
    currentRow,
    model.cursor.grapheme,
  );
  const targetColumn =
    model.preferredColumn?.kind === "display"
      ? model.preferredColumn.column
      : currentColumn;
  const targetLine = model.layout.document.lines[targetRow.line]!;
  model.cursor = {
    line: targetRow.line,
    grapheme: graphemeAtOrBeforeDisplayColumn(
      targetLine,
      targetRow,
      targetColumn,
    ),
  };
  model.preferredColumn = { kind: "display", column: targetColumn };
}

function positionViewport(
  model: ReplyModel,
  alignment: "center" | "top" | "bottom",
  viewportHeight: number,
): void {
  const renderer = createRenderer(model);
  const rows = renderer.buildDisplayRows(model.lastInnerWidth);
  const cursorRow = renderer.findCursorRow(rows);
  if (cursorRow < 0) return;
  const maxScrollTop = Math.max(0, rows.length - viewportHeight);
  const requestedScrollTop =
    alignment === "top"
      ? cursorRow
      : alignment === "bottom"
        ? cursorRow - viewportHeight + 1
        : cursorRow - Math.floor(viewportHeight / 2);
  model.scrollTop = Math.max(0, Math.min(maxScrollTop, requestedScrollTop));
}

function scrollHalfPage(
  model: ReplyModel,
  direction: -1 | 1,
  viewportHeight: number,
): void {
  const currentLine = model.layout.document.lines[model.cursor.line]!;
  const renderer = createRenderer(model);
  const rows = renderer.buildDisplayRows(model.lastInnerWidth);
  const step = Math.max(1, Math.floor(viewportHeight / 2));
  model.scrollTop = Math.max(
    0,
    Math.min(
      Math.max(0, rows.length - viewportHeight),
      model.scrollTop + direction * step,
    ),
  );
  const sourceRow = renderer.findCursorRow(rows);
  if (sourceRow < 0) return;
  const targetRow = Math.max(
    0,
    Math.min(rows.length - 1, sourceRow + direction * step),
  );
  const targetSource = rows[targetRow];
  if (targetSource?.kind !== "source") return;
  const targetLine = model.layout.document.lines[targetSource.line]!;
  const targetColumn =
    model.preferredColumn?.kind === "display"
      ? model.preferredColumn.column
      : cellColumn(currentLine, model.cursor.grapheme);
  model.cursor = {
    line: targetSource.line,
    grapheme: graphemeAtOrBeforeColumn(targetLine, targetColumn),
  };
  model.preferredColumn = { kind: "display", column: targetColumn };
}

function createRenderer(model: ReplyModel): ReplyRenderer {
  const interaction =
    model.interaction.kind === "comment"
      ? model.interaction
      : editingInteraction(model);
  const activeSelection =
    interaction.kind === "visual"
      ? getSelectionRange(
          model.layout.document,
          interaction.anchor,
          model.cursor,
          interaction.visualMode,
        )
      : interaction.kind === "comment"
        ? interaction.selection
        : null;
  return new ReplyRenderer(
    noTheme as Theme,
    model.layout.document,
    model.annotations,
    {
      cursor: model.cursor,
      activeSelection,
      searchMatches: model.search?.matches ?? [],
      currentSearchMatch:
        model.search && model.search.currentIndex >= 0
          ? model.search.matches[model.search.currentIndex]!
          : null,
      yankHighlight: model.yank.highlight,
      hasCommentInput: model.interaction.kind === "comment",
      focused: false,
    },
    model.layout.renderedLines,
  );
}

// The reducer only needs geometry. Styling is supplied by the view adapter.
const noTheme = {
  fg: (_color: string, text: string) => text,
  bg: (_color: string, text: string) => text,
  bold: (text: string) => text,
  underline: (text: string) => text,
};

function linewiseSelection(
  model: ReplyModel,
  destination: CursorPosition,
): SelectionRange | null {
  return getSelectionRange(
    model.layout.document,
    model.cursor,
    destination,
    "line",
  );
}

function characterwiseSelection(
  model: ReplyModel,
  start: CursorPosition,
  destination: CursorPosition,
): SelectionRange | null {
  return getSelectionRange(
    model.layout.document,
    start,
    destination,
    "character",
  );
}

function graphemeSelection(
  model: ReplyModel,
  position: CursorPosition,
): SelectionRange | null {
  const line = model.layout.document.lines[position.line];
  const grapheme = line?.graphemes[position.grapheme];
  if (!line || !grapheme) return null;
  return selectionFromOffsets(
    model,
    line.start + grapheme.start,
    line.start + grapheme.end,
  );
}

function selectionFromOffsets(
  model: ReplyModel,
  start: number,
  end: number,
): SelectionRange | null {
  if (end <= start) return null;
  return { start, end, text: model.layout.document.text.slice(start, end) };
}

function selectionForYankMotion(
  model: ReplyModel,
  data: string,
  context: UpdateContext,
): SelectionRange | null | undefined {
  if (matchesKey(data, context.keymap.left)) {
    if (model.cursor.grapheme === 0) return null;
    return graphemeSelection(model, {
      line: model.cursor.line,
      grapheme: model.cursor.grapheme - 1,
    });
  }
  if (matchesKey(data, context.keymap.right))
    return graphemeSelection(model, model.cursor);
  if (matchesKey(data, context.keymap.down)) {
    const destination = previewMotion(model, () =>
      moveLogicalLine(model, 1),
    );
    return sameCursor(model.cursor, destination)
      ? null
      : linewiseSelection(model, destination);
  }
  if (matchesKey(data, context.keymap.up)) {
    const destination = previewMotion(model, () =>
      moveLogicalLine(model, -1),
    );
    return sameCursor(model.cursor, destination)
      ? null
      : linewiseSelection(model, destination);
  }
  if (matchesKey(data, context.keymap.lastLine)) {
    return linewiseSelection(
      model,
      previewMotion(model, () =>
        moveToLine(model, model.layout.document.lines.length - 1),
      ),
    );
  }
  if (matchesKey(data, context.keymap.wordForward))
    return wordMotionSelection(model, "forward", "start");
  if (matchesKey(data, context.keymap.wordBackward))
    return wordMotionSelection(model, "backward", "start");
  if (matchesKey(data, context.keymap.wordEnd))
    return wordMotionSelection(model, "forward", "end");
  if (matchesKey(data, context.keymap.lineStart))
    return logicalLineStartSelection(model);
  if (matchesKey(data, context.keymap.firstNonBlank))
    return linewiseSelection(model, model.cursor);
  if (matchesKey(data, context.keymap.lineEnd)) {
    return logicalLineEndSelection(model);
  }
  return undefined;
}

function logicalLineStartSelection(model: ReplyModel): SelectionRange | null {
  const document = model.layout.document;
  const end = cursorOffset(document, model.cursor);
  const startLineIndex =
    model.layout.logicalLineStartByLine[model.cursor.line] ?? model.cursor.line;
  const startLine = document.lines[startLineIndex];
  const currentLine = document.lines[model.cursor.line];
  if (!startLine || !currentLine || end <= startLine.start) return null;

  const text = [
    ...document.lines
      .slice(startLineIndex, model.cursor.line)
      .map((line) => line.text),
    document.text.slice(currentLine.start, end),
  ].join("");
  return { start: startLine.start, end, text };
}

function logicalLineEndSelection(model: ReplyModel): SelectionRange | null {
  const document = model.layout.document;
  const startLine = document.lines[model.cursor.line];
  if (!startLine || startLine.graphemes.length === 0) return null;

  const endLineIndex =
    model.layout.logicalLineEndByLine[model.cursor.line] ?? model.cursor.line;
  const endLine = document.lines[endLineIndex] ?? startLine;
  const start = cursorOffset(document, model.cursor);
  const end = endLine.start + endLine.text.length;
  const text = [
    document.text.slice(start, startLine.start + startLine.text.length),
    ...document.lines
      .slice(model.cursor.line + 1, endLineIndex + 1)
      .map((line) => line.text),
  ].join("");

  if (end <= start) return null;
  return { start, end, text };
}

function wordMotionSelection(
  model: ReplyModel,
  direction: "forward" | "backward",
  target: "start" | "end",
): SelectionRange | null {
  const start = { ...model.cursor };
  const destination = previewMotion(model, () =>
    moveWord(model, direction, target),
  );
  const startOffset = cursorOffset(model.layout.document, start);
  const destinationOffset = cursorOffset(model.layout.document, destination);
  if (target === "start" && direction === "backward")
    return selectionFromOffsets(model, destinationOffset, startOffset);
  if (target === "start") {
    const end =
      !sameCursor(start, destination) && isWordStart(model, destination)
        ? destinationOffset
        : graphemeEndOffset(model, destination);
    return selectionFromOffsets(model, startOffset, end);
  }
  return selectionFromOffsets(
    model,
    startOffset,
    graphemeEndOffset(model, destination),
  );
}

function wordObjectSelection(
  model: ReplyModel,
  outer: boolean,
): SelectionRange | null {
  const line = model.layout.document.lines[model.cursor.line];
  if (!line || line.graphemes.length === 0) return null;
  const kind = wordKind(line.graphemes[model.cursor.grapheme]!.text);
  let start = model.cursor.grapheme;
  let end = model.cursor.grapheme + 1;
  while (start > 0 && wordKind(line.graphemes[start - 1]!.text) === kind)
    start--;
  while (
    end < line.graphemes.length &&
    wordKind(line.graphemes[end]!.text) === kind
  )
    end++;
  let startOffset = line.start + line.graphemes[start]!.start;
  let endOffset = line.start + line.graphemes[end - 1]!.end;
  if (outer && kind !== "whitespace") {
    if (
      end < line.graphemes.length &&
      wordKind(line.graphemes[end]!.text) === "whitespace"
    ) {
      while (
        end < line.graphemes.length &&
        wordKind(line.graphemes[end]!.text) === "whitespace"
      )
        end++;
      endOffset = line.start + line.graphemes[end - 1]!.end;
    } else {
      while (
        start > 0 &&
        wordKind(line.graphemes[start - 1]!.text) === "whitespace"
      )
        start--;
      startOffset = line.start + line.graphemes[start]!.start;
    }
  } else if (outer && kind === "whitespace") {
    const hasFollowingUnit = end < line.graphemes.length;
    while (
      end < line.graphemes.length &&
      wordKind(line.graphemes[end]!.text) !== "whitespace"
    )
      end++;
    if (hasFollowingUnit) endOffset = line.start + line.graphemes[end - 1]!.end;
    else {
      const nextWord = firstNonWhitespaceUnit(model, model.cursor.line + 1);
      if (nextWord) endOffset = graphemeEndOffset(model, nextWord);
    }
  }
  return selectionFromOffsets(model, startOffset, endOffset);
}

function firstNonWhitespaceUnit(
  model: ReplyModel,
  startLine: number,
): CursorPosition | null {
  for (
    let lineIndex = startLine;
    lineIndex < model.layout.document.lines.length;
    lineIndex++
  ) {
    const line = model.layout.document.lines[lineIndex]!;
    const grapheme = line.graphemes.findIndex(
      (candidate) => wordKind(candidate.text) !== "whitespace",
    );
    if (grapheme >= 0) return { line: lineIndex, grapheme };
  }
  return null;
}

function previewMotion(model: ReplyModel, move: () => void): CursorPosition {
  const previousCursor = { ...model.cursor };
  const previousPreferredColumn = model.preferredColumn;
  move();
  const destination = { ...model.cursor };
  model.cursor = previousCursor;
  model.preferredColumn = previousPreferredColumn;
  return destination;
}

function sameCursor(first: CursorPosition, second: CursorPosition): boolean {
  return first.line === second.line && first.grapheme === second.grapheme;
}

function graphemeEndOffset(
  model: ReplyModel,
  position: CursorPosition,
): number {
  const line = model.layout.document.lines[position.line];
  const grapheme = line?.graphemes[position.grapheme];
  return line && grapheme
    ? line.start + grapheme.end
    : cursorOffset(model.layout.document, position);
}

function isWordStart(model: ReplyModel, position: CursorPosition): boolean {
  const line = model.layout.document.lines[position.line];
  const grapheme = line?.graphemes[position.grapheme];
  if (!line || !grapheme || wordKind(grapheme.text) === "whitespace")
    return false;
  if (position.grapheme === 0) return true;
  return (
    wordKind(line.graphemes[position.grapheme - 1]!.text) !==
    wordKind(grapheme.text)
  );
}

function wordKind(unit: string): "keyword" | "other" | "whitespace" {
  if (/^\s+$/u.test(unit)) return "whitespace";
  return /^[A-Za-z0-9_]$/.test(unit) ? "keyword" : "other";
}

function findAnnotationAtCursor(model: ReplyModel): Annotation | null {
  const line = model.layout.document.lines[model.cursor.line];
  const grapheme = line?.graphemes[model.cursor.grapheme];
  if (!line || !grapheme) return null;
  const start = line.start + grapheme.start;
  const end = line.start + grapheme.end;
  for (let index = model.annotations.length - 1; index >= 0; index--) {
    const annotation = model.annotations[index]!;
    if (selectionContainsOffset(annotation, start, end)) return annotation;
  }
  return null;
}

function cellColumn(
  line: { graphemes: Array<{ text: string }> },
  graphemeIndex: number,
): number {
  let column = 0;
  for (let index = 0; index < graphemeIndex; index++) {
    const text = line.graphemes[index]!.text;
    column += text === "\t" ? 4 - (column % 4) : visibleWidth(text);
  }
  return column;
}

function requestRender(): ReplyEffect[] {
  return [{ type: "request-render" }];
}
