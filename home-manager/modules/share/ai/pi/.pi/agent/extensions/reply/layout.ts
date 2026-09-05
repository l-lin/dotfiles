import {
  decodeSearchQuery,
  findKeywordSearchMatches,
  findLiteralSearchMatches,
  cursorOffset,
  type CursorPosition,
  type SearchMatch,
  type SelectionRange,
  type SourceDocument,
} from "./model.js";
import { renderMarkdownDocument } from "./render.js";
import type {
  MotionPending,
  NormalPending,
  ReplyInteraction,
  ReplyModel,
  SearchSnapshot,
  SearchState,
  YankPending,
} from "./state.js";

export type SearchStateSnapshot = {
  query: string;
  prefix: "/" | "?";
  direction: "forward" | "backward";
  kind: "literal" | "word";
  matchOrdinals: number[];
  currentMatchOrdinal: number | null;
};

type DisplayInteractionSnapshot =
  | { kind: "normal"; pending: NormalPending }
  | {
      kind: "visual";
      visualMode: "character" | "line";
      anchorOrdinal: number;
      pending: MotionPending;
    }
  | {
      kind: "comment";
      selection: { startOrdinal: number; endOrdinal: number };
      annotationId: number | null;
      returnTo: "normal" | "visual";
      anchorOrdinal: number | null;
    }
  | {
      kind: "search";
      direction: "forward" | "backward";
      prefix: "/" | "?";
      before: DisplaySearchSnapshot;
    };

type DisplaySearchSnapshot = {
  cursorOrdinal: number;
  preferredColumn: number | null;
  interaction: DisplayInteractionSnapshot;
  search: SearchStateSnapshot | null;
};

export interface ReplyDisplaySnapshot {
  cursorOrdinal: number;
  preferredColumn: number | null;
  interaction: DisplayInteractionSnapshot;
  annotations: Array<{
    annotationId: number;
    startOrdinal: number;
    endOrdinal: number;
  }>;
  search: SearchStateSnapshot | null;
  searchInputBefore: DisplaySearchSnapshot | null;
  yankHighlight: { startOrdinal: number; endOrdinal: number } | null;
}

export function createReplyLayout(
  rawSourceText: string,
  width: number,
): import("./state.js").ReplyLayout {
  const normalizedWidth = Math.max(3, width);
  const rendered = renderMarkdownDocument(rawSourceText, normalizedWidth);
  return {
    width: normalizedWidth,
    document: rendered.document,
    renderedLines: rendered.renderedLines,
    logicalLineStartByLine: rendered.logicalLineStartByLine,
    logicalLineEndByLine: rendered.logicalLineEndByLine,
  };
}

export function reflowReplyModel(model: ReplyModel, width: number): ReplyModel {
  const normalizedWidth = Math.max(3, width);
  if (model.layout.width === normalizedWidth) return model;

  const snapshot = captureDisplayState(model);
  model.layout = createReplyLayout(model.rawSourceText, normalizedWidth);
  model.lastInnerWidth = normalizedWidth;
  restoreDisplayState(model, snapshot);
  return model;
}

export function captureDisplayState(model: ReplyModel): ReplyDisplaySnapshot {
  const document = model.layout.document;
  return {
    cursorOrdinal: visibleGraphemeOrdinal(
      document,
      cursorOffset(document, model.cursor),
    ),
    preferredColumn: model.preferredColumn,
    interaction: captureInteraction(document, model.interaction),
    annotations: model.annotations.map((annotation) => ({
      annotationId: annotation.id,
      startOrdinal: visibleGraphemeOrdinal(document, annotation.start),
      endOrdinal: visibleGraphemeOrdinal(document, annotation.end),
    })),
    search: captureSearchState(document, model.search),
    searchInputBefore:
      model.interaction.kind === "search"
        ? captureSearchSnapshot(document, model.interaction.before)
        : null,
    yankHighlight: model.yank.highlight
      ? {
          startOrdinal: visibleGraphemeOrdinal(
            document,
            model.yank.highlight.start,
          ),
          endOrdinal: visibleGraphemeOrdinal(
            document,
            model.yank.highlight.end,
          ),
        }
      : null,
  };
}

