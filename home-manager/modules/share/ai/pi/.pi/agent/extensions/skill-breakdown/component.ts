import {
  matchesKey,
  truncateToWidth,
  visibleWidth,
  type Component,
  type TUI,
} from "@mariozechner/pi-tui";
import { getOrderedModelsForSkill } from "./aggregation.js";
import { RANGE_DAYS } from "./constants.js";
import { renderBreakdownBody } from "./renderer.js";
import { findSkillMatches } from "./search.js";
import type {
  ModelKey,
  SkillBreakdownData,
  SkillBreakdownView,
  SkillName,
} from "./types.js";

type SearchKeybindings = {
  matches(data: string, binding: string): boolean;
};

const SEARCH_SEGMENTER = new Intl.Segmenter(undefined, {
  granularity: "grapheme",
});
const VIEW_ORDER: SkillBreakdownView[] = ["skills", "least-used", "projects"];

function matchesBinding(
  keybindings: SearchKeybindings | undefined,
  data: string,
  binding: string,
): boolean {
  return !!keybindings?.matches(data, binding);
}

function isWhitespaceCharacter(value: string): boolean {
  return value.trim().length === 0;
}

function isPunctuationCharacter(value: string): boolean {
  return /[\p{P}\p{S}]/u.test(value);
}

function splitSearchQuery(value: string): Intl.SegmentData[] {
  return [...SEARCH_SEGMENTER.segment(value)];
}

function deleteCharBackwardFromEnd(value: string): string {
  const segments = splitSearchQuery(value);
  const lastSegment = segments[segments.length - 1];
  if (!lastSegment) return value;
  return value.slice(0, lastSegment.index);
}

function deleteWordBackwardFromEnd(value: string): string {
  const segments = splitSearchQuery(value);
  let index = segments.length;

  while (
    index > 0 &&
    isWhitespaceCharacter(segments[index - 1]?.segment ?? "")
  ) {
    index -= 1;
  }

  if (index > 0) {
    const lastCharacter = segments[index - 1]?.segment ?? "";
    const deletePunctuation = isPunctuationCharacter(lastCharacter);

    while (index > 0) {
      const currentCharacter = segments[index - 1]?.segment ?? "";
      const shouldDelete = deletePunctuation
        ? isPunctuationCharacter(currentCharacter)
        : !isWhitespaceCharacter(currentCharacter) &&
          !isPunctuationCharacter(currentCharacter);
      if (!shouldDelete) break;
      index -= 1;
    }
  }

  const deleteStart = segments[index]?.index ?? 0;
  return value.slice(0, deleteStart);
}

function isConfirmInput(
  data: string,
  keybindings?: SearchKeybindings,
): boolean {
  return !!(
    matchesBinding(keybindings, data, "tui.select.confirm") ||
    matchesKey(data, "return") ||
    matchesKey(data, "enter")
  );
}

function isCancelInput(data: string, keybindings?: SearchKeybindings): boolean {
  return !!(
    matchesBinding(keybindings, data, "tui.select.cancel") ||
    matchesKey(data, "escape") ||
    matchesKey(data, "ctrl+c")
  );
}

function isUpInput(data: string, keybindings?: SearchKeybindings): boolean {
  return !!(
    matchesBinding(keybindings, data, "tui.select.up") || matchesKey(data, "up")
  );
}

function isDownInput(data: string, keybindings?: SearchKeybindings): boolean {
  return !!(
    matchesBinding(keybindings, data, "tui.select.down") ||
    matchesKey(data, "down")
  );
}

function isDeleteCharBackwardInput(
  data: string,
  keybindings?: SearchKeybindings,
): boolean {
  return !!(
    matchesBinding(keybindings, data, "tui.editor.deleteCharBackward") ||
    matchesKey(data, "backspace") ||
    data === "\b" ||
    data === "\u007f"
  );
}

function isDeleteCharForwardInput(
  data: string,
  keybindings?: SearchKeybindings,
): boolean {
  return matchesBinding(keybindings, data, "tui.editor.deleteCharForward");
}

function isDeleteWordBackwardInput(
  data: string,
  keybindings?: SearchKeybindings,
): boolean {
  return matchesBinding(keybindings, data, "tui.editor.deleteWordBackward");
}

function isDeleteWordForwardInput(
  data: string,
  keybindings?: SearchKeybindings,
): boolean {
  return matchesBinding(keybindings, data, "tui.editor.deleteWordForward");
}

function isDeleteToLineStartInput(
  data: string,
  keybindings?: SearchKeybindings,
): boolean {
  return matchesBinding(keybindings, data, "tui.editor.deleteToLineStart");
}

