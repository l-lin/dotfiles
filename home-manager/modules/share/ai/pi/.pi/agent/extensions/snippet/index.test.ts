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
    when_listingInputHandlers() {
      return [...inputHandlers];
    },
  };
}

test("snippet extension GIVEN initialization WHEN loading THEN it does not register an input handler", () => {
  const { pi, when_listingInputHandlers } = given_mockPi();

  snippetExtension(pi as never);

  const actual = when_listingInputHandlers();
  const expected: InputEventHandler[] = [];

  assert.deepEqual(actual, expected);
});
