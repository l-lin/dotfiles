import assert from "node:assert/strict";
import test from "node:test";
import { renderCall, renderResult } from "./render.js";
import type { Result } from "./types.js";

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

function given_result(): Result {
  return {
    questions: [
      {
        id: "popularity-fallback",
        label: "q5",
        prompt: "How should the fallback ranker behave when entropy is low?",
        options: [
          {
            value: "popular-entropy",
            label: "4. Popularity × entropy fallback",
            description:
              "Prefer globally popular results, but still reward useful uncertainty.",
          },
          {
            value: "entropy-only",
            label: "Entropy only",
            description: "Ignore popularity and rank only by uncertainty.",
          },
        ],
      },
    ],
    answers: [
      {
        id: "popularity-fallback",
        value: "popular-entropy",
        label: "4. Popularity × entropy fallback",
        wasCustom: false,
        index: 4,
      },
    ],
    cancelled: false,
  };
}

function when_renderingCall(width: number): string {
  return renderCall(
    { questions: given_result().questions },
    given_theme() as never,
  )
    .render(width)
    .join("\n");
}

function when_renderingResult(
  result: Result,
  expanded: boolean,
  width: number,
  theme = given_theme(),
): string {
  return renderResult(
    {
      content: [{ type: "text", text: "fallback" }],
      details: result,
    } as never,
    { expanded, isPartial: false },
    theme as never,
  )
    .render(width)
    .map((line) => line.trimEnd())
    .join("\n");
}

test("renderCall GIVEN ask-user-question inputs WHEN rendering the tool call THEN it keeps the header compact without q-label clutter", () => {
  const actual = when_renderingCall(80);
  const expected = "ask-user-question 1 question";

  assert.match(actual, /ask-user-question 1 question/);
  assert.doesNotMatch(actual, /q5/);
  assert.match(actual, new RegExp(expected));
});

test("renderResult GIVEN a completed question WHEN rendering the collapsed result THEN it separates the full prompt from the selected answer", () => {
  const actual = when_renderingResult(given_result(), false, 120);
  const expected =
    "✓ How should the fallback ranker behave when entropy is low?\n" +
    "  Answer: 4. Popularity × entropy fallback";

  assert.equal(actual, expected);
});

test("renderResult GIVEN a theme with bold styling WHEN rendering the collapsed result THEN only the question is bold", () => {
  const theme = {
    ...given_theme(),
    bold(text: string) {
      return `\x1b[1m${text}\x1b[22m`;
    },
  };
  const actual = when_renderingResult(given_result(), false, 120, theme);
  const expected =
    "\x1b[1m✓ How should the fallback ranker behave when entropy is low?\x1b[22m\n" +
    "  Answer: 4. Popularity × entropy fallback";

  assert.equal(actual, expected);
});

test("renderResult GIVEN multiple answers including custom input WHEN rendering the collapsed result THEN it separates each question-answer pair and preserves custom text", () => {
  const result = given_result();
  result.questions.push({
    id: "metadata",
    label: "Metadata",
    prompt: "Where should metadata live?",
    options: [],
  });
  result.answers.push({
    id: "metadata",
    value: "Use revinfo.",
    label: "Use revinfo.",
    wasCustom: true,
  });
  const actual = when_renderingResult(result, false, 120);
  const expected =
    "✓ How should the fallback ranker behave when entropy is low?\n" +
    "  Answer: 4. Popularity × entropy fallback\n\n" +
    "✓ Where should metadata live?\n" +
    "  Answer: (wrote) Use revinfo.";

  assert.equal(actual, expected);
});

test("renderResult GIVEN a narrow terminal WHEN the question wraps THEN the answer still starts on its own labeled line", () => {
  const lines = when_renderingResult(given_result(), false, 50).split("\n");
  const answerIndex = lines.findIndex((line) => line.startsWith("  Answer: "));
  const actual = {
    question: lines
      .slice(0, answerIndex)
      .map((line) => line.trim())
      .join(" "),
    answer: lines.slice(answerIndex).join("\n"),
    questionWrapped: answerIndex > 1,
  };
  const expected = {
    question: "✓ How should the fallback ranker behave when entropy is low?",
    answer: "  Answer: 4. Popularity × entropy fallback",
    questionWrapped: true,
  };

  assert.deepEqual(actual, expected);
});

test("renderResult GIVEN expanded mode WHEN rendering the result THEN it shows question blocks with all options and the selected marker", () => {
  const actual = when_renderingResult(given_result(), true, 120);

  assert.match(actual, /✓ Question 1/);
  assert.match(
    actual,
    /Prompt: How should the fallback ranker behave when entropy is low\?/,
  );
  assert.doesNotMatch(actual, /Selected:/);
  assert.match(
    actual,
    /✓ 4\. Popularity × entropy fallback[\s\S]*Prefer globally popular results, but still reward useful uncertainty\./,
  );
  assert.match(
    actual,
    /Entropy only[\s\S]*Ignore popularity and rank only by uncertainty\./,
  );
});