export function restoreDisplayState(
  model: ReplyModel,
  snapshot: ReplyDisplaySnapshot,
): void {
  const document = model.layout.document;
  model.cursor = cursorAtVisibleOrdinal(document, snapshot.cursorOrdinal);
  model.preferredColumn = snapshot.preferredColumn;
  model.interaction = restoreInteraction(document, snapshot.interaction);
  model.yank.highlight = snapshot.yankHighlight
    ? selectionFromOffsets(
        document,
        boundaryOffsetAtVisibleOrdinal(
          document,
          snapshot.yankHighlight.startOrdinal,
        ),
        endOffsetAtVisibleOrdinal(document, snapshot.yankHighlight.endOrdinal),
      )
    : null;

  for (const annotationState of snapshot.annotations) {
    const annotation = model.annotations.find(
      (candidate) => candidate.id === annotationState.annotationId,
    );
    if (!annotation) continue;

    annotation.start = boundaryOffsetAtVisibleOrdinal(
      document,
      annotationState.startOrdinal,
    );
    annotation.end = boundaryOffsetAtVisibleOrdinal(
      document,
      annotationState.endOrdinal,
    );
    annotation.text = document.text.slice(annotation.start, annotation.end);
  }

  model.search = restoreSearchState(model, snapshot.search);
  if (snapshot.interaction.kind === "search") {
    const before = restoreSearchSnapshot(model, snapshot.searchInputBefore);
    if (before) {
      model.interaction = {
        kind: "search",
        direction: snapshot.interaction.direction,
        prefix: snapshot.interaction.prefix,
        before,
      };
    }
  }
}

function captureInteraction(
  document: SourceDocument,
  interaction: ReplyInteraction,
): DisplayInteractionSnapshot {
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
        anchorOrdinal: visibleGraphemeOrdinal(
          document,
          cursorOffset(document, interaction.anchor),
        ),
        pending: cloneMotionPending(interaction.pending),
      };
    case "comment":
      return {
        kind: "comment",
        selection: {
          startOrdinal: visibleGraphemeOrdinal(
            document,
            interaction.selection.start,
          ),
          endOrdinal: visibleGraphemeOrdinal(
            document,
            interaction.selection.end,
          ),
        },
        annotationId: interaction.annotationId,
        returnTo: interaction.returnTo,
        anchorOrdinal: interaction.anchor
          ? visibleGraphemeOrdinal(
              document,
              cursorOffset(document, interaction.anchor),
            )
          : null,
      };
    case "search":
      return {
        kind: "search",
        direction: interaction.direction,
        prefix: interaction.prefix,
        before: captureSearchSnapshot(document, interaction.before),
      };
  }
}

function restoreInteraction(
  document: SourceDocument,
  interaction: DisplayInteractionSnapshot,
): ReplyInteraction {
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
        anchor: cursorAtVisibleOrdinal(document, interaction.anchorOrdinal),
        pending: cloneMotionPending(interaction.pending),
      };
    case "comment": {
      const start = boundaryOffsetAtVisibleOrdinal(
        document,
        interaction.selection.startOrdinal,
      );
      const end = endOffsetAtVisibleOrdinal(
        document,
        interaction.selection.endOrdinal,
      );
      return {
        kind: "comment",
        selection: selectionFromOffsets(document, start, end) ?? {
          start,
          end,
          text: document.text.slice(start, end),
        },
        annotationId: interaction.annotationId,
        returnTo: interaction.returnTo,
        anchor:
          interaction.anchorOrdinal === null
            ? null
            : cursorAtVisibleOrdinal(document, interaction.anchorOrdinal),
      };
    }
    case "search":
      return {
        kind: "search",
        direction: interaction.direction,
        prefix: interaction.prefix,
        before: restoreSearchSnapshotFromDisplay(document, interaction.before),
      };
  }
}

function captureSearchSnapshot(
  document: SourceDocument,
  snapshot: SearchSnapshot,
): DisplaySearchSnapshot {
  return {
    cursorOrdinal: visibleGraphemeOrdinal(
      document,
      cursorOffset(document, snapshot.cursor),
    ),
    preferredColumn: snapshot.preferredColumn,
    interaction: captureInteraction(document, snapshot.interaction),
    search: captureSearchState(document, snapshot.search),
  };
}

function restoreSearchSnapshot(
  model: ReplyModel,
  snapshot: DisplaySearchSnapshot | null,
): SearchSnapshot | null {
  return snapshot
    ? restoreSearchSnapshotFromDisplay(model.layout.document, snapshot, model)
    : null;
}

function restoreSearchSnapshotFromDisplay(
  document: SourceDocument,
  snapshot: DisplaySearchSnapshot,
  model?: ReplyModel,
): SearchSnapshot {
  return {
    cursor: cursorAtVisibleOrdinal(document, snapshot.cursorOrdinal),
    preferredColumn: snapshot.preferredColumn,
    interaction: restoreInteraction(document, snapshot.interaction) as Extract<
      ReplyInteraction,
      { kind: "normal" | "visual" }
    >,
    search: model
      ? restoreSearchState(model, snapshot.search)
      : restoreSearchStateForDocument(document, snapshot.search),
  };
}

