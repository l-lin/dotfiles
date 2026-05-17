import * as fs from "node:fs";
import * as path from "node:path";
import {
  isCreateFileChange,
  isDeleteFileChange,
  isRenameFileChange,
  isTextDocumentEdit,
  type LspPosition,
  type LspTextEdit,
  type LspWorkspaceEdit,
} from "./protocol.js";
import { fileUriToPath } from "./resolver.js";

export interface WorkspaceEditSummary {
  textDocumentCount: number;
  textEditCount: number;
  createCount: number;
  renameCount: number;
  deleteCount: number;
  changedPaths: string[];
}

export function applyWorkspaceEdit(
  workspaceEdit: LspWorkspaceEdit,
  cwd: string,
): WorkspaceEditSummary {
  const changedPaths = new Set<string>();
  const uriAliases = new Map<string, string>();

  let textDocumentCount = 0;
  let textEditCount = 0;
  let createCount = 0;
  let renameCount = 0;
  let deleteCount = 0;

  for (const [uri, edits] of Object.entries(workspaceEdit.changes ?? {})) {
    const targetPath = resolveWorkspacePath(uri, cwd, uriAliases);
    applyTextDocumentEdits(targetPath, edits);
    changedPaths.add(targetPath);
    textDocumentCount += 1;
    textEditCount += edits.length;
  }

  for (const change of workspaceEdit.documentChanges ?? []) {
    if (isTextDocumentEdit(change)) {
      const targetPath = resolveWorkspacePath(
        change.textDocument.uri,
        cwd,
        uriAliases,
      );
      applyTextDocumentEdits(targetPath, change.edits);
      changedPaths.add(targetPath);
      textDocumentCount += 1;
      textEditCount += change.edits.length;
      continue;
    }

    if (isRenameFileChange(change)) {
      const oldPath = resolveWorkspacePath(change.oldUri, cwd, uriAliases);
      const newPath = resolveWorkspacePath(change.newUri, cwd, uriAliases);
      fs.mkdirSync(path.dirname(newPath), { recursive: true });
      fs.renameSync(oldPath, newPath);
      uriAliases.set(change.oldUri, change.newUri);
      renameCount += 1;
      changedPaths.add(newPath);
      continue;
    }

    if (isCreateFileChange(change)) {
      const targetPath = resolveWorkspacePath(change.uri, cwd, uriAliases);
      fs.mkdirSync(path.dirname(targetPath), { recursive: true });
      if (!fs.existsSync(targetPath) || change.options?.overwrite) {
        fs.writeFileSync(targetPath, "", "utf8");
      }
      createCount += 1;
      changedPaths.add(targetPath);
      continue;
    }

    if (isDeleteFileChange(change)) {
      const targetPath = resolveWorkspacePath(change.uri, cwd, uriAliases);
      if (fs.existsSync(targetPath) || !change.options?.ignoreIfNotExists) {
        fs.rmSync(targetPath, {
          recursive: change.options?.recursive ?? false,
          force: change.options?.ignoreIfNotExists ?? false,
        });
      }
      deleteCount += 1;
      changedPaths.add(targetPath);
      continue;
    }
  }

  return {
    textDocumentCount,
    textEditCount,
    createCount,
    renameCount,
    deleteCount,
    changedPaths: [...changedPaths].sort(),
  };
}

function resolveWorkspacePath(
  uriOrPath: string,
  cwd: string,
  uriAliases: Map<string, string>,
): string {
  let current = uriOrPath;
  while (uriAliases.has(current)) {
    current = uriAliases.get(current)!;
  }

  const rawPath = current.startsWith("file://")
    ? fileUriToPath(current)
    : current;
  return path.isAbsolute(rawPath) ? rawPath : path.resolve(cwd, rawPath);
}

function applyTextDocumentEdits(filePath: string, edits: LspTextEdit[]): void {
  const currentText = fs.existsSync(filePath)
    ? fs.readFileSync(filePath, "utf8")
    : "";
  const nextText = applyTextEdits(currentText, edits);
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, nextText, "utf8");
}

function applyTextEdits(currentText: string, edits: LspTextEdit[]): string {
  const orderedEdits = [...edits].sort(compareEditsDescending);
  let nextText = currentText;

  for (const edit of orderedEdits) {
    const startOffset = positionToOffset(nextText, edit.range.start);
    const endOffset = positionToOffset(nextText, edit.range.end);
    nextText =
      nextText.slice(0, startOffset) + edit.newText + nextText.slice(endOffset);
  }

  return nextText;
}

function compareEditsDescending(left: LspTextEdit, right: LspTextEdit): number {
  if (left.range.start.line !== right.range.start.line) {
    return right.range.start.line - left.range.start.line;
  }

  if (left.range.start.character !== right.range.start.character) {
    return right.range.start.character - left.range.start.character;
  }

  if (left.range.end.line !== right.range.end.line) {
    return right.range.end.line - left.range.end.line;
  }

  return right.range.end.character - left.range.end.character;
}

function positionToOffset(text: string, position: LspPosition): number {
  let offset = 0;
  let currentLine = 0;

  while (currentLine < position.line && offset < text.length) {
    const nextNewline = text.indexOf("\n", offset);
    if (nextNewline === -1) {
      return text.length;
    }

    offset = nextNewline + 1;
    currentLine += 1;
  }

  return Math.min(offset + position.character, text.length);
}
