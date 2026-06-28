import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import mcpToggleExtension, {
  MCP_ADAPTER_SETTINGS_KEY,
  MCP_TOGGLE_COMMAND,
} from "./index.js";

type RegisteredCommand = {
  description?: string;
  handler: Function;
};

type MockToolInfo = {
  name: string;
  sourceInfo: {
    source: string;
  };
};

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "mcp-toggle-"));

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

function given_savedSettingsFile(tempHome: string, settings: unknown): string {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
  return settingsPath;
}

function when_readingSavedSettingsFile(tempHome: string): unknown {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  return JSON.parse(fs.readFileSync(settingsPath, "utf8"));
}

function given_mcpAdapterTool(name: string): MockToolInfo {
  return {
    name,
    sourceInfo: {
      source: "npm:pi-mcp-adapter",
    },
  };
}

function given_localTool(name: string): MockToolInfo {
  return {
    name,
    sourceInfo: {
      source: "local",
    },
  };
}

function given_mockPi(options?: {
  activeTools?: string[];
  allTools?: MockToolInfo[];
  commandNames?: string[];
}) {
  const sessionStartHandlers: Function[] = [];
  const registeredCommands = new Map<string, RegisteredCommand>();
  const emittedEvents: Array<{ event: string; payload: unknown }> = [];
  const setActiveToolsCalls: string[][] = [];
  let currentActiveTools = [...(options?.activeTools ?? [])];
  const allTools = options?.allTools ?? [];
  const commandNames = options?.commandNames ?? ["cmd:mcp", "cmd:mcp-auth"];

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
      getActiveTools() {
        return [...currentActiveTools];
      },
      getAllTools() {
        return allTools.map((tool) => ({
          ...tool,
          sourceInfo: { ...tool.sourceInfo },
        }));
      },
      setActiveTools(next: string[]) {
        currentActiveTools = [...next];
        setActiveToolsCalls.push([...next]);
      },
      getCommands() {
        return commandNames.map((name) => ({ name }));
      },
      events: {
        emit(event: string, payload: unknown) {
          emittedEvents.push({ event, payload });
        },
      },
    },
    registeredCommands,
    emittedEvents,
    setActiveToolsCalls,
    when_listingCommands() {
      return commandNames.map((name) => name);
    },
    async when_startingSession(ctx: unknown) {
      for (const handler of sessionStartHandlers) {
        await handler({}, ctx);
      }
    },
  };
}

function given_commandContext() {
  const notifications: Array<{ message: string; type?: string }> = [];

  return {
    ctx: {
      cwd: process.cwd(),
      ui: {
        notify(message: string, type?: string) {
          notifications.push({ message, type });
        },
      },
    },
    notifications,
  };
}

async function when_runningCommand(
  commandHandler: Function,
  ctx: unknown,
): Promise<void> {
  await commandHandler("", ctx);
}

test("mcp-toggle GIVEN a persisted disabled setting WHEN the session starts THEN it removes adapter tools and emits the disabled runtime event", async (t) => {
  given_savedSettingsFile(given_tempHome(t), {
    extensionSettings: {
      [MCP_ADAPTER_SETTINGS_KEY]: { enabled: false },
    },
  });
  const { pi, emittedEvents, setActiveToolsCalls, when_startingSession } =
    given_mockPi({
      activeTools: ["read", "mcp", "jira-search"],
      allTools: [
        given_localTool("read"),
        given_mcpAdapterTool("mcp"),
        given_mcpAdapterTool("jira-search"),
      ],
    });
  const { ctx, notifications } = given_commandContext();

  mcpToggleExtension(pi as never);
  await when_startingSession(ctx as never);

  const actual = { emittedEvents, notifications, setActiveToolsCalls };
  const expected = {
    emittedEvents: [{ event: "mcp-adapter:state-changed", payload: false }],
    notifications: [],
    setActiveToolsCalls: [["read"]],
  };

  assert.deepEqual(actual, expected);
});

test("mcp-toggle GIVEN enabled adapter tools WHEN /mcp-toggle disables them THEN it persists the disabled flag, removes every adapter tool, and leaves MCP commands available", async (t) => {
  const tempHome = given_tempHome(t);
  const {
    pi,
    emittedEvents,
    registeredCommands,
    setActiveToolsCalls,
    when_listingCommands,
  } = given_mockPi({
    activeTools: ["read", "mcp", "jira-search", "github-issue"],
    allTools: [
      given_localTool("read"),
      given_mcpAdapterTool("mcp"),
      given_mcpAdapterTool("jira-search"),
      given_mcpAdapterTool("github-issue"),
    ],
  });
  const { ctx, notifications } = given_commandContext();

  mcpToggleExtension(pi as never);

  const command = registeredCommands.get(MCP_TOGGLE_COMMAND);
  assert.ok(command, "Expected MCP toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const actual = {
    emittedEvents,
    listedCommands: when_listingCommands(),
    notifications,
    savedSettings: when_readingSavedSettingsFile(tempHome),
    setActiveToolsCalls,
  };
  const expected = {
    emittedEvents: [{ event: "mcp-adapter:state-changed", payload: false }],
    listedCommands: ["cmd:mcp", "cmd:mcp-auth"],
    notifications: [{ message: "MCP adapter disabled", type: "info" }],
    savedSettings: {
      extensionSettings: {
        [MCP_ADAPTER_SETTINGS_KEY]: {
          enabled: false,
        },
      },
    },
    setActiveToolsCalls: [["read"]],
  };

  assert.deepEqual(actual, expected);
});

test("mcp-toggle GIVEN a persisted disabled adapter state WHEN /mcp-toggle re-enables it THEN it restores every adapter tool and emits the enabled runtime event", async (t) => {
  const tempHome = given_tempHome(t);
  given_savedSettingsFile(tempHome, {
    extensionSettings: {
      [MCP_ADAPTER_SETTINGS_KEY]: { enabled: false },
    },
  });
  const { pi, emittedEvents, registeredCommands, setActiveToolsCalls } =
    given_mockPi({
      activeTools: ["read"],
      allTools: [
        given_localTool("read"),
        given_mcpAdapterTool("mcp"),
        given_mcpAdapterTool("jira-search"),
      ],
    });
  const { ctx, notifications } = given_commandContext();

  mcpToggleExtension(pi as never);

  const command = registeredCommands.get(MCP_TOGGLE_COMMAND);
  assert.ok(command, "Expected MCP toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const actual = {
    emittedEvents,
    notifications,
    savedSettings: when_readingSavedSettingsFile(tempHome),
    setActiveToolsCalls,
  };
  const expected = {
    emittedEvents: [{ event: "mcp-adapter:state-changed", payload: true }],
    notifications: [{ message: "MCP adapter enabled", type: "info" }],
    savedSettings: {
      extensionSettings: {
        [MCP_ADAPTER_SETTINGS_KEY]: {
          enabled: true,
        },
      },
    },
    setActiveToolsCalls: [["read", "mcp", "jira-search"]],
  };

  assert.deepEqual(actual, expected);
});
