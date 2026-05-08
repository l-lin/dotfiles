import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import contextExtension from "./index.js";

type ListedCommand = {
  name: string;
  description?: string;
  source: string;
  sourceInfo: { path?: string };
};

type RegisteredCommand = {
  handler: Function;
};

function given_tempDirectory(t: test.TestContext, prefix: string): string {
  const directoryPath = fs.mkdtempSync(path.join(os.tmpdir(), prefix));

  t.after(() => {
    fs.rmSync(directoryPath, { recursive: true, force: true });
  });

  return directoryPath;
}

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = given_tempDirectory(t, "context-home-");

  process.env.HOME = tempHome;
  delete process.env.XDG_CONFIG_HOME;

  t.after(() => {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;

    if (previousXdgConfigHome === undefined) delete process.env.XDG_CONFIG_HOME;
    else process.env.XDG_CONFIG_HOME = previousXdgConfigHome;
  });

  return tempHome;
}

function given_mockPi(listedCommands: ListedCommand[]) {
  const registeredCommands = new Map<string, RegisteredCommand>();
  const sentMessages: Array<{ content: string; customType: string }> = [];

  return {
    pi: {
      on() {},
      registerCommand(name: string, command: RegisteredCommand) {
        registeredCommands.set(name, command);
      },
      getCommands() {
        return listedCommands;
      },
      getActiveTools() {
        return [];
      },
      getAllTools() {
        return [];
      },
      sendMessage(message: { content: string; customType: string }) {
        sentMessages.push(message);
      },
      appendEntry() {},
    },
    registeredCommands,
    sentMessages,
  };
}

function given_commandContext(cwd: string) {
  return {
    cwd,
    hasUI: false,
    getSystemPrompt() {
      return "";
    },
    getContextUsage() {
      return null;
    },
    sessionManager: {
      getSessionId() {
        return "session-1";
      },
      getEntries() {
        return [];
      },
    },
  };
}

async function when_runningContextCommand(
  commandHandler: Function,
  ctx: unknown,
): Promise<void> {
  await commandHandler("", ctx);
}

test("context GIVEN an extension entrypoint on a directory index file WHEN rendering plain text output THEN it shows the directory name instead of index.ts", async (t) => {
  given_tempHome(t);
  const tempCwd = given_tempDirectory(t, "context-cwd-");
  const extensionEntrypointPath = path.join(tempCwd, "context", "index.ts");
  const listedCommands: ListedCommand[] = [
    {
      name: "cmd:test-extension",
      description: "test extension command",
      source: "extension",
      sourceInfo: { path: extensionEntrypointPath },
    },
  ];
  const { pi, registeredCommands, sentMessages } = given_mockPi(listedCommands);

  contextExtension(pi as never);

  const command = registeredCommands.get("cmd:context");
  assert.ok(command, "Expected cmd:context to be registered");

  await when_runningContextCommand(
    command.handler,
    given_commandContext(tempCwd),
  );

  assert.equal(sentMessages.length, 1);

  const actual = sentMessages[0]?.content ?? "";
  const expected = /Extensions \(1\): context/;

  assert.match(actual, expected);
  assert.ok(!actual.includes("index.ts"));
});
