import assert from "node:assert/strict";
import test from "node:test";
import minimalModeExtension from "./index.js";
import { getBuiltInTools } from "./tool-cache.js";

type RegisteredTool = {
  name: string;
  parameters: object;
  renderResult?: Function;
};

function given_mockPi() {
  const registeredTools: RegisteredTool[] = [];

  return {
    pi: {
      registerTool(tool: RegisteredTool) {
        registeredTools.push(tool);
      },
    },
    registeredTools,
  };
}

test("minimal-mode GIVEN pi 0.62 built-in override detection WHEN loading THEN parameter schemas are cloned so custom renderers stay active", () => {
  const { pi, registeredTools } = given_mockPi();

  minimalModeExtension(pi as never);

  const actualByName = new Map(
    registeredTools.map((tool) => [tool.name, tool]),
  );
  const builtInTools = getBuiltInTools(process.cwd());

  for (const name of ["read", "write", "edit", "find", "grep", "ls"] as const) {
    const actual = actualByName.get(name);

    assert.ok(actual, `Expected ${name} override to be registered`);
    assert.notEqual(actual.parameters, builtInTools[name].parameters);
    assert.equal(typeof actual.renderResult, "function");
  }
});