function captureSearchState(
  document: SourceDocument,
  search: SearchState | null,
): SearchStateSnapshot | null {
  if (!search) return null;
  return {
    query: search.query,
    prefix: search.prefix,
    direction: search.direction,
    kind: search.kind,
    matchOrdinals: search.matches.map((match) =>
      visibleGraphemeOrdinal(document, match.start),
    ),
    currentMatchOrdinal:
      search.currentIndex >= 0
        ? visibleGraphemeOrdinal(
            document,
            search.matches[search.currentIndex]!.start,
          )
        : null,
  };
}

function restoreSearchState(
  model: ReplyModel,
  snapshot: SearchStateSnapshot | null,
): SearchState | null {
  return restoreSearchStateForDocument(model.layout.document, snapshot);
}

function restoreSearchStateForDocument(
  document: SourceDocument,
  snapshot: SearchStateSnapshot | null,
): SearchState | null {
  if (!snapshot) return null;

  const allMatches =
    snapshot.kind === "word"
      ? findKeywordSearchMatches(document, snapshot.query)
      : findLiteralSearchMatches(
          document.text,
          decodeSearchQuery(snapshot.query),
        );
  const matches = snapshot.matchOrdinals
    .map((ordinal) =>
      allMatches.find(
        (match) => visibleGraphemeOrdinal(document, match.start) === ordinal,
      ),
    )
    .filter((match): match is SearchMatch => match !== undefined);
  const currentIndex =
    snapshot.currentMatchOrdinal === null
      ? -1
      : matches.findIndex(
          (match) =>
            visibleGraphemeOrdinal(document, match.start) ===
            snapshot.currentMatchOrdinal,
        );

  return {
    query: snapshot.query,
    prefix: snapshot.prefix,
    direction: snapshot.direction,
    kind: snapshot.kind,
    matches,
    currentIndex,
  };
}

function cloneNormalPending(pending: NormalPending): NormalPending {
  if (pending.kind === "motion") {
    return {
      kind: "motion",
      motion: cloneRequiredMotionPending(pending.motion),
    };
  }
  if (pending.kind === "yank") {
    return { kind: "yank", yank: cloneYankPending(pending.yank) };
  }
  return { kind: "none" };
}

function cloneMotionPending(pending: MotionPending): MotionPending {
  return pending.kind === "char" ? { ...pending } : { kind: pending.kind };
}

function cloneRequiredMotionPending(
  pending: Exclude<MotionPending, { kind: "none" }>,
): Exclude<MotionPending, { kind: "none" }> {
  return pending.kind === "char" ? { ...pending } : { kind: pending.kind };
}

function cloneYankPending(pending: YankPending): YankPending {
  return pending.kind === "char" ? { ...pending } : { ...pending };
}

function selectionFromOffsets(
  document: SourceDocument,
  start: number,
  end: number,
): SelectionRange | null {
  if (end <= start) return null;
  return { start, end, text: document.text.slice(start, end) };
}

export function visibleGraphemeOrdinal(
  document: SourceDocument,
  offset: number,
): number {
  const boundedOffset = Math.max(0, Math.min(offset, document.text.length));
  let ordinal = 0;
  for (const line of document.lines) {
    for (const grapheme of line.graphemes) {
      if (line.start + grapheme.start >= boundedOffset) return ordinal;
      ordinal++;
    }
  }
  return ordinal;
}

export function boundaryOffsetAtVisibleOrdinal(
  document: SourceDocument,
  ordinal: number,
): number {
  const target = Math.max(0, ordinal);
  let current = 0;
  for (const line of document.lines) {
    for (const grapheme of line.graphemes) {
      if (current === target) return line.start + grapheme.start;
      current++;
    }
  }
  return document.text.length;
}

export function endOffsetAtVisibleOrdinal(
  document: SourceDocument,
  ordinal: number,
): number {
  const target = Math.max(0, ordinal);
  let current = 0;
  let lastEnd = 0;
  for (const line of document.lines) {
    for (const grapheme of line.graphemes) {
      if (current === target) return lastEnd;
      lastEnd = line.start + grapheme.end;
      current++;
    }
  }
  return document.text.length;
}

export function cursorAtVisibleOrdinal(
  document: SourceDocument,
  ordinal: number,
): CursorPosition {
  const target = Math.max(0, ordinal);
  let current = 0;
  let last: CursorPosition = { line: 0, grapheme: 0 };
  for (let lineIndex = 0; lineIndex < document.lines.length; lineIndex++) {
    const line = document.lines[lineIndex]!;
    for (
      let graphemeIndex = 0;
      graphemeIndex < line.graphemes.length;
      graphemeIndex++
    ) {
      last = { line: lineIndex, grapheme: graphemeIndex };
      if (current === target) return last;
      current++;
    }
  }
  return last;
}
