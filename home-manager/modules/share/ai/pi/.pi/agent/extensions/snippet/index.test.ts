import assert from "node:assert/strict";
import test from "node:test";
import snippetExtension from "./index.js";

type InputEventHandler = (event: {
  source: string;
  text: string;
}) => Promise<unknown> | unknown;

function given_mockPi() {
  const inputHandlers: InputEventHandler[] = [];

  return {
    pi: {
      on(event: string, handler: InputEventHandler) {
        if (event === "input") {
          inputHandlers.push(handler);
        }
      },
    },
    async when_processingInput(text: string, source = "user") {
      const handler = inputHandlers[0];
      assert.ok(
        handler,
        "Expected the snippet extension to register an input handler",
      );

      return await handler({ source, text });
    },
  };
}

test("snippet extension GIVEN a dollar snippet trigger WHEN processing input THEN it leaves the text alone", async () => {
  const { pi, when_processingInput } = given_mockPi();

  snippetExtension(pi as never);

  const actual = await when_processingInput("$understanding-next-steps");
  const expected = { action: "continue" };

  assert.deepEqual(actual, expected);
});

test("snippet extension GIVEN a question-mark snippet trigger WHEN processing input THEN it leaves the text alone", async () => {
  const { pi, when_processingInput } = given_mockPi();

  snippetExtension(pi as never);

  const actual = await when_processingInput("?q");
  const expected = { action: "continue" };

  assert.deepEqual(actual, expected);
});
