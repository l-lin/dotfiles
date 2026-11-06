import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionStartEvent,
} from "@earendil-works/pi-coding-agent";
import branchSessionName from "./index.js";

const exec = promisify(execFile);

function given_session(
  options: {
    name?: string;
    file?: string;
    parentSession?: string;
    messages?: boolean;
    exec?: ExtensionAPI["exec"];
    cwd?: string;
  } = {},
) {
  let handler!: (event: SessionStartEvent, ctx: ExtensionContext) => unknown;
  const names: string[] = [];
  const calls: unknown[] = [];
  let name = options.name;
  branchSessionName({
    on(event: string, callback: typeof handler) {
      if (event === "session_start") handler = callback;
    },
    async exec(...args: Parameters<ExtensionAPI["exec"]>) {
      calls.push(args);
      if (options.exec) return options.exec(...args);
      return {
        stdout: "feature/ABC-123-add-search\n",
        stderr: "",
        code: 0,
        killed: false,
        truncated: false,
      };
    },
    setSessionName(value: string) {
      names.push(value);
      name = value;
    },
  } as unknown as ExtensionAPI);
  const ctx = {
    cwd: options.cwd ?? "/project/subdirectory",
    sessionManager: {
      getSessionName: () => name,
      getSessionFile: () => options.file,
      getHeader: () => ({ parentSession: options.parentSession }),
      getEntries: () =>
        options.messages ? [{ type: "message" }] : [{ type: "model_change" }],
    },
  } as unknown as ExtensionContext;
  return {
    names,
    calls,
    when_starting: async (reason: SessionStartEvent["reason"]) => {
      await handler({ type: "session_start", reason }, ctx);
    },
  };
}

for (const reason of ["startup", "new"] as const) {
  test(`GIVEN an unnamed session WHEN ${reason} occurs THEN the exact branch becomes its name`, async () => {
    const session = given_session();
    await session.when_starting(reason);
    const actual = { names: session.names, calls: session.calls };
    const expected = {
      names: ["feature/ABC-123-add-search"],
      calls: [
        [
          "git",
          ["branch", "--show-current"],
          { cwd: "/project/subdirectory", timeout: 5000 },
        ],
      ],
    };
    assert.deepEqual(actual, expected);
  });
}

for (const reason of ["resume", "reload", "fork"] as const) {
  test(`GIVEN an unnamed session WHEN ${reason} occurs THEN naming does not run`, async () => {
    const session = given_session();
    await session.when_starting(reason);
    const actual = session.calls;
    const expected: unknown[] = [];
    assert.deepEqual(actual, expected);
  });
}

for (const options of [
  { name: "Explicit name" },
  { messages: true },
  { parentSession: "/parent.jsonl" },
]) {
  test(`GIVEN existing session state ${JSON.stringify(options)} WHEN startup occurs THEN naming does not run`, async () => {
    const session = given_session(options);
    await session.when_starting("startup");
    const actual = session.calls;
    const expected: unknown[] = [];
    assert.deepEqual(actual, expected);
  });
}

test("GIVEN a saved unnamed session WHEN startup occurs THEN naming does not run", async (t) => {
  const directory = mkdtempSync(join(tmpdir(), "branch-session-name-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const file = join(directory, "session.jsonl");
  writeFileSync(file, "");
  const session = given_session({ file });
  await session.when_starting("startup");
  const actual = session.calls;
  const expected: unknown[] = [];
  assert.deepEqual(actual, expected);
});

for (const result of [
  { stdout: "main\n" },
  { stdout: "master\n" },
  { stdout: "\n" },
  { code: 1 },
  { killed: true },
  { truncated: true },
]) {
  test(`GIVEN Git result ${JSON.stringify(result)} WHEN a new session starts THEN its name stays unchanged`, async () => {
    const session = given_session({
      exec: async () => ({
        stdout: "feature/test\n",
        stderr: "",
        code: 0,
        killed: false,
        truncated: false,
        ...result,
      }),
    });
    await session.when_starting("new");
    const actual = session.names;
    const expected: string[] = [];
    assert.deepEqual(actual, expected);
  });
}

test("GIVEN Git cannot run WHEN a new session starts THEN the failure stays silent", async () => {
  const session = given_session({
    exec: async () => {
      throw new Error("Git is unavailable");
    },
  });
  await session.when_starting("new");
  const actual = session.names;
  const expected: string[] = [];
  assert.deepEqual(actual, expected);
});

test("GIVEN a named session WHEN another startup occurs THEN its name stays unchanged", async () => {
  const session = given_session();
  await session.when_starting("new");
  await session.when_starting("startup");
  const actual = session.names;
  const expected = ["feature/ABC-123-add-search"];
  assert.deepEqual(actual, expected);
});

test("GIVEN a Git repository WHEN sessions start from a subdirectory THEN Git supplies the branch", async (t) => {
  const directory = mkdtempSync(join(tmpdir(), "branch-session-name-git-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  await exec("git", ["init", "--initial-branch=feature/ABC-123"], {
    cwd: directory,
  });
  const cwd = join(directory, "subdirectory");
  mkdirSync(cwd);
  const session = given_session({
    cwd,
    exec: async (command, args, options) => {
      const result = await exec(command, args, { cwd: options?.cwd });
      return { ...result, code: 0, killed: false, truncated: false };
    },
  });
  await session.when_starting("new");
  const actual = session.names;
  const expected = ["feature/ABC-123"];
  assert.deepEqual(actual, expected);
});
