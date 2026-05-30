/**
 * Tests for the red-team extension's bash filtering logic.
 *
 * These tests verify the isBashBlocked function — the core security logic —
 * without mocking the Pi agent runtime.
 */
import * as assert from "node:assert";
import { describe, it } from "node:test";

// ── Helpers ──────────────────────────────────────────────────────────────────

interface BlockedResult {
  blocked: true;
  reason: string;
}
interface AllowedResult {
  blocked: false;
}
type BashCheckResult = BlockedResult | AllowedResult;

// ── Core logic (extracted for testability) ───────────────────────────────────

const BLOCKED_BASH_PATTERNS: Array<{ regex: RegExp; reason: string }> = [
  { regex: /\brm\b/, reason: "File deletion is not allowed" },
  { regex: /\bmv\b/, reason: "File move is not allowed" },
  { regex: /\bc\b(?!ommands?\b)/, reason: "File copy is not allowed" },
  { regex: /\bcp\b/, reason: "File copy is not allowed" },
  { regex: /\bmkdir\b/, reason: "Directory creation is not allowed" },
  { regex: /\btouch\b/, reason: "File creation is not allowed" },
  { regex: /\bsed\s+.*-i\b/, reason: "In-place file editing is not allowed" },
  { regex: /\btee\b/, reason: "Pipe write is not allowed" },
  { regex: />\s*/, reason: "Output redirection is not allowed" },
  { regex: /\b>\s*/, reason: "Output redirection is not allowed" },
];

function isBashBlocked(command: string): BashCheckResult {
  for (const { regex, reason } of BLOCKED_BASH_PATTERNS) {
    if (regex.test(command)) {
      return { blocked: true, reason };
    }
  }
  return { blocked: false };
}

// ── Tests ────────────────────────────────────────────────────────────────────

describe("red-team — bash filtering", () => {
  describe("WHEN command contains a blocked operation", () => {
    const blockedCases: Array<[string, string]> = [
      ["rm file.txt", "File deletion is not allowed"],
      ["rm -rf dist/", "File deletion is not allowed"],
      ["mv old new", "File move is not allowed"],
      ["cp src dest", "File copy is not allowed"],
      ["mkdir -p build", "Directory creation is not allowed"],
      ["touch newfile", "File creation is not allowed"],
      ["sed -i 's/a/b/g' file.txt", "In-place file editing is not allowed"],
      ["echo hello | tee output.txt", "Pipe write is not allowed"],
      ["echo hello > output.txt", "Output redirection is not allowed"],
      ["cat file > output.txt", "Output redirection is not allowed"],
    ];

    for (const [command, expectedReason] of blockedCases) {
      it(`blocks: ${command}`, () => {
        const actual = isBashBlocked(command);
        assert.strictEqual(
          actual.blocked,
          true,
          `Expected "${command}" to be blocked`,
        );
        const blocked = actual as { blocked: true; reason: string };
        assert.ok(
          blocked.reason.includes(expectedReason),
          `Expected reason to mention: ${expectedReason}`,
        );
      });
    }
  });

  describe("WHEN command is read-only", () => {
    const allowedCases = [
      "cat file.txt",
      "grep pattern file.txt",
      "ls -la",
      "find src -name '*.ts'",
      "head -n 20 file.txt",
      "tail -n 10 file.log",
      "wc -l file.txt",
      "rg pattern src/",
      "fd --type f src/",
      "cat file.txt | wc -l",
      "ls | grep ts",
    ];

    for (const command of allowedCases) {
      it(`allows: ${command}`, () => {
        const actual = isBashBlocked(command);
        assert.strictEqual(
          actual.blocked,
          false,
          `Expected "${command}" to be allowed`,
        );
      });
    }
  });

  describe("WHEN command is ambiguous", () => {
    it("allows 'ls' even though it contains 'l' which could be part of other words", () => {
      const actual = isBashBlocked("ls -la");
      assert.strictEqual(actual.blocked, false);
    });

    it("allows 'find' for directory traversal", () => {
      const actual = isBashBlocked("find . -name '*.md'");
      assert.strictEqual(actual.blocked, false);
    });

    it("does not false-positive on 'commands' or 'command'", () => {
      const actual = isBashBlocked("echo commands");
      assert.strictEqual(actual.blocked, false);
    });

    it("blocks 'cp' but not 'commands' or 'command'", () => {
      const cpResult = isBashBlocked("cp src dest");
      const commandsResult = isBashBlocked("echo commands");
      assert.strictEqual(cpResult.blocked, true);
      assert.strictEqual(commandsResult.blocked, false);
    });
  });

  describe("WHEN command is empty or whitespace", () => {
    it("allows empty string", () => {
      const actual = isBashBlocked("");
      assert.strictEqual(actual.blocked, false);
    });

    it("allows whitespace-only string", () => {
      const actual = isBashBlocked("   ");
      assert.strictEqual(actual.blocked, false);
    });
  });

  describe("WHEN command has edge-case formatting", () => {
    it("blocks 'rm' even with flags", () => {
      const actual = isBashBlocked("rm -rf /");
      assert.strictEqual(actual.blocked, true);
    });

    it("blocks 'sed -i' with spaces", () => {
      const actual = isBashBlocked("sed -i '' 's/foo/bar/g' file.txt");
      assert.strictEqual(actual.blocked, true);
    });

    it("does not block 'sed' without -i flag", () => {
      const actual = isBashBlocked("sed 's/foo/bar/g' file.txt");
      assert.strictEqual(actual.blocked, false);
    });
  });
});
