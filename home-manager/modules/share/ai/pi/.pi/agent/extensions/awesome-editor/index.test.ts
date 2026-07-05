import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import awesomeEditorExtension, {
  AWESOME_EDITOR_MODE_COMMAND,
} from "./index.js";
import { AWESOME_EDITOR_SETTINGS_KEY } from "./settings.js";

type EditorFactory = (
  tui: unknown,
  theme: unknown,
  keybindings: unknown,
) => unknown;

type RegisteredCommand = {
  description?: string;
  getArgumentCompletions?: (
    prefix: string,
  ) =>
    | Array<{ value: string; label: string }>
    | null
    | Promise<Array<{ value: string; label: string }> | null>;
  handler: Function;
};

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "awesome-editor-"));

  process.env.HOME = tempHome;
  delete process.env.XDG_CONFIG_HOME;

  t.after(() => {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;

    if (previousXdgConfigHome === undefined) delete process.env.XDG_CONFIG_HOME;
    else process.env.XDG_CONFIG_HOME = previousXdgConfigHome;

    fs.rmSync(tempHome, { recursive: true, force: true });
  });

  return tempHome;
}

function given_savedSettingsFile(tempHome: string, settings: unknown): void {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
}

function when_readingSavedSettingsFile(tempHome: string): unknown {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  return JSON.parse(fs.readFileSync(settingsPath, "utf8"));
}

function given_mockPi() {
  const sessionStartHandlers: Function[] = [];
  const registeredCommands = new Map<string, RegisteredCommand>();

  return {
    pi: {
      on(event: string, handler: Function) {
        if (event === "session_start") {
          sessionStartHandlers.push(handler);
        }
      },
      registerCommand(name: string, command: RegisteredCommand) {
        registeredCommands.set(name, command);
      },
    },
    registeredCommands,
    async when_startingSession(ctx: unknown): Promise<void> {
      for (const handler of sessionStartHandlers) {
        await handler({}, ctx);
      }
    },
  };
}

function given_editorContext() {
  const notifications: Array<{ message: string; type?: string }> = [];
  const setEditorComponentCalls: Array<EditorFactory | undefined> = [];

  return {
    ctx: {
      ui: {
        notify(message: string, type?: string) {
          notifications.push({ message, type });
        },
        setEditorComponent(factory: EditorFactory | undefined) {
          setEditorComponentCalls.push(factory);
        },
      },
    },
    notifications,
    setEditorComponentCalls,
  };
}

function given_editorFactory(
  setEditorComponentCalls: Array<EditorFactory | undefined>,
): EditorFactory {
  const actual = setEditorComponentCalls.at(-1);

  assert.ok(actual, "Expected an editor factory to be installed");

  return actual;
}

function given_minimalTui() {
  return {
    requestRender() {},
  };
}

function given_minimalTheme() {
  return {
    borderColor(text: string) {
      return text;
    },
    selectList: {},
  };
}

function given_minimalAppKeybindings() {
  return {
    matches() {
      return false;
    },
  };
}

function when_creatingEditor(factory: EditorFactory) {
  return factory(
    given_minimalTui() as never,
    given_minimalTheme() as never,
    given_minimalAppKeybindings() as never,
  ) as {
    handleInput(data: string): void;
    getText(): string;
  };
}

function when_typingEscapeThenA(editor: {
  handleInput(data: string): void;
  getText(): string;
}): string {
  editor.handleInput("\x1b");
  editor.handleInput("a");

  return editor.getText();
}

async function when_runningCommand(
  commandHandler: Function,
  args: string,
  ctx: unknown,
): Promise<void> {
  await commandHandler(args, ctx);
}

test("awesome-editor GIVEN no persisted mode WHEN the session starts THEN it installs the emacs-style editor", async (t) => {
  given_tempHome(t);
  const { pi, when_startingSession } = given_mockPi();
  const { ctx, setEditorComponentCalls } = given_editorContext();

  awesomeEditorExtension(pi as never);
  await when_startingSession(ctx as never);

  const actual = when_typingEscapeThenA(
    when_creatingEditor(given_editorFactory(setEditorComponentCalls)),
  );
  const expected = "a";

  assert.equal(actual, expected);
});

