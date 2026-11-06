import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test, { type TestContext } from "node:test";
import { promisify } from "node:util";
import {
  SessionManager,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type ExtensionContext,
  type SessionStartEvent,
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
    mode?: ExtensionContext["mode"];
    manager?: SessionManager;
    switchSession?: ExtensionCommandContext["switchSession"];
  } = {},
) {
  type Handler = (event: unknown, ctx: ExtensionContext) => unknown;
  const handlers = new Map<string, Handler>();
  const commands = new Map<string, { handler: Handler }>();
  const dispatched: Promise<unknown>[] = [];
  const names: string[] = [];
  const calls: unknown[] = [];
  const switches: string[] = [];
  const notices: unknown[] = [];
  const messages: unknown[] = [];
  let name = options.name;
  branchSessionName({
    on(event: string, callback: Handler) {
      handlers.set(event, callback);
    },
    registerCommand(command: string, options: { handler: Handler }) {
      commands.set(command, options);
    },
    sendUserMessage(content: string, options: unknown) {
      messages.push([content, options]);
      dispatched.push(
        Promise.resolve(commands.get(content.slice(1))!.handler("", ctx)),
      );
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
      options.manager?.appendSessionInfo(value);
    },
  } as unknown as ExtensionAPI);
  const ctx = {
    cwd: options.cwd ?? "/project/subdirectory",
    mode: options.mode,
    sessionManager: options.manager ?? {
      getSessionName: () => name,
      getSessionFile: () => options.file,
      getSessionId: () => "new-session",
      getSessionDir: () => "/sessions",
      getHeader: () => ({ parentSession: options.parentSession }),
      getEntries: () =>
        options.messages ? [{ type: "message" }] : [{ type: "model_change" }],
    },
    ui: {
      notify: (...args: unknown[]) => notices.push(args),
    },
    async switchSession(path: string) {
      switches.push(path);
      if (options.switchSession) return options.switchSession(path);
      await handlers.get("session_shutdown")!({}, ctx);
      return { cancelled: false };
    },
  } as unknown as ExtensionContext;
  return {
    names,
    calls,
    switches,
    notices,
    messages,
    when_starting: async (reason: SessionStartEvent["reason"]) => {
      await handlers.get("session_start")!(
        { type: "session_start", reason },
        ctx,
      );
    },
    when_discovering: async (beforeDispatch?: () => unknown) => {
      await handlers.get("resources_discover")!({}, ctx);
      await beforeDispatch?.();
      await new Promise<void>((resolve) => setImmediate(resolve));
      await Promise.all(dispatched);
    },
    when_shutting_down: () => handlers.get("session_shutdown")!({}, ctx),
    when_renaming: (value: string) => {
      name = value;
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

function given_saved_sessions(t: TestContext) {
  const directory = mkdtempSync(join(tmpdir(), "branch-session-resume-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const cwd = join(directory, "project");
  mkdirSync(cwd);
  const sessionDir = join(directory, "sessions");
  return {
    cwd,
    manager: SessionManager.create(cwd, sessionDir),
    given_saved_session(name: string, timestamp: number, sessionCwd = cwd) {
      const manager = SessionManager.create(sessionCwd, sessionDir);
      manager.appendSessionInfo(name);
      manager.appendMessage({
        role: "user",
        content: "Saved conversation",
        timestamp,
      });
      return manager.getSessionFile()!;
    },
  };
}

const branch = "feature/ABC-123-add-search";

for (const matching of [true, false]) {
  test(`GIVEN matching session ${matching} WHEN interactive startup completes THEN only an exact name resumes`, async (t) => {
    const saved = given_saved_sessions(t);
    const path = saved.given_saved_session(
      matching ? branch : `${branch}-other`,
      1000,
    );
    const session = given_session({ ...saved, mode: "tui" });
    await session.when_starting("startup");
    const beforeDiscovery = [...session.switches];
    await session.when_discovering();
    const actual = {
      beforeDiscovery,
      switches: session.switches,
      names: session.names,
      notices: session.notices,
      messages: session.messages,
    };
    const expected = {
      beforeDiscovery: [],
      switches: matching ? [path] : [],
      names: [branch],
      notices: [],
      messages: [
        ["/branch-session-auto-resume", { expandPromptTemplates: true }],
      ],
    };
    assert.deepEqual(actual, expected);
  });
}

test("GIVEN duplicate names WHEN startup completes THEN the latest matching session in the current directory resumes", async (t) => {
  const saved = given_saved_sessions(t);
  saved.given_saved_session(branch, 1000);
  const latest = saved.given_saved_session(branch, 2000);
  saved.given_saved_session(branch.toUpperCase(), 3000);
  saved.given_saved_session(branch, 4000, join(saved.cwd, "subdirectory"));
  const session = given_session({ ...saved, mode: "tui" });
  await session.when_starting("startup");
  await session.when_discovering();
  const actual = session.switches;
  const expected = [latest];
  assert.deepEqual(actual, expected);
});

for (const mode of ["rpc", "json", "print"] as const) {
  test(`GIVEN ${mode} mode WHEN startup completes THEN automatic resume does not run`, async (t) => {
    const saved = given_saved_sessions(t);
    saved.given_saved_session(branch, 1000);
    const session = given_session({ ...saved, mode });
    await session.when_starting("startup");
    await session.when_discovering();
    const actual = { messages: session.messages, names: session.names };
    const expected = { messages: [], names: [branch] };
    assert.deepEqual(actual, expected);
  });
}

for (const reason of ["new", "reload", "resume", "fork"] as const) {
  test(`GIVEN a matching session WHEN ${reason} occurs THEN automatic resume does not run`, async (t) => {
    const saved = given_saved_sessions(t);
    saved.given_saved_session(branch, 1000);
    const session = given_session({ ...saved, mode: "tui" });
    await session.when_starting(reason);
    await session.when_discovering();
    const actual = session.messages;
    const expected: unknown[] = [];
    assert.deepEqual(actual, expected);
  });
}

for (const arg of [
  "--continue",
  "-c",
  "--resume",
  "-r",
  "--session",
  "--no-session",
]) {
  test(`GIVEN explicit ${arg} WHEN startup completes THEN automatic resume does not run`, async (t) => {
    const argv = process.argv;
    process.argv = [...argv, arg];
    t.after(() => {
      process.argv = argv;
    });
    const saved = given_saved_sessions(t);
    saved.given_saved_session(branch, 1000);
    const session = given_session({ ...saved, mode: "tui" });
    await session.when_starting("startup");
    await session.when_discovering();
    const actual = session.messages;
    const expected: unknown[] = [];
    assert.deepEqual(actual, expected);
  });
}

for (const options of [
  { name: "Chosen session" },
  { messages: true },
  { parentSession: "/parent.jsonl" },
]) {
  test(`GIVEN existing state ${JSON.stringify(options)} WHEN interactive startup completes THEN automatic resume does not run`, async () => {
    const session = given_session({
      ...options,
      mode: "tui",
      file: "/unsaved-session.jsonl",
    });
    await session.when_starting("startup");
    await session.when_discovering();
    const actual = session.messages;
    const expected: unknown[] = [];
    assert.deepEqual(actual, expected);
  });
}

for (const result of [
  { stdout: "main\n" },
  { stdout: "master\n" },
  { stdout: "\n" },
  { code: 1 },
  { killed: true },
  { truncated: true },
]) {
  test(`GIVEN Git result ${JSON.stringify(result)} WHEN interactive startup completes THEN lookup does not run`, async () => {
    const session = given_session({
      mode: "tui",
      file: "/unsaved-session.jsonl",
      exec: async () => ({
        stdout: branch,
        stderr: "",
        code: 0,
        killed: false,
        truncated: false,
        ...result,
      }),
    });
    await session.when_starting("startup");
    await session.when_discovering();
    const actual = { messages: session.messages, names: session.names };
    const expected = { messages: [], names: [] };
    assert.deepEqual(actual, expected);
  });
}

test("GIVEN session lookup fails WHEN startup completes THEN branch naming remains and a warning appears", async (t) => {
  t.mock.method(SessionManager, "list", async () => {
    throw new Error("Lookup failed");
  });
  const session = given_session({
    mode: "tui",
    file: "/unsaved-session.jsonl",
  });
  await session.when_starting("startup");
  await session.when_discovering();
  const actual = {
    names: session.names,
    notices: session.notices,
    switches: session.switches,
  };
  const expected = {
    names: [branch],
    notices: [["Cannot resume the branch session: Lookup failed", "warning"]],
    switches: [],
  };
  assert.deepEqual(actual, expected);
});

for (const cancelled of [true, false]) {
  test(`GIVEN resume ${cancelled ? "is cancelled" : "throws"} WHEN startup completes THEN branch naming remains and a warning appears`, async (t) => {
    const saved = given_saved_sessions(t);
    const path = saved.given_saved_session(branch, 1000);
    const session = given_session({
      ...saved,
      mode: "tui",
      switchSession: async () => {
        if (cancelled) return { cancelled: true };
        throw new Error("Resume failed");
      },
    });
    await session.when_starting("startup");
    await session.when_discovering();
    const actual = {
      names: session.names,
      notices: session.notices,
      switches: session.switches,
    };
    const expected = {
      names: [branch],
      notices: [
        [
          cancelled
            ? "Automatic branch session resume was cancelled."
            : "Cannot resume the branch session: Resume failed",
          "warning",
        ],
      ],
      switches: [path],
    };
    assert.deepEqual(actual, expected);
  });
}

test("GIVEN shutdown before resource discovery WHEN startup completes THEN no command runs", async () => {
  const session = given_session({
    mode: "tui",
    file: "/unsaved-session.jsonl",
  });
  await session.when_starting("startup");
  await session.when_shutting_down();
  await session.when_discovering();
  const actual = session.messages;
  const expected: unknown[] = [];
  assert.deepEqual(actual, expected);
});

test("GIVEN shutdown before command dispatch WHEN resources are discovered THEN the pending command is cancelled", async () => {
  const session = given_session({
    mode: "tui",
    file: "/unsaved-session.jsonl",
  });
  await session.when_starting("startup");
  await session.when_discovering(session.when_shutting_down);
  const actual = { messages: session.messages, notices: session.notices };
  const expected = { messages: [], notices: [] };
  assert.deepEqual(actual, expected);
});

test("GIVEN shutdown during lookup WHEN lookup completes THEN the old runtime does not switch or notify", async (t) => {
  const session = given_session({
    mode: "tui",
    file: "/unsaved-session.jsonl",
  });
  t.mock.method(SessionManager, "list", async () => {
    await session.when_shutting_down();
    throw new Error("Runtime closed");
  });
  await session.when_starting("startup");
  await session.when_discovering();
  const actual = { switches: session.switches, notices: session.notices };
  const expected = { switches: [], notices: [] };
  assert.deepEqual(actual, expected);
});

test("GIVEN the user renames the session during lookup WHEN lookup completes THEN automatic resume does not replace it", async (t) => {
  const session = given_session({
    mode: "tui",
    file: "/unsaved-session.jsonl",
  });
  t.mock.method(SessionManager, "list", async () => {
    session.when_renaming("User choice");
    return [];
  });
  await session.when_starting("startup");
  await session.when_discovering();
  const actual = { switches: session.switches, notices: session.notices };
  const expected = { switches: [], notices: [] };
  assert.deepEqual(actual, expected);
});
