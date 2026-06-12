import assert from "node:assert/strict";
import test from "node:test";
import { buildWidget } from "./widget.js";
import type { Question, Result } from "./types.js";

function given_theme() {
  return {
    fg(_color: string, text: string) {
      return text;
    },
    bg(_color: string, text: string) {
      return text;
    },
    bold(text: string) {
      return text;
    },
  };
}

function given_tui() {
  return {
    requestRender() {},
  };
}

function when_renderingQuestionnaire(
  questions: Question[],
  width: number,
): string[] {
  const widgetFactory = buildWidget(questions);
  const widget = widgetFactory(
    given_tui() as never,
    given_theme() as never,
    null,
    (_result: Result) => {},
  );

  return widget.render(width);
}

test("buildWidget GIVEN a long option description WHEN rendering the questionnaire THEN it wraps the description instead of truncating it", () => {
  const actual = when_renderingQuestionnaire(
    [
      {
        id: "architecture",
        label: "Architecture",
        prompt: "Pick the next step.",
        options: [
          {
            value: "spi-port",
            label: "Invert with an SPI port (recommended)",
            description:
              "end-user-context defines EndUserAccountInitializer (framework types only); content/adapter implements it via InitAccountUseCase. Gate beans stay in bootstrap so later details still remain visible.",
          },
        ],
      },
    ],
    90,
  ).join("\n");

  assert.match(actual, /Gate beans stay in bootstrap/i);
  assert.doesNotMatch(actual, /\.\.\./);
});

test("buildWidget GIVEN a long option label WHEN rendering the questionnaire THEN it wraps the label instead of truncating it", () => {
  const actual = when_renderingQuestionnaire(
    [
      {
        id: "direction",
        label: "Direction",
        prompt: "Choose one.",
        options: [
          {
            value: "relocate",
            label:
              "Relocate gate to bootstrap/web-server because the current label is intentionally long enough to require wrapping",
          },
        ],
      },
    ],
    60,
  ).join("\n");

  assert.match(
    actual,
    /current label is intentionally long enough to require/i,
  );
  assert.match(actual, /wrapping/i);
  assert.doesNotMatch(actual, /\.\.\./);
});