test("awesome-editor GIVEN a persisted vi mode WHEN the session starts THEN it installs the existing vi editor behavior", async (t) => {
  given_savedSettingsFile(given_tempHome(t), {
    extensionSettings: {
      [AWESOME_EDITOR_SETTINGS_KEY]: { mode: "vi" },
    },
  });
  const { pi, when_startingSession } = given_mockPi();
  const { ctx, setEditorComponentCalls } = given_editorContext();

  awesomeEditorExtension(pi as never);
  await when_startingSession(ctx as never);

  const actual = when_typingEscapeThenA(
    when_creatingEditor(given_editorFactory(setEditorComponentCalls)),
  );
  const expected = "";

  assert.equal(actual, expected);
});

test("awesome-editor GIVEN the mode command WHEN requesting argument completions THEN it suggests both supported modes", async (t) => {
  given_tempHome(t);
  const { pi, registeredCommands } = given_mockPi();

  awesomeEditorExtension(pi as never);

  const command = registeredCommands.get(AWESOME_EDITOR_MODE_COMMAND);
  assert.ok(command, "Expected awesome-editor mode command to be registered");

  const actual = await command.getArgumentCompletions?.("");
  const expected = [
    { value: "vi", label: "vi" },
    { value: "emacs", label: "emacs" },
  ];

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN an invalid mode argument WHEN running /awesome-editor-mode THEN it warns without saving or reconfiguring the editor", async (t) => {
  const tempHome = given_tempHome(t);
  const { pi, registeredCommands } = given_mockPi();
  const { ctx, notifications, setEditorComponentCalls } = given_editorContext();

  awesomeEditorExtension(pi as never);

  const command = registeredCommands.get(AWESOME_EDITOR_MODE_COMMAND);
  assert.ok(command, "Expected awesome-editor mode command to be registered");

  await when_runningCommand(command.handler, "banana", ctx);

  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  const actual = {
    notifications,
    savedSettingsExists: fs.existsSync(settingsPath),
    setEditorComponentCalls,
  };
  const expected = {
    notifications: [
      {
        message: "Usage: /awesome-editor-mode vi|emacs",
        type: "warning",
      },
    ],
    savedSettingsExists: false,
    setEditorComponentCalls: [],
  };

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN sibling extension settings WHEN running /awesome-editor-mode emacs THEN it persists the mode, preserves siblings, and applies the mode immediately", async (t) => {
  const tempHome = given_tempHome(t);
  given_savedSettingsFile(tempHome, {
    sessionName: "demo",
    extensionSettings: {
      [AWESOME_EDITOR_SETTINGS_KEY]: { keep: true },
      webSearch: { enabled: false },
    },
  });
  const { pi, registeredCommands } = given_mockPi();
  const { ctx, notifications, setEditorComponentCalls } = given_editorContext();

  awesomeEditorExtension(pi as never);

  const command = registeredCommands.get(AWESOME_EDITOR_MODE_COMMAND);
  assert.ok(command, "Expected awesome-editor mode command to be registered");

  await when_runningCommand(command.handler, "emacs", ctx);

  const actual = {
    editorBehavior: when_typingEscapeThenA(
      when_creatingEditor(given_editorFactory(setEditorComponentCalls)),
    ),
    notifications,
    savedSettings: when_readingSavedSettingsFile(tempHome),
  };
  const expected = {
    editorBehavior: "a",
    notifications: [{ message: "Awesome editor mode: emacs", type: "info" }],
    savedSettings: {
      sessionName: "demo",
      extensionSettings: {
        [AWESOME_EDITOR_SETTINGS_KEY]: { keep: true, mode: "emacs" },
        webSearch: { enabled: false },
      },
    },
  };

  assert.deepEqual(actual, expected);
});
