import type {
  Annotation,
  CursorPosition,
  SearchDirection,
  SearchMatch,
  SelectionRange,
  SourceDocument,
  VisualMode,
} from "./model.js";
import type { CharMotion, LastCharMotion } from "../vim/types.js";
import { createReplyLayout } from "./layout.js";

export type PreferredColumn =
  | { kind: "logical"; column: number }
  | { kind: "display"; column: number };

export type MotionPending =
  | { kind: "none" }
  | { kind: "g" }
  | { kind: "z" }
  | { kind: "char"; motion: CharMotion };

export type YankPending =
  | { kind: "operator" }
  | { kind: "g" }
  | { kind: "char"; motion: CharMotion }
  | { kind: "text-object"; outer: boolean };

export type NormalPending =
  | { kind: "none" }
  | { kind: "motion"; motion: Exclude<MotionPending, { kind: "none" }> }
  | { kind: "yank"; yank: YankPending };

export type SearchState = {
  query: string;
  prefix: "/" | "?";
  direction: SearchDirection;
  kind: "literal" | "word";
  matches: SearchMatch[];
  currentIndex: number;
};

export type SearchSnapshot = {
  cursor: CursorPosition;
  preferredColumn: PreferredColumn | null;
  interaction: Extract<ReplyInteraction, { kind: "normal" | "visual" }>;
  search: SearchState | null;
};

export type ReplyInteraction =
  | { kind: "normal"; pending: NormalPending }
  | {
      kind: "visual";
      visualMode: VisualMode;
      anchor: CursorPosition;
      pending: MotionPending;
    }
  | {
      kind: "comment";
      selection: SelectionRange;
      annotationId: number | null;
      returnTo: "normal" | "visual";
      anchor: CursorPosition | null;
    }
  | {
      kind: "search";
      direction: SearchDirection;
      prefix: "/" | "?";
      before: SearchSnapshot;
    };

export interface ReplyLayout {
  width: number;
  document: SourceDocument;
  renderedLines: readonly string[];
  logicalLineStartByLine: readonly number[];
  logicalLineEndByLine: readonly number[];
}

export interface YankFeedback {
  highlight: SelectionRange | null;
  pendingSelection: SelectionRange | null;
  pendingSelections: Map<number, SelectionRange>;
  generation: number;
  operationId: number;
  latestSuccessfulOperationId: number;
  sessionId: number;
}

export interface ReplyComponentResult {
  action: "save" | "cancel";
  text?: string;
}

export interface ReplyModel {
  rawSourceText: string;
  layout: ReplyLayout;
  annotations: Annotation[];
  nextAnnotationId: number;
  cursor: CursorPosition;
  preferredColumn: PreferredColumn | null;
  interaction: ReplyInteraction;
  search: SearchState | null;
  yank: YankFeedback;
  scrollTop: number;
  lastInnerWidth: number;
  lastCharMotion: LastCharMotion | null;
  disposed: boolean;
}

export function createReplyModel(
  sourceText: string,
  initialWidth: number,
): ReplyModel {
  const width = Math.max(3, initialWidth);
  return {
    rawSourceText: sourceText,
    layout: createReplyLayout(sourceText, width),
    annotations: [],
    nextAnnotationId: 1,
    cursor: { line: 0, grapheme: 0 },
    preferredColumn: null,
    interaction: { kind: "normal", pending: { kind: "none" } },
    search: null,
    yank: {
      highlight: null,
      pendingSelection: null,
      pendingSelections: new Map(),
      generation: 0,
      operationId: 0,
      latestSuccessfulOperationId: 0,
      sessionId: 0,
    },
    scrollTop: 0,
    lastInnerWidth: width,
    lastCharMotion: null,
    disposed: false,
  };
}
