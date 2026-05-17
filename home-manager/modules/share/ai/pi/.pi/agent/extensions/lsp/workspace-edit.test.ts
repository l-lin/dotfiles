import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { pathToFileUri } from "./resolver.js";
import { applyWorkspaceEdit } from "./workspace-edit.js";
import type { LspWorkspaceEdit } from "./protocol.js";

function given_tempDir(t: test.TestContext): string {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "lsp-workspace-edit-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  return tempDir;
}

test("applyWorkspaceEdit GIVEN multiple edits in one file WHEN applying THEN later offsets are preserved by applying from the end", (t) => {
  const tempDir = given_tempDir(t);
  const filePath = path.join(tempDir, "src", "math.ts");
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, "const sum = 1;\nconsole.log(sum);\n", "utf8");

  const workspaceEdit: LspWorkspaceEdit = {
    changes: {
      [pathToFileUri(filePath)]: [
        {
          range: {
            start: { line: 0, character: 6 },
            end: { line: 0, character: 9 },
          },
          newText: "total",
        },
        {
          range: {
            start: { line: 1, character: 12 },
            end: { line: 1, character: 15 },
          },
          newText: "total",
        },
      ],
    },
  };

  const actual = applyWorkspaceEdit(workspaceEdit, tempDir);
  const actualContent = fs.readFileSync(filePath, "utf8");

  assert.equal(actualContent, "const total = 1;\nconsole.log(total);\n");
  assert.equal(actual.textDocumentCount, 1);
  assert.equal(actual.textEditCount, 2);
  assert.deepEqual(actual.changedPaths, [filePath]);
});

test("applyWorkspaceEdit GIVEN documentChanges with a file rename WHEN applying THEN the rename and text edits are both persisted", (t) => {
  const tempDir = given_tempDir(t);
  const oldFilePath = path.join(tempDir, "src", "Foo.ts");
  const newFilePath = path.join(tempDir, "src", "Bar.ts");
  fs.mkdirSync(path.dirname(oldFilePath), { recursive: true });
  fs.writeFileSync(oldFilePath, "export class Foo {}\n", "utf8");

  const workspaceEdit: LspWorkspaceEdit = {
    documentChanges: [
      {
        kind: "rename",
        oldUri: pathToFileUri(oldFilePath),
        newUri: pathToFileUri(newFilePath),
      },
      {
        textDocument: { uri: pathToFileUri(newFilePath) },
        edits: [
          {
            range: {
              start: { line: 0, character: 13 },
              end: { line: 0, character: 16 },
            },
            newText: "Bar",
          },
        ],
      },
    ],
  };

  const actual = applyWorkspaceEdit(workspaceEdit, tempDir);

  assert.equal(fs.existsSync(oldFilePath), false);
  assert.equal(fs.existsSync(newFilePath), true);
  assert.equal(fs.readFileSync(newFilePath, "utf8"), "export class Bar {}\n");
  assert.equal(actual.renameCount, 1);
  assert.equal(actual.textDocumentCount, 1);
  assert.equal(actual.textEditCount, 1);
  assert.deepEqual(actual.changedPaths, [newFilePath]);
});
