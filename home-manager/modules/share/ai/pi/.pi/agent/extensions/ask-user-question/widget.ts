/** Interactive TUI widget factory for the ask-user-question tool. */

import {
  Editor,
  type EditorTheme,
  getKeybindings,
  Key,
  matchesKey,
  truncateToWidth,
  wrapTextWithAnsi,
} from "@mariozechner/pi-tui";
import type { Answer, Question, Result } from "./types.js";

/**
 * Returns the `ctx.ui.custom<Result>()` callback for the questionnaire widget.
 * Handles state, input routing, and rendering for single and multi-question flows.
 */
export function buildWidget(questions: Question[]) {
  const isMulti = questions.length > 1;
  const kb = getKeybindings();

  return (
    tui: any,
    theme: any,
    _appKb: any,
    done: (result: Result) => void,
  ) => {
    let currentTab = 0;
    let selectedIndex = 0;
    let inputMode = false;
    let inputQuestionId: string | null = null;
    let cachedLines: string[] | undefined;
    const answers = new Map<string, Answer>();

    const editor = new Editor(tui, {
      borderColor: (s: string) => theme.fg("accent", s),
      selectList: {
        selectedPrefix: (t: string) => theme.fg("accent", t),
        selectedText: (t: string) => theme.fg("accent", t),
        description: (t: string) => theme.fg("muted", t),
        scrollInfo: (t: string) => theme.fg("dim", t),
        noMatch: (t: string) => theme.fg("warning", t),
      },
    } as EditorTheme);

    // ── helpers ────────────────────────────────────────────────────────────

    const refresh = () => {
      cachedLines = undefined;
      tui.requestRender();
    };

    const currentQuestion = () => questions[currentTab];

    const currentOptions = () => {
      const question = currentQuestion();
      if (!question) return [];
      return [
        ...question.options,
        { value: "__other__", label: "Type something." },
      ];
    };

    const allAnswered = () => questions.every((q) => answers.has(q.id));

    const finish = (cancelled: boolean) =>
      done({ questions, answers: Array.from(answers.values()), cancelled });

    const advanceToNext = () => {
      if (!isMulti) return finish(false);
      currentTab =
        currentTab < questions.length - 1 ? currentTab + 1 : questions.length;
      selectedIndex = 0;
      refresh();
    };

    // ── editor submit ──────────────────────────────────────────────────────

    editor.onSubmit = (value: string) => {
      if (!inputQuestionId) return;
      const trimmed = value.trim() || "(no response)";
      answers.set(inputQuestionId, {
        id: inputQuestionId,
        value: trimmed,
        label: trimmed,
        wasCustom: true,
      });
      inputMode = false;
      inputQuestionId = null;
      editor.setText("");
      advanceToNext();
    };

    // ── input handling ─────────────────────────────────────────────────────

    const handleInput = (data: string) => {
      if (inputMode) {
        if (
          kb.matches(data, "tui.select.cancel") ||
          matchesKey(data, "ctrl+[")
        ) {
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

      if (isMulti) {
        if (
          matchesKey(data, Key.tab) ||
          matchesKey(data, Key.right) ||
          data === "l"
        ) {
          currentTab = (currentTab + 1) % (questions.length + 1);
          selectedIndex = 0;
          refresh();
          return;
        }
        if (
          matchesKey(data, Key.shift("tab")) ||
          matchesKey(data, Key.left) ||
          data === "h"
        ) {
          currentTab =
            (currentTab - 1 + questions.length + 1) % (questions.length + 1);
          selectedIndex = 0;
          refresh();
          return;
        }
      }

      // Submit tab
      if (currentTab === questions.length) {
        if (kb.matches(data, "tui.select.confirm") && allAnswered())
          finish(false);
        else if (
          kb.matches(data, "tui.select.cancel") ||
          matchesKey(data, "ctrl+[")
        )
          finish(true);
        return;
      }

      // Option navigation
      if (kb.matches(data, "tui.select.up") || data === "k") {
        selectedIndex = Math.max(0, selectedIndex - 1);
        refresh();
        return;
      }
      if (kb.matches(data, "tui.select.down") || data === "j") {
        selectedIndex = Math.min(options.length - 1, selectedIndex + 1);
        refresh();
        return;
      }

      // Option selection
      if (kb.matches(data, "tui.select.confirm") && currentQuestion()) {
        const option = options[selectedIndex];
        if (option.value === "__other__") {
          inputMode = true;
          inputQuestionId = currentQuestion()!.id;
          editor.setText("");
        } else {
          const question = currentQuestion()!;
          answers.set(question.id, {
            id: question.id,
            value: option.value,
            label: option.label,
            wasCustom: false,
            index: selectedIndex + 1,
          });
          advanceToNext();
        }
        refresh();
        return;
      }

      if (kb.matches(data, "tui.select.cancel") || matchesKey(data, "ctrl+["))
        finish(true);
    };

    // ── rendering ──────────────────────────────────────────────────────────

    const renderOptions = (
      options: ReturnType<typeof currentOptions>,
      addLine: (s: string) => void,
    ) => {
      options.forEach((option, i) => {
        const isSelected = i === selectedIndex;
        const prefix = isSelected ? theme.fg("accent", "> ") : "  ";
        const label = `${i + 1}. ${option.label}${option.value === "__other__" && inputMode ? " ✎" : ""}`;
        addLine(prefix + theme.fg(isSelected ? "accent" : "text", label));
        if (option.description)
          addLine(`     ${theme.fg("muted", option.description)}`);
      });
    };

    const renderTabBar = (addLine: (s: string) => void) => {
      const parts = ["← "];
      questions.forEach((q, i) => {
        const answered = answers.has(q.id);
        const text = ` ${answered ? "■" : "□"} ${q.label} `;
        parts.push(
          i === currentTab
            ? theme.bg("selectedBg", theme.fg("text", text))
            : theme.fg(answered ? "success" : "muted", text),
        );
        parts.push(" ");
      });
      const submitText = " ✓ Submit ";
      parts.push(
        currentTab === questions.length
          ? theme.bg("selectedBg", theme.fg("text", submitText))
          : theme.fg(allAnswered() ? "success" : "dim", submitText),
      );
      parts.push(" →");
      addLine(` ${parts.join("")}`);
    };

    const render = (width: number): string[] => {
      if (cachedLines) return cachedLines;

      const lines: string[] = [];
      const addLine = (s: string) => lines.push(truncateToWidth(s, width));
      const question = currentQuestion();
      const options = currentOptions();

      addLine(theme.fg("accent", "─".repeat(width)));

      if (isMulti) {
        renderTabBar(addLine);
        lines.push("");
      }

      if (inputMode && question) {
        wrapTextWithAnsi(question.prompt, width - 2).forEach((line) =>
          addLine(theme.fg("text", ` ${line}`)),
        );
        lines.push("");
        renderOptions(options, addLine);
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
          if (answer) {
            addLine(
              `${theme.fg("muted", ` ${q.label}: `)}${theme.fg("text", (answer.wasCustom ? "(wrote) " : "") + answer.label)}`,
            );
          }
        });
        lines.push("");
        addLine(
          allAnswered()
            ? theme.fg("success", " Press Enter to submit")
            : theme.fg(
                "warning",
                ` Unanswered: ${questions
                  .filter((q) => !answers.has(q.id))
                  .map((q) => q.label)
                  .join(", ")}`,
              ),
        );
      } else if (question) {
        wrapTextWithAnsi(question.prompt, width - 2).forEach((line) =>
          addLine(theme.fg("text", ` ${line}`)),
        );
        lines.push("");
        renderOptions(options, addLine);
      }

      lines.push("");
      if (!inputMode) {
        addLine(
          theme.fg(
            "dim",
            isMulti
              ? " Tab/←→/h/l navigate • ↑↓/j/k select • Enter confirm • Esc cancel"
              : " ↑↓/j/k navigate • Enter select • Esc cancel",
          ),
        );
      }
      addLine(theme.fg("accent", "─".repeat(width)));

      cachedLines = lines;
      return lines;
    };

    return {
      render,
      invalidate: () => {
        cachedLines = undefined;
      },
      handleInput,
    };
  };
}