function isDeleteToLineEndInput(
  data: string,
  keybindings?: SearchKeybindings,
): boolean {
  return matchesBinding(keybindings, data, "tui.editor.deleteToLineEnd");
}

function isPrintableInput(data: string): boolean {
  return data.length === 1 && data >= " " && data !== "\u007f";
}

export class SkillBreakdownComponent implements Component {
  private data: SkillBreakdownData;
  private tui: TUI;
  private theme: any;
  private keybindings?: SearchKeybindings;
  private onDone: () => void;
  private rangeIndex = 1;
  private view: SkillBreakdownView = "skills";
  private selectedSkill: SkillName | null = null;
  private selectedModel: ModelKey | null = null;
  private isSearchMode = false;
  private searchQuery = "";
  private selectedSearchIndex = 0;
  private isLight = false;

  constructor(
    data: SkillBreakdownData,
    tui: TUI,
    onDone: () => void,
    theme?: any,
    keybindings?: SearchKeybindings,
  ) {
    this.data = data;
    this.tui = tui;
    this.onDone = onDone;
    this.theme = theme;
    this.keybindings = keybindings;

    try {
      this.isLight = !!(
        theme &&
        typeof theme.name === "string" &&
        theme.name.toLowerCase().includes("light")
      );
    } catch {
      this.isLight = false;
    }
  }

  private box(contentLines: string[], width: number, title: string): string[] {
    const innerWidth = Math.max(1, width - 2);
    const titleText = truncateToWidth(` ${title} `, innerWidth);
    const titleWidth = visibleWidth(titleText);
    const leftRule = "─".repeat(Math.floor((innerWidth - titleWidth) / 2));
    const rightRule = "─".repeat(
      Math.max(0, innerWidth - titleWidth - leftRule.length),
    );
    const lines: string[] = [];

    if (this.theme) {
      lines.push(
        this.theme.fg("border", `╭${leftRule}`) +
          this.theme.fg("accent", titleText) +
          this.theme.fg("border", `${rightRule}╮`),
      );
    } else {
      lines.push(`╭${leftRule}${titleText}${rightRule}╮`);
    }

    for (const line of contentLines) {
      const paddedLine = truncateToWidth(" " + line, innerWidth, "...", true);
      if (this.theme) {
        lines.push(
          this.theme.fg("border", "│") +
            paddedLine +
            this.theme.fg("border", "│"),
        );
      } else {
        lines.push(`│${paddedLine}│`);
      }
    }

    if (this.theme) {
      lines.push(this.theme.fg("border", `╰${"─".repeat(innerWidth)}╯`));
    } else {
      lines.push(`╰${"─".repeat(innerWidth)}╯`);
    }

    return lines;
  }

  private selectedRange() {
    const selectedDays = RANGE_DAYS[this.rangeIndex] ?? 30;
    return this.data.ranges.get(selectedDays)!;
  }

  private currentSearchMatches() {
    return findSkillMatches(this.selectedRange(), this.searchQuery);
  }

  private normalizedSelectedSearchIndex(): number {
    const matches = this.currentSearchMatches();
    if (matches.length === 0) return 0;
    return Math.max(0, Math.min(this.selectedSearchIndex, matches.length - 1));
  }

  private buildContent(width: number): string[] {
    const innerWidth = Math.max(1, width - 2);
    const selectedDays = RANGE_DAYS[this.rangeIndex] ?? 30;
    const range = this.selectedRange();

    const lines = renderBreakdownBody(
      range,
      selectedDays,
      this.data,
      this.isLight,
      innerWidth,
      this.rangeIndex,
      this.view,
      this.selectedSkill,
      this.selectedModel,
      this.isSearchMode,
      this.searchQuery,
      this.normalizedSelectedSearchIndex(),
    );

    return lines.map((line) =>
      visibleWidth(line) > innerWidth ? line.slice(0, innerWidth) : line,
    );
  }

  private requestRender(): void {
    this.tui.requestRender();
  }

  private openSearch(): void {
    this.isSearchMode = true;
    this.searchQuery = "";
    this.selectedSearchIndex = 0;
    this.requestRender();
  }

  private closeSearch(): void {
    this.isSearchMode = false;
    this.searchQuery = "";
    this.selectedSearchIndex = 0;
    this.requestRender();
  }

  private moveSearchSelection(direction: 1 | -1): void {
    const matches = this.currentSearchMatches();
    if (matches.length === 0) return;

    const nextIndex = this.normalizedSelectedSearchIndex() + direction;
    this.selectedSearchIndex = Math.max(
      0,
      Math.min(nextIndex, matches.length - 1),
    );
    this.requestRender();
  }

