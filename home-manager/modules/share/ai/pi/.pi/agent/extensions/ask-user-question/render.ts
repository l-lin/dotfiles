/** Rendering for ask-user-question tool calls and results. */

import type {
  AgentToolResult,
  Theme,
  ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import type { Answer, Question, Result } from "./types.js";

function getQuestionForAnswer(
  questions: Question[],
  answer: Answer,
): Question | undefined {
  return questions.find((question) => question.id === answer.id);
}

function getQuestionText(
  question: Question | undefined,
  answer: Answer,
): string {
  return (
    question?.prompt || question?.label || answer.id || "(missing question)"
  );
}

function getAnswerText(answer: Answer): string {
  const answerLabel =
    answer.label || answer.value || answer.id || "(missing answer)";
  return answer.wasCustom ? `(wrote) ${answerLabel}` : answerLabel;
}

function renderCollapsedResult(result: Result, theme: Theme): string {
  return result.answers
    .map((answer) => {
      const question = getQuestionForAnswer(result.questions, answer);
      const prompt = getQuestionText(question, answer);
      const selectedAnswer = getAnswerText(answer);
      const prefix = theme.fg("accent", `✓ ${prompt}:`);
      const value = theme.fg("text", ` ${selectedAnswer}`);
      return `${prefix}${value}`;
    })
    .join("\n");
}

function renderExpandedResult(result: Result, theme: Theme): string {
  return result.answers
    .map((answer, index) => {
      const question = getQuestionForAnswer(result.questions, answer);
      const prompt = getQuestionText(question, answer);
      const selectedAnswer = getAnswerText(answer);
      const options = question?.options ?? [];

      const lines = [
        theme.fg("success", `✓ Question ${index + 1}`),
        `${theme.fg("dim", "  Prompt: ")}${theme.fg("text", prompt)}`,
      ];

      if (options.length > 0) {
        lines.push(theme.fg("dim", "  Options:"));
        options.forEach((option) => {
          const isSelected = !answer.wasCustom && option.value === answer.value;
          const marker = isSelected
            ? theme.fg("success", "    ✓ ")
            : theme.fg("muted", "      ");
          const optionLabel = theme.fg(
            isSelected ? "accent" : "text",
            option.label || option.value || "(missing answer)",
          );
          lines.push(`${marker}${optionLabel}`);
          if (option.description) {
            lines.push(
              `${theme.fg("muted", "      ")}${theme.fg("muted", option.description)}`,
            );
          }
        });
      }

      return lines.join("\n");
    })
    .join("\n\n");
}

export function renderCall(args: any, theme: Theme): Text {
  const questions = (args.questions as Question[]) || [];
  const text =
    theme.fg("toolTitle", theme.bold("ask-user-question ")) +
    theme.fg(
      "muted",
      `${questions.length} question${questions.length !== 1 ? "s" : ""}`,
    );

  return new Text(text, 0, 0);
}

export function renderResult(
  result: AgentToolResult<Result>,
  opts: ToolRenderResultOptions,
  theme: Theme,
): Text {
  const details = result.details as Result | undefined;
  if (!details) {
    const text =
      result.content[0]?.type === "text" ? result.content[0].text : "";
    return new Text(text, 0, 0);
  }

  if (details.cancelled) {
    return new Text(theme.fg("warning", "Cancelled"), 0, 0);
  }

  const text = opts.expanded
    ? renderExpandedResult(details, theme)
    : renderCollapsedResult(details, theme);

  return new Text(text, 0, 0);
}
