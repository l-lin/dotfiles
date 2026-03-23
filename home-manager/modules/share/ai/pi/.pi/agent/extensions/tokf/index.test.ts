import assert from "node:assert/strict";
import test from "node:test";
import tokfRewriteExtension, {
  createTokfBashTool,
  rewriteCommandForTokf,
} from "./index.js";
import type { BashOperations } from "@mariozechner/pi-coding-agent";

function given_mockPi() {
  const registeredTools: unknown[] = [];

  return {
    pi: {
      registerTool(tool: unknown) {
        registeredTools.push(tool);
      },
    },
    registeredTools,
  };
}

test("rewriteCommandForTokf GIVEN a bash command WHEN rewriting THEN tokf prefix is added", () => {
  const actual = rewriteCommandForTokf("ls");
  const expected = "tokf run -- ls";

  assert.equal(actual, expected);
});

test("createTokfBashTool GIVEN custom bash operations WHEN executing THEN tokf-prefixed command is delegated", async () => {
  let actualCommand: string | undefined;
  let actualCwd: string | undefined;
  let actualTimeout: number | undefined;

  const operations: BashOperations = {
    async exec(command, cwd, options) {
      actualCommand = command;
      actualCwd = cwd;
      actualTimeout = options.timeout;
      options.onData(Buffer.from("tokf output"));
      return { exitCode: 0 };
    },
  };

  const tool = createTokfBashTool(process.cwd(), { operations });
  const actual = await tool.execute(
    "tool-call-id",
    { command: "ls", timeout: 7 },
    undefined,
    undefined,
  );

  assert.equal(actualCommand, "tokf run -- ls");
  assert.equal(actualCwd, process.cwd());
  assert.equal(actualTimeout, 7);
  assert.deepEqual(actual.content, [{ type: "text", text: "tokf output" }]);
});

test("extension GIVEN pi WHEN loading THEN it registers a bash override", () => {
  const { pi, registeredTools } = given_mockPi();

  tokfRewriteExtension(pi as never);

  assert.equal(registeredTools.length, 1);
  const actual = registeredTools[0] as { name: string };
  const expected = "bash";

  assert.equal(actual.name, expected);
});
