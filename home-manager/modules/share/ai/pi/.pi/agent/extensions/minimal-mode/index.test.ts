import assert from "node:assert/strict";
import test from "node:test";
import minimalModeExtension from "./index.js";

function given_mockPi(activeTools: string[] = []) {
  const sessionStartHandlers: Function[] = [];
  const toolCallHandlers: Function[] = [];
  const registeredTools: string[] = [];
  const setActiveToolsCalls: string[][] = [];
  let currentActiveTools = [...activeTools];

  return {
    pi: {
      registerTool(tool: { name: string }) {
        registeredTools.push(tool.name);
      },
      on(event: string, handler: Function) {
        if (event === "session_start") {
          sessionStartHandlers.push(handler);
        }

        if (event === "tool_call") {
          toolCallHandlers.push(handler);
        }
      },
      getActiveTools() {
        return [...currentActiveTools];
      },
      setActiveTools(next: string[]) {
        currentActiveTools = [...next];
        setActiveToolsCalls.push([...next]);
      },
    },
    registeredTools,
    setActiveToolsCalls,
    when_gettingActiveTools() {
      return [...currentActiveTools];
    },
    async when_startingSession() {
      for (const handler of sessionStartHandlers) {
        await handler({}, {});
      }
    },
    async when_handlingToolCall(toolName: string) {
      let actual;

      for (const handler of toolCallHandlers) {
        actual = await handler({ toolName }, {});
      }

      return actual;
    },
  };
}

test("minimal-mode GIVEN active find grep and ls tools WHEN the session starts THEN it removes them from the active tool list", async () => {
  const {
    pi,
    registeredTools,
    setActiveToolsCalls,
    when_gettingActiveTools,
    when_startingSession,
  } = given_mockPi(["read", "find", "bash", "grep", "ls", "write"]);

  minimalModeExtension(pi as never);
  await when_startingSession();

  const actual = when_gettingActiveTools();
  const expected = ["read", "bash", "write"];

  assert.deepEqual(registeredTools, ["read"]);
  assert.deepEqual(setActiveToolsCalls, [expected]);
  assert.deepEqual(actual, expected);
});

test("minimal-mode GIVEN an already filtered tool list WHEN the session starts THEN it leaves the active tools unchanged", async () => {
  const {
    pi,
    setActiveToolsCalls,
    when_gettingActiveTools,
    when_startingSession,
  } = given_mockPi(["read", "bash", "write"]);

  minimalModeExtension(pi as never);
  await when_startingSession();

  const actual = when_gettingActiveTools();
  const expected = ["read", "bash", "write"];

  assert.deepEqual(setActiveToolsCalls, []);
  assert.deepEqual(actual, expected);
});

test("minimal-mode GIVEN an allowed tool call WHEN tool_call runs THEN it does not block execution", async () => {
  const { pi, when_handlingToolCall } = given_mockPi();

  minimalModeExtension(pi as never);

  const actual = await when_handlingToolCall("read");

  assert.equal(actual, undefined);
});
