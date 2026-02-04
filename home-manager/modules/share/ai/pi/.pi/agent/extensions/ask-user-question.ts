/**
 * Questionnaire Tool - Ask single or multiple questions with option selection
 *
 * src: https://github.com/badlogic/pi-mono/blob/81b8f9c083db63ed9b7ffb1f555fc6fee8653767/packages/coding-agent/examples/extensions/questionnaire.ts
 * Adapted with the following changes:
 * - rename extension to `AskUserQuestion` to match the same name as claude-code & opencode
 * - use keymaps from keybindings.json instead of hard coded keymaps (arrows, Esc, Enter)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  Editor,
  type EditorTheme,
  getEditorKeybindings,
  Key,
  matchesKey,
  Text,
  truncateToWidth,
} from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

interface Question {
  id: string;
  label: string;
  prompt: string;
  options: { value: string; label: string; description?: string }[];
}

interface Answer {
  id: string;
  value: string;
  label: string;
  wasCustom: boolean;
  index?: number;
}

interface Result {
  questions: Question[];
  answers: Answer[];
  cancelled: boolean;
}

const QuestionnaireParams = Type.Object({
  questions: Type.Array(
    Type.Object({
      id: Type.String({ description: "Unique identifier for this question" }),
      label: Type.Optional(Type.String({ description: "Short label for tab bar (defaults to Q1, Q2)" })),
      prompt: Type.String({ description: "The question text to display" }),
      options: Type.Array(
        Type.Object({
          value: Type.String({ description: "Value returned when selected" }),
          label: Type.String({ description: "Display label" }),
          description: Type.Optional(Type.String({ description: "Optional description" })),
        }),
        { description: "Available options" },
      ),

    }),
    { description: "Questions to ask" },
  ),
});

export default function questionnaire(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user_question",
    label: "AskUserQuestion",
    description: "Ask the user one or more questions. Single question shows options list; multiple questions show tab-based interface.",
    parameters: QuestionnaireParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!ctx.hasUI) return error("UI not available");
      if (!params.questions.length) return error("No questions provided");

      const questions: Question[] = params.questions.map((q, i) => ({
        ...q,
        label: q.label || `Q${i + 1}`,
      }));

      const isMulti = questions.length > 1;
      const kb = getEditorKeybindings();

      const result = await ctx.ui.custom<Result>((tui, theme, _appKb, done) => {
        let currentTab = 0;
        let selectedIndex = 0;
        let inputMode = false;
        let inputQuestionId: string | null = null;
        let cachedLines: string[] | undefined;
        const answers = new Map<string, Answer>();

        const editor = new Editor(tui, {
          borderColor: (s) => theme.fg("accent", s),
          selectList: {
            selectedPrefix: (t) => theme.fg("accent", t),
            selectedText: (t) => theme.fg("accent", t),
            description: (t) => theme.fg("muted", t),
            scrollInfo: (t) => theme.fg("dim", t),
            noMatch: (t) => theme.fg("warning", t),
          },
        } as EditorTheme);

        const refresh = () => { cachedLines = undefined; tui.requestRender(); };

        const currentQuestion = () => questions[currentTab];

        const currentOptions = () => {
          const question = currentQuestion();
          if (!question) return [];
          const options = [...question.options];
          options.push({ value: "__other__", label: "Type something." });
          return options;
        };

        const allAnswered = () => questions.every((question) => answers.has(question.id));

        const finish = (cancelled: boolean) => done({ questions, answers: Array.from(answers.values()), cancelled });

        const advanceToNext = () => {
          if (!isMulti) return finish(false);
          currentTab = currentTab < questions.length - 1 ? currentTab + 1 : questions.length;
          selectedIndex = 0;
          refresh();
        };

        editor.onSubmit = (value) => {
          if (!inputQuestionId) return;
          const trimmed = value.trim() || "(no response)";
          answers.set(inputQuestionId, { id: inputQuestionId, value: trimmed, label: trimmed, wasCustom: true });
          inputMode = false;
          inputQuestionId = null;
          editor.setText("");
          advanceToNext();
        };

        const handleInput = (data: string) => {
          if (inputMode) {
            if (kb.matches(data, "selectCancel")) {
              inputMode = false;
              inputQuestionId = null;
              editor.setText("");
              refresh();
            } else {
              editor.handleInput(data);
              refresh();
            }
            return;
          }

          const options = currentOptions();

          // Tab navigation
          if (isMulti) {
            if (matchesKey(data, Key.tab) || matchesKey(data, Key.right)) {
              currentTab = (currentTab + 1) % (questions.length + 1);
              selectedIndex = 0;
              refresh();
              return;
            }
            if (matchesKey(data, Key.shift("tab")) || matchesKey(data, Key.left)) {
              currentTab = (currentTab - 1 + questions.length + 1) % (questions.length + 1);
              selectedIndex = 0;
              refresh();
              return;
            }
          }

          // Submit tab
          if (currentTab === questions.length) {
            if (kb.matches(data, "selectConfirm") && allAnswered()) finish(false);
            else if (kb.matches(data, "selectCancel")) finish(true);
            return;
          }

          // Option navigation & selection
          if (kb.matches(data, "selectUp")) { selectedIndex = Math.max(0, selectedIndex - 1); refresh(); return; }
          if (kb.matches(data, "selectDown")) { selectedIndex = Math.min(options.length - 1, selectedIndex + 1); refresh(); return; }
          if (kb.matches(data, "selectConfirm") && currentQuestion()) {
            const option = options[selectedIndex];
            if (option.value === "__other__") {
              inputMode = true;
              inputQuestionId = currentQuestion()!.id;
              editor.setText("");
            } else {
              const question = currentQuestion()!;
              answers.set(question.id, { id: question.id, value: option.value, label: option.label, wasCustom: false, index: selectedIndex + 1 });
              advanceToNext();
            }
            refresh();
            return;
          }
          if (kb.matches(data, "selectCancel")) finish(true);
        };

        const render = (width: number): string[] => {
          if (cachedLines) return cachedLines;
          const lines: string[] = [];
          const addLine = (s: string) => lines.push(truncateToWidth(s, width));
          const question = currentQuestion();
          const options = currentOptions();

          addLine(theme.fg("accent", "─".repeat(width)));

          // Tab bar
          if (isMulti) {
            const parts = ["← "];
            questions.forEach((q, i) => {
              const answered = answers.has(q.id);
              const text = ` ${answered ? "■" : "□"} ${q.label} `;
              parts.push(i === currentTab ? theme.bg("selectedBg", theme.fg("text", text)) : theme.fg(answered ? "success" : "muted", text));
              parts.push(" ");
            });
            const submitText = " ✓ Submit ";
            parts.push(currentTab === questions.length
              ? theme.bg("selectedBg", theme.fg("text", submitText))
              : theme.fg(allAnswered() ? "success" : "dim", submitText));
            parts.push(" →");
            addLine(` ${parts.join("")}`);
            lines.push("");
          }

          const renderOptions = () => options.forEach((option, i) => {
            const isSelected = i === selectedIndex;
            const prefix = isSelected ? theme.fg("accent", "> ") : "  ";
            const label = `${i + 1}. ${option.label}${option.value === "__other__" && inputMode ? " ✎" : ""}`;
            addLine(prefix + theme.fg(isSelected ? "accent" : "text", label));
            if (option.description) addLine(`     ${theme.fg("muted", option.description)}`);
          });

          if (inputMode && question) {
            addLine(theme.fg("text", ` ${question.prompt}`));
            lines.push("");
            renderOptions();
            lines.push("");
            addLine(theme.fg("muted", " Your answer:"));
            editor.render(width - 2).forEach((line) => addLine(` ${line}`));
            lines.push("");
            addLine(theme.fg("dim", " Enter to submit • Esc to cancel"));
          } else if (currentTab === questions.length) {
            addLine(theme.fg("accent", theme.bold(" Ready to submit")));
            lines.push("");
            questions.forEach((q) => {
              const answer = answers.get(q.id);
              if (answer) addLine(`${theme.fg("muted", ` ${q.label}: `)}${theme.fg("text", (answer.wasCustom ? "(wrote) " : "") + answer.label)}`);
            });
            lines.push("");
            addLine(allAnswered() ? theme.fg("success", " Press Enter to submit") : theme.fg("warning", ` Unanswered: ${questions.filter((q) => !answers.has(q.id)).map((q) => q.label).join(", ")}`));
          } else if (question) {
            addLine(theme.fg("text", ` ${question.prompt}`));
            lines.push("");
            renderOptions();
          }

          lines.push("");
          if (!inputMode) addLine(theme.fg("dim", isMulti ? " Tab/←→ navigate • ↑↓ select • Enter confirm • Esc cancel" : " ↑↓ navigate • Enter select • Esc cancel"));
          addLine(theme.fg("accent", "─".repeat(width)));

          cachedLines = lines;
          return lines;
        };

        return { render, invalidate: () => { cachedLines = undefined; }, handleInput };
      });

      if (result.cancelled) return { content: [{ type: "text", text: "User cancelled" }], details: result };

      const text = result.answers.map((a) => {
        const label = questions.find((q) => q.id === a.id)?.label || a.id;
        return a.wasCustom ? `${label}: user wrote: ${a.label}` : `${label}: user selected: ${a.index}. ${a.label}`;
      }).join("\n");

      return { content: [{ type: "text", text }], details: result };
    },

    renderCall(args, theme) {
      const qs = (args.questions as Question[]) || [];
      let text = theme.fg("toolTitle", theme.bold("AskUserQuestion "));
      text += theme.fg("muted", `${qs.length} question${qs.length !== 1 ? "s" : ""}`);
      const labels = qs.map((q) => q.label || q.id).join(", ");
      if (labels) text += theme.fg("dim", ` (${truncateToWidth(labels, 40)})`);
      return new Text(text, 0, 0);
    },

    renderResult(result, _opts, theme) {
      const d = result.details as Result | undefined;
      if (!d) return new Text(result.content[0]?.type === "text" ? result.content[0].text : "", 0, 0);
      if (d.cancelled) return new Text(theme.fg("warning", "Cancelled"), 0, 0);
      return new Text(d.answers.map((a) => {
        const display = a.wasCustom ? `${theme.fg("muted", "(wrote) ")}${a.label}` : (a.index ? `${a.index}. ${a.label}` : a.label);
        return `${theme.fg("success", "✓ ")}${theme.fg("accent", a.id)}: ${display}`;
      }).join("\n"), 0, 0);
    },
  });
}

function error(msg: string) {
  return { content: [{ type: "text" as const, text: `Error: ${msg}` }], details: { questions: [], answers: [], cancelled: true } };
}
