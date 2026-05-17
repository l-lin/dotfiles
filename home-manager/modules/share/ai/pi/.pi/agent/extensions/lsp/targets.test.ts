import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { resolveTargetContext } from "./targets.js";
import type { LspDiagnosticsFileConfig } from "./types.js";

function given_tempDir(t: test.TestContext): string {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "lsp-targets-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  return tempDir;
}

const TEST_FILE_CONFIG: LspDiagnosticsFileConfig = {
  servers: {
    vtsls: {
      command: "vtsls",
      args: ["--stdio"],
      fileTypes: [".ts"],
      rootMarkers: ["package.json"],
    },
    "lua-language-server": {
      command: "lua-language-server",
      fileTypes: [".lua"],
      rootMarkers: [".git"],
    },
  },
};

test("resolveTargetContext GIVEN a directory with multiple supported languages WHEN resolving THEN it keeps supported files and a representative root source per server", (t) => {
  const tempDir = given_tempDir(t);
  fs.mkdirSync(path.join(tempDir, "src"), { recursive: true });
  fs.mkdirSync(path.join(tempDir, "lua"), { recursive: true });
  fs.mkdirSync(path.join(tempDir, "node_modules", "ignored"), {
    recursive: true,
  });
  fs.writeFileSync(
    path.join(tempDir, "src", "app.ts"),
    "export const app = 1;\n",
    "utf8",
  );
  fs.writeFileSync(
    path.join(tempDir, "lua", "init.lua"),
    "return {}\n",
    "utf8",
  );
  fs.writeFileSync(
    path.join(tempDir, "node_modules", "ignored", "nope.ts"),
    "export const nope = true;\n",
    "utf8",
  );

  const actual = resolveTargetContext(".", tempDir, null, TEST_FILE_CONFIG);

  assert.deepEqual(
    actual.files.map((filePath) => path.relative(tempDir, filePath)).sort(),
    ["lua/init.lua", "src/app.ts"],
  );
  assert.deepEqual(
    actual.commands
      .map(({ resolved, rootSourcePath }) => ({
        command: path.basename(resolved.command[0]!),
        rootSourcePath: path.relative(tempDir, rootSourcePath),
      }))
      .sort((left, right) => left.command!.localeCompare(right.command!)),
    [
      { command: "lua-language-server", rootSourcePath: "lua/init.lua" },
      { command: "vtsls", rootSourcePath: "src/app.ts" },
    ],
  );
});
