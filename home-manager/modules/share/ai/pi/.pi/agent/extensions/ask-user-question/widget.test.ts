import assert from "node:assert/strict";
import test from "node:test";
import { initTheme } from "@earendil-works/pi-coding-agent";
import { stripTerminalSequences, visibleWidth } from "@earendil-works/pi-tui";
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
    terminal: { rows: 24 },
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

function given_highlightedWidget() {
  const questions: Question[] = [
    {
      id: "metadata",
      label: "Metadata",
      prompt: "Where should metadata live?",
      options: [
        {
          value: "revinfo",
          label:
            "Keep metadata in revinfo with a label that wraps on narrow terminals",
          description:
            "A revision join satisfies the requirement without duplicating metadata on every consent row. 模型",
        },
        { value: "columns", label: "Second choice" },
      ],
    },
  ];
  const completedResults: Result[] = [];
  const theme = {
    ...given_theme(),
    bg(color: string, text: string) {
      return color === "selectedBg"
        ? `\x1b[48;2;230;230;230m${text}\x1b[49m`
        : text;
    },
  };
  const widget = buildWidget(questions)(given_tui(), theme, null, (result) =>
    completedResults.push(result),
  );
  return { widget, completedResults };
}

test("buildWidget GIVEN a selected option with wrapped label and description WHEN rendering and resizing THEN every line of that option has a full-width background", () => {
  const { widget } = given_highlightedWidget();
  const background = "\x1b[48;2;230;230;230m";

  for (const width of [80, 26, 100]) {
    const lines = widget.render(width);
    const visibleLines = lines.map(stripTerminalSequences);
    const firstOptionIndex = visibleLines.findIndex((line) =>
      line.startsWith("> 1. "),
    );
    const nextOptionIndex = visibleLines.findIndex((line) =>
      line.startsWith("  2. "),
    );
    const highlightedLines = lines.filter((line) =>
      line.startsWith(background),
    );
    const actual = {
      highlightedIndices: lines.flatMap((line, index) =>
        line.startsWith(background) ? [index] : [],
      ),
      highlightedWidths: highlightedLines.map(visibleWidth),
      backgroundEnds: highlightedLines.every((line) =>
        line.endsWith("\x1b[49m"),
      ),
    };
    const expected = {
      highlightedIndices: Array.from(
        { length: nextOptionIndex - firstOptionIndex },
        (_, index) => firstOptionIndex + index,
      ),
      highlightedWidths: Array(nextOptionIndex - firstOptionIndex).fill(width),
      backgroundEnds: true,
    };

    assert.ok(firstOptionIndex >= 0);
    assert.ok(nextOptionIndex > firstOptionIndex);
    assert.deepEqual(actual, expected);
    const selectedText = highlightedLines
      .map(stripTerminalSequences)
      .map((line) => line.trim())
      .join(" ");
    assert.match(selectedText, /Keep metadata in revinfo/);
    assert.match(selectedText, /every consent row\. 模\s*型/);
  }
});

test("buildWidget GIVEN highlighted options WHEN navigating through choices and confirming THEN the background follows selection without changing the answer", () => {
  const { widget, completedResults } = given_highlightedWidget();
  const background = "\x1b[48;2;230;230;230m";

  for (const selectedLabel of ["2. Second choice", "3. Type something."]) {
    widget.handleInput("j");
    const highlightedLines = widget
      .render(60)
      .filter((line) => line.startsWith(background));
    const actual = highlightedLines.map(stripTerminalSequences);
    const expected = [`> ${selectedLabel}`.padEnd(60)];

    assert.deepEqual(actual, expected);
  }

  widget.handleInput("k");
  widget.handleInput("\r");
  const actual = completedResults.map((result) => result.answers);
  const expected = [
    [
      {
        id: "metadata",
        value: "columns",
        label: "Second choice",
        wasCustom: false,
        index: 2,
      },
    ],
  ];

  assert.deepEqual(actual, expected);
});

test("buildWidget GIVEN Markdown in a question prompt WHEN rendering the questionnaire THEN it displays formatted text instead of Markdown syntax", () => {
  initTheme("dark", false);
  const actual = when_renderingQuestionnaire(
    [
      {
        id: "deployment",
        label: "Deployment",
        prompt: "# Choose a target\n\nDeploy to **production** or `staging`.",
        options: [{ value: "production", label: "Production" }],
      },
    ],
    80,
  ).join("\n");
  const visible = stripTerminalSequences(actual);

  assert.match(visible, /Choose a target/);
  assert.match(visible, /Deploy to production or staging\./);
  assert.doesNotMatch(visible, /# Choose|\*\*production\*\*|`staging`/);
});

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
