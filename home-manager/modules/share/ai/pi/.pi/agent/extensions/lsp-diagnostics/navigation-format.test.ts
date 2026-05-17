import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { pathToFileUri } from "./resolver.js";
import {
  formatDocumentSymbolResult,
  formatLocationResult,
  formatWorkspaceSymbolResult,
} from "./navigation-format.js";
import type {
  LspDocumentSymbol,
  LspLocation,
  LspWorkspaceSymbol,
} from "./protocol.js";

function given_tempDir(t: test.TestContext): string {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "lsp-navigation-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  return tempDir;
}

test("formatLocationResult GIVEN matching locations WHEN formatting THEN each result includes a relative path, coordinates, and source preview", (t) => {
  const tempDir = given_tempDir(t);
  const filePath = path.join(tempDir, "src", "math.ts");
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(
    filePath,
    [
      "export function total(value: number) {",
      "  return value + 1;",
      "}",
      "console.log(total(1));",
      "",
    ].join("\n"),
    "utf8",
  );

  const locations: LspLocation[] = [
    {
      uri: pathToFileUri(filePath),
      range: {
        start: { line: 0, character: 16 },
        end: { line: 0, character: 21 },
      },
    },
    {
      uri: pathToFileUri(filePath),
      range: {
        start: { line: 3, character: 12 },
        end: { line: 3, character: 17 },
      },
    },
  ];

  const actual = formatLocationResult(locations, tempDir, {
    title: "Definition",
    maxResults: 10,
  });

  assert.match(actual, /Definition \(2 result\(s\)\)/);
  assert.match(
    actual,
    /src\/math.ts:1:17 \| export function total\(value: number\) \{/,
  );
  assert.match(actual, /src\/math.ts:4:13 \| console\.log\(total\(1\)\);/);
});

test("formatWorkspaceSymbolResult GIVEN symbol hits in multiple files WHEN formatting THEN it shows names, kinds, containers, and locations", (t) => {
  const tempDir = given_tempDir(t);
  const filePath = path.join(tempDir, "src", "math.ts");
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, "export function total() {}\n", "utf8");

  const symbols: LspWorkspaceSymbol[] = [
    {
      name: "total",
      kind: 12,
      containerName: "math",
      location: {
        uri: pathToFileUri(filePath),
        range: {
          start: { line: 0, character: 16 },
          end: { line: 0, character: 21 },
        },
      },
    },
  ];

  const actual = formatWorkspaceSymbolResult(symbols, tempDir, 10);

  assert.match(actual, /Workspace symbols \(1 result\(s\)\)/);
  assert.match(actual, /total \[function\] — math/);
  assert.match(actual, /src\/math.ts:1:17/);
});

test("formatDocumentSymbolResult GIVEN nested document symbols WHEN formatting THEN it preserves the hierarchy with readable kinds", () => {
  const symbols: LspDocumentSymbol[] = [
    {
      name: "Greeter",
      kind: 5,
      range: {
        start: { line: 0, character: 0 },
        end: { line: 4, character: 1 },
      },
      selectionRange: {
        start: { line: 0, character: 6 },
        end: { line: 0, character: 13 },
      },
      children: [
        {
          name: "greet",
          kind: 6,
          range: {
            start: { line: 1, character: 2 },
            end: { line: 3, character: 3 },
          },
          selectionRange: {
            start: { line: 1, character: 2 },
            end: { line: 1, character: 7 },
          },
        },
      ],
    },
  ];

  const actual = formatDocumentSymbolResult("src/greeter.ts", symbols);

  assert.match(actual, /Document symbols for src\/greeter.ts/);
  assert.match(actual, /- Greeter \[class\] @ 1:1-5:2/);
  assert.match(actual, /  - greet \[method\] @ 2:3-4:4/);
});
