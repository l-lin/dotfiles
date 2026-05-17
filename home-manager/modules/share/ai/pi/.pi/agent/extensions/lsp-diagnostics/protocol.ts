import type { LspDiagnostic } from "./types.js";

export type { LspDiagnostic };

export interface LspPosition {
  line: number;
  character: number;
}

export interface LspRange {
  start: LspPosition;
  end: LspPosition;
}

export interface LspLocation {
  uri: string;
  range: LspRange;
}

export interface LspLocationLink {
  targetUri: string;
  targetRange: LspRange;
  targetSelectionRange: LspRange;
  originSelectionRange?: LspRange;
}

export interface LspSymbolInformation {
  name: string;
  kind: number;
  location: LspLocation;
  containerName?: string;
}

export interface LspDocumentSymbol {
  name: string;
  detail?: string;
  kind: number;
  range: LspRange;
  selectionRange: LspRange;
  children?: LspDocumentSymbol[];
}

export interface LspWorkspaceSymbol {
  name: string;
  kind: number;
  location?: LspLocation;
  containerName?: string;
  data?: unknown;
}

export interface LspTextEdit {
  range: LspRange;
  newText: string;
}

export interface LspTextDocumentIdentifier {
  uri: string;
  version?: number | null;
}

export interface LspTextDocumentEdit {
  textDocument: LspTextDocumentIdentifier;
  edits: LspTextEdit[];
}

export interface LspCreateFile {
  kind: "create";
  uri: string;
  options?: {
    overwrite?: boolean;
    ignoreIfExists?: boolean;
  };
}

export interface LspRenameFile {
  kind: "rename";
  oldUri: string;
  newUri: string;
  options?: {
    overwrite?: boolean;
    ignoreIfExists?: boolean;
  };
}

export interface LspDeleteFile {
  kind: "delete";
  uri: string;
  options?: {
    recursive?: boolean;
    ignoreIfNotExists?: boolean;
  };
}

export type LspDocumentChange =
  | LspTextDocumentEdit
  | LspCreateFile
  | LspRenameFile
  | LspDeleteFile;

export interface LspWorkspaceEdit {
  changes?: Record<string, LspTextEdit[]>;
  documentChanges?: LspDocumentChange[];
}

const SYMBOL_KIND_LABELS: Record<number, string> = {
  1: "file",
  2: "module",
  3: "namespace",
  4: "package",
  5: "class",
  6: "method",
  7: "property",
  8: "field",
  9: "constructor",
  10: "enum",
  11: "interface",
  12: "function",
  13: "variable",
  14: "constant",
  15: "string",
  16: "number",
  17: "boolean",
  18: "array",
  19: "object",
  20: "key",
  21: "null",
  22: "enum-member",
  23: "struct",
  24: "event",
  25: "operator",
  26: "type-parameter",
};

export function symbolKindToLabel(kind: number): string {
  return SYMBOL_KIND_LABELS[kind] ?? `kind-${kind}`;
}

export function toLspPosition(line: number, character: number): LspPosition {
  if (!Number.isInteger(line) || line < 1) {
    throw new Error(`line must be a positive integer, received ${line}`);
  }

  if (!Number.isInteger(character) || character < 1) {
    throw new Error(
      `character must be a positive integer, received ${character}`,
    );
  }

  return { line: line - 1, character: character - 1 };
}

export function normalizeLocationResult(
  value: LspLocation | LspLocation[] | LspLocationLink[] | null | undefined,
): LspLocation[] {
  if (!value) return [];
  const items = Array.isArray(value) ? value : [value];

  return items.map((item) => {
    if (isLocationLink(item)) {
      return { uri: item.targetUri, range: item.targetSelectionRange };
    }

    return item;
  });
}

export function isSymbolInformation(
  value: LspDocumentSymbol | LspSymbolInformation,
): value is LspSymbolInformation {
  return "location" in value;
}

export function isTextDocumentEdit(
  change: LspDocumentChange,
): change is LspTextDocumentEdit {
  return "textDocument" in change;
}

export function isCreateFileChange(
  change: LspDocumentChange,
): change is LspCreateFile {
  return "kind" in change && change.kind === "create";
}

export function isRenameFileChange(
  change: LspDocumentChange,
): change is LspRenameFile {
  return "kind" in change && change.kind === "rename";
}

export function isDeleteFileChange(
  change: LspDocumentChange,
): change is LspDeleteFile {
  return "kind" in change && change.kind === "delete";
}

function isLocationLink(
  value: LspLocation | LspLocationLink,
): value is LspLocationLink {
  return "targetUri" in value;
}
