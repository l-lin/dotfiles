// ============================================================================
// GitHub Copilot Extension — Models Overlay Component
//
// Renders a bordered overlay with:
//  - Box border matching session-breakdown style (╭╮╰╯│─)
//  - Visible search input field with fuzzy filtering
//  - Model list with active indicator and multiplier info
// ============================================================================

import {
  Input,
  SelectList,
  type SelectItem,
  fuzzyFilter,
  getEditorKeybindings,
  matchesKey,
  truncateToWidth,
  visibleWidth,
} from "@mariozechner/pi-tui";
import type { Component, TUI } from "@mariozechner/pi-tui";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { CopilotModel } from "./types.js";

type Theme = ExtensionContext["ui"]["theme"];

const MAX_VISIBLE_ITEMS = 15;

function formatMultiplier(multiplier: number | null): string {
  if (multiplier === null) return "?x";
  if (multiplier === 0) return "free";
  return `${multiplier}x`;
}

/**
 * Renders content lines inside a rounded box border.
 * Title appears centred in the top border — same style as session-breakdown.
 */
function renderBorderedBox(
  contentLines: string[],
  width: number,
  title: string,
  theme: Theme,
): string[] {
  const innerW = Math.max(1, width - 2);
  const result: string[] = [];

  const titleStr = truncateToWidth(` ${title} `, innerW);
  const titleW = visibleWidth(titleStr);
  const leftPad = "─".repeat(Math.floor((innerW - titleW) / 2));
  const rightPad = "─".repeat(Math.max(0, innerW - titleW - leftPad.length));

  result.push(
    theme.fg("border", `╭${leftPad}`) +
      theme.fg("accent", titleStr) +
      theme.fg("border", `${rightPad}╮`),
  );

  for (const line of contentLines) {
    const padded = truncateToWidth(" " + line, innerW, "…", true);
    result.push(theme.fg("border", "│") + padded + theme.fg("border", "│"));
  }

  result.push(theme.fg("border", `╰${"─".repeat(innerW)}╯`));

  return result;
}

function buildSelectItems(
  models: CopilotModel[],
  activeModelId: string | undefined,
): SelectItem[] {
  return models.map((m) => {
    const multiplierStr = formatMultiplier(m.multiplier);
    const isActive = m.id === activeModelId;
    return {
      value: m.id,
      label: isActive ? `${m.name} ●` : m.name,
      description: `[${multiplierStr}]  ${m.id}`,
    };
  });
}

export class ModelsOverlayComponent implements Component {
  private input: Input;
  private list: SelectList;
  private tui: TUI;
  private theme: Theme;
  private onDone: (value: string | null) => void;
  private allItems: SelectItem[];
  private kb = getEditorKeybindings();

  constructor(
    models: CopilotModel[],
    activeModelId: string | undefined,
    tui: TUI,
    theme: Theme,
    onDone: (value: string | null) => void,
  ) {
    this.tui = tui;
    this.theme = theme;
    this.onDone = onDone;

    this.allItems = buildSelectItems(models, activeModelId);
    this.input = new Input();
    this.list = this.buildList(this.allItems);
  }

  private buildList(items: SelectItem[]): SelectList {
    const list = new SelectList(items, MAX_VISIBLE_ITEMS, {
      selectedPrefix: (t: string) => this.theme.fg("accent", t),
      selectedText: (t: string) => this.theme.fg("accent", t),
      description: (t: string) => this.theme.fg("muted", t),
      scrollInfo: (t: string) => this.theme.fg("dim", t),
      noMatch: (t: string) => this.theme.fg("warning", t),
    });
    list.onSelect = (item) => this.onDone(item.value);
    list.onCancel = () => this.onDone(null);
    return list;
  }

  /** Rebuild the list with fuzzy-filtered items based on current search query. */
  private applyFilter(): void {
    const query = this.input.getValue();
    const filtered = query.trim()
      ? fuzzyFilter(
          this.allItems,
          query,
          (item) => `${item.label} ${item.description ?? ""}`,
        )
      : this.allItems;
    this.list = this.buildList(filtered);
  }

  invalidate(): void {}

  private handleCancel(data: string): boolean {
    if (this.kb.matches(data, "selectCancel") || matchesKey(data, "ctrl+[")) {
      this.onDone(null);
      return true;
    }
    return false;
  }

  private handleNavigation(data: string): boolean {
    if (
      this.kb.matches(data, "selectUp") ||
      this.kb.matches(data, "selectDown") ||
      this.kb.matches(data, "selectConfirm")
    ) {
      this.list.handleInput(data);
      this.tui.requestRender();
      return true;
    }
    return false;
  }

  private handlePageNavigation(data: string): boolean {
    const list = this.list as any;

    if (this.kb.matches(data, "selectPageUp")) {
      list.selectedIndex = Math.max(0, list.selectedIndex - list.maxVisible);
      this.tui.requestRender();
      return true;
    }

    if (this.kb.matches(data, "selectPageDown")) {
      const lastIndex = Math.max(0, list.filteredItems.length - 1);
      list.selectedIndex = Math.min(
        lastIndex,
        list.selectedIndex + list.maxVisible,
      );
      this.tui.requestRender();
      return true;
    }

    return false;
  }

  handleInput(data: string): void {
    if (this.handleCancel(data)) return;
    if (this.handleNavigation(data)) return;
    if (this.handlePageNavigation(data)) return;

    this.input.handleInput(data);
    this.applyFilter();
    this.tui.requestRender();
  }

  render(width: number): string[] {
    const theme = this.theme;
    const innerW = Math.max(1, width - 2);
    const contentLines: string[] = [];

    // Search input row
    const searchLabel = theme.fg("accent", " Search: ");
    const labelW = visibleWidth(searchLabel);
    const inputWidth = Math.max(1, innerW - labelW - 1);
    const inputLines = this.input.render(inputWidth);
    contentLines.push(searchLabel + (inputLines[0] ?? ""));

    // Separator
    contentLines.push(theme.fg("border", "─".repeat(innerW)));

    // Model list
    const listLines = this.list.render(innerW - 1);
    for (const line of listLines) {
      contentLines.push(" " + line);
    }

    // Help hint
    contentLines.push(
      theme.fg(
        "dim",
        " ↑↓ navigate · ^u/^d page · type to filter · enter select · esc cancel",
      ),
    );

    return renderBorderedBox(contentLines, width, "Copilot Models", theme);
  }
}
