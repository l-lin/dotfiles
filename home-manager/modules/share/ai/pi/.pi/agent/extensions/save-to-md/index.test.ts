import assert from "node:assert/strict";
import {
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rm,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import {
  InMemoryCredentialStore,
  type AssistantMessage,
} from "@earendil-works/pi-ai";
import {
  discoverAndLoadExtensions,
  ExtensionRunner,
  ModelRegistry,
  ModelRuntime,
  SessionManager,
} from "@earendil-works/pi-coding-agent";

const extensionPath = dirname(fileURLToPath(import.meta.url));

function assistantMessage(markdown: string): AssistantMessage {
  return {
    role: "assistant",
    content: [{ type: "text", text: markdown }],
    api: "anthropic-messages",
    provider: "anthropic",
    model: "test-model",
    usage: {
      input: 0,
      output: 0,
      cacheRead: 0,
      cacheWrite: 0,
      totalTokens: 0,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
    },
    stopReason: "stop",
    timestamp: Date.now(),
  };
}

async function createHarness(cwd: string) {
  const sessionManager = SessionManager.inMemory(cwd);
  const loaded = await discoverAndLoadExtensions(
    [extensionPath],
    cwd,
    join(cwd, ".agent"),
  );
  assert.deepEqual(loaded.errors, []);
  const sentMessages: Array<{
    message: { customType: string; content: unknown; display: boolean };
    options?: { deliverAs?: "steer" | "followUp" | "nextTurn" };
  }> = [];
  loaded.runtime.sendMessage = (message, options) => {
    sentMessages.push({ message, options });
  };
  const modelRuntime = await ModelRuntime.create({
    credentials: new InMemoryCredentialStore(),
    modelsPath: null,
    allowModelNetwork: false,
  });

  const runner = new ExtensionRunner(
    loaded.extensions,
    loaded.runtime,
    cwd,
    sessionManager,
    new ModelRegistry(modelRuntime),
  );
  const notifications: Array<{
    message: string;
    type?: "info" | "warning" | "error";
  }> = [];
  runner.setUIContext({
    ...runner.getUIContext(),
    notify: (message, type) => notifications.push({ message, type }),
  });

  return { notifications, runner, sentMessages, sessionManager };
}

test("user can save the latest assistant response as Markdown with /cmd:save-to-md", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-save-to-md-"));

  try {
    const { notifications, runner, sentMessages, sessionManager } =
      await createHarness(cwd);
    const markdown =
      "# Design\n\n- Preserve **Markdown**\n\n```ts\nconst ready = true;\n```";
    sessionManager.appendMessage(assistantMessage(markdown));

    const command = runner.getCommand("cmd:save-to-md");
    assert.ok(command, "/cmd:save-to-md should be registered");
    await command.handler("design", runner.createCommandContext());

    const path = join(cwd, ".sandbox", "responses", "design.md");
    assert.equal(await readFile(path, "utf8"), `${markdown}\n`);
    assert.deepEqual(notifications, [
      { message: `Saved Markdown to ${path}`, type: "info" },
    ]);
    assert.deepEqual(sentMessages, [
      {
        message: {
          customType: "save-to-md",
          content: `Saved Markdown to ${path}`,
          display: true,
        },
        options: { deliverAs: "nextTurn" },
      },
    ]);
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});

test("saving does not rewrite the assistant's Markdown", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-save-to-md-"));

  try {
    const { runner, sessionManager } = await createHarness(cwd);
    const markdown = "Paragraph with deliberate trailing space  \n\n";
    sessionManager.appendMessage(assistantMessage(markdown));

    const command = runner.getCommand("cmd:save-to-md");
    assert.ok(command);
    await command.handler("verbatim.md", runner.createCommandContext());

    assert.equal(
      await readFile(join(cwd, ".sandbox", "responses", "verbatim.md"), "utf8"),
      markdown,
    );
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});

test("user gets a default Markdown filename when /cmd:save-to-md is missing a name", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-save-to-md-"));

  try {
    const { notifications, runner, sessionManager } = await createHarness(cwd);
    sessionManager.appendMessage(assistantMessage("# Unsaved"));

    const command = runner.getCommand("cmd:save-to-md");
    assert.ok(command);
    await command.handler("   ", runner.createCommandContext());

    assert.deepEqual(await readdir(cwd), [".sandbox"]);
    const directory = join(cwd, ".sandbox", "responses");
    const actual = await readdir(directory);
    const expected = 1;
    assert.equal(actual.length, expected);
    assert.match(actual[0], /^\d{4}-\d{2}-\d{2}-\d{6}\.md$/);
    assert.equal(
      await readFile(join(directory, actual[0]), "utf8"),
      "# Unsaved\n",
    );
    assert.deepEqual(notifications, [
      {
        message: `Saved Markdown to ${join(directory, actual[0])}`,
        type: "info",
      },
    ]);
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});

test("user cannot accidentally overwrite an existing Markdown file", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-save-to-md-"));

  try {
    const path = join(cwd, ".sandbox", "responses", "design.md");
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, "existing content\n", "utf8");
    const { notifications, runner, sessionManager } = await createHarness(cwd);
    sessionManager.appendMessage(assistantMessage("# Replacement"));

    const command = runner.getCommand("cmd:save-to-md");
    assert.ok(command);
    await command.handler("design", runner.createCommandContext());

    assert.equal(await readFile(path, "utf8"), "existing content\n");
    assert.deepEqual(notifications, [
      { message: `File already exists: ${path}`, type: "error" },
    ]);
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});

test("user saves the latest assistant response on the active branch", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-save-to-md-"));

  try {
    const { runner, sessionManager } = await createHarness(cwd);
    const activeAssistantId = sessionManager.appendMessage(
      assistantMessage("# Active branch"),
    );
    sessionManager.appendMessage(assistantMessage("# Abandoned branch"));
    sessionManager.branch(activeAssistantId);

    const command = runner.getCommand("cmd:save-to-md");
    assert.ok(command);
    await command.handler("branch", runner.createCommandContext());

    assert.equal(
      await readFile(join(cwd, ".sandbox", "responses", "branch.md"), "utf8"),
      "# Active branch\n",
    );
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});

test("user is warned when the latest assistant response has no Markdown text", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-save-to-md-"));

  try {
    const { notifications, runner, sessionManager } = await createHarness(cwd);
    sessionManager.appendMessage(assistantMessage("   "));

    const command = runner.getCommand("cmd:save-to-md");
    assert.ok(command);
    await command.handler("answer", runner.createCommandContext());

    assert.deepEqual(await readdir(cwd), []);
    assert.deepEqual(notifications, [
      {
        message: "The latest assistant response has no Markdown text",
        type: "warning",
      },
    ]);
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});

test("user is warned when there is no assistant response to save", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-save-to-md-"));

  try {
    const { notifications, runner } = await createHarness(cwd);

    const command = runner.getCommand("cmd:save-to-md");
    assert.ok(command);
    await command.handler("answer", runner.createCommandContext());

    assert.deepEqual(await readdir(cwd), []);
    assert.deepEqual(notifications, [
      { message: "No assistant response to save", type: "warning" },
    ]);
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});