  private confirmSearch(): void {
    const matches = this.currentSearchMatches();
    const selectedMatch = matches[this.normalizedSelectedSearchIndex()];
    if (!selectedMatch) return;

    this.selectedSkill = selectedMatch.skillName;
    this.selectedModel = null;
    this.view = "projects";
    this.isSearchMode = false;
    this.searchQuery = "";
    this.selectedSearchIndex = 0;
    this.requestRender();
  }

  private cycleModelScope(direction: 1 | -1): void {
    if (this.view !== "projects" || !this.selectedSkill) return;

    const modelOrder: Array<ModelKey | null> = [
      null,
      ...getOrderedModelsForSkill(this.selectedRange(), this.selectedSkill),
    ];
    const currentIndex = modelOrder.findIndex(
      (modelKey) => modelKey === this.selectedModel,
    );
    const nextIndex =
      currentIndex === -1
        ? 0
        : (currentIndex + modelOrder.length + direction) % modelOrder.length;

    this.selectedModel = modelOrder[nextIndex] ?? null;
    this.requestRender();
  }

  private cycleView(direction: 1 | -1): void {
    const currentIndex = VIEW_ORDER.indexOf(this.view);
    const normalizedCurrentIndex = currentIndex === -1 ? 0 : currentIndex;
    const nextIndex =
      (normalizedCurrentIndex + VIEW_ORDER.length + direction) %
      VIEW_ORDER.length;

    this.view = VIEW_ORDER[nextIndex] ?? "skills";
    this.requestRender();
  }

  invalidate(): void {
    // No cached state to clear.
  }

  handleInput(data: string): void {
    if (this.isSearchMode) {
      if (isCancelInput(data, this.keybindings)) {
        this.closeSearch();
        return;
      }
      if (isConfirmInput(data, this.keybindings)) {
        this.confirmSearch();
        return;
      }
      if (isUpInput(data, this.keybindings)) {
        this.moveSearchSelection(-1);
        return;
      }
      if (isDownInput(data, this.keybindings)) {
        this.moveSearchSelection(1);
        return;
      }
      if (isDeleteCharBackwardInput(data, this.keybindings)) {
        this.searchQuery = deleteCharBackwardFromEnd(this.searchQuery);
        this.selectedSearchIndex = 0;
        this.requestRender();
        return;
      }
      if (isDeleteCharForwardInput(data, this.keybindings)) {
        return;
      }
      if (isDeleteWordBackwardInput(data, this.keybindings)) {
        this.searchQuery = deleteWordBackwardFromEnd(this.searchQuery);
        this.selectedSearchIndex = 0;
        this.requestRender();
        return;
      }
      if (isDeleteWordForwardInput(data, this.keybindings)) {
        return;
      }
      if (isDeleteToLineStartInput(data, this.keybindings)) {
        this.searchQuery = "";
        this.selectedSearchIndex = 0;
        this.requestRender();
        return;
      }
      if (isDeleteToLineEndInput(data, this.keybindings)) {
        return;
      }
      if (isPrintableInput(data)) {
        this.searchQuery += data;
        this.selectedSearchIndex = 0;
        this.requestRender();
      }
      return;
    }

    if (data === "/") {
      this.openSearch();
      return;
    }

    if (isCancelInput(data, this.keybindings) || data.toLowerCase() === "q") {
      this.onDone();
      return;
    }

    if (isUpInput(data, this.keybindings) || data.toLowerCase() === "k") {
      this.cycleView(-1);
      return;
    }
    if (isDownInput(data, this.keybindings) || data.toLowerCase() === "j") {
      this.cycleView(1);
      return;
    }

    if (matchesKey(data, "tab") || matchesKey(data, "shift+tab")) {
      const direction: 1 | -1 = matchesKey(data, "shift+tab") ? -1 : 1;
      this.cycleModelScope(direction);
      return;
    }

    const previousRange = () => {
      this.rangeIndex =
        (this.rangeIndex + RANGE_DAYS.length - 1) % RANGE_DAYS.length;
      this.requestRender();
    };
    const nextRange = () => {
      this.rangeIndex = (this.rangeIndex + 1) % RANGE_DAYS.length;
      this.requestRender();
    };

    if (matchesKey(data, "left") || data.toLowerCase() === "h") {
      previousRange();
      return;
    }
    if (matchesKey(data, "right") || data.toLowerCase() === "l") {
      nextRange();
      return;
    }

    const selectedRangeIndex = ["1", "2", "3"].indexOf(data);
    if (selectedRangeIndex !== -1) {
      this.rangeIndex = selectedRangeIndex;
      this.requestRender();
    }
  }

  render(width: number): string[] {
    const content = this.buildContent(width);
    const title =
      "Skill breakdown · ←→/hl:range · ↑↓/jk:view · /:search · tab:model · q:close";
    return this.box(content, width, title);
  }
}
