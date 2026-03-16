import {
  matchesKey,
  truncateToWidth,
  visibleWidth,
  type Component,
  type TUI,
} from "@mariozechner/pi-tui";
import type { BreakdownData, BreakdownView, MeasurementMode } from "./types.js";
import { RANGE_DAYS } from "./constants.js";
import { toLocalDayKey } from "./date-utils.js";
import { renderBreakdownBody } from "./renderer.js";

export class BreakdownComponent implements Component {
  private data: BreakdownData;
  private tui: TUI;
  private theme: any;
  private onDone: () => void;
  private rangeIndex = 1; // default 30d
  private measurement: MeasurementMode = "sessions";
  private view: BreakdownView = "model";
  private isLight = false;

  constructor(data: BreakdownData, tui: TUI, onDone: () => void, theme?: any) {
    this.data = data;
    this.tui = tui;
    this.onDone = onDone;
    this.theme = theme;

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
    const th = this.theme;
    const innerW = Math.max(1, width - 2);
    const result: string[] = [];

    const titleStr = truncateToWidth(` ${title} `, innerW);
    const titleW = visibleWidth(titleStr);
    const topLine = "─".repeat(Math.floor((innerW - titleW) / 2));
    const topLine2 = "─".repeat(Math.max(0, innerW - titleW - topLine.length));

    if (th) {
      result.push(
        th.fg("border", `╭${topLine}`) +
          th.fg("accent", titleStr) +
          th.fg("border", `${topLine2}╮`),
      );
    } else {
      result.push(`╭${topLine}${titleStr}${topLine2}╮`);
    }

    for (const line of contentLines) {
      const paddedLine = truncateToWidth(" " + line, innerW, "...", true);
      if (th) {
        result.push(th.fg("border", "│") + paddedLine + th.fg("border", "│"));
      } else {
        result.push("│" + paddedLine + "│");
      }
    }

    if (th) {
      result.push(th.fg("border", `╰${"─".repeat(innerW)}╯`));
    } else {
      result.push(`╰${"─".repeat(innerW)}╯`);
    }

    return result;
  }

  private buildContent(width: number): string[] {
    const inner = Math.max(1, width - 2);

    const selectedDays = RANGE_DAYS[this.rangeIndex];
    const range = this.data.ranges.get(selectedDays)!;

    const todayKey = toLocalDayKey(new Date());
    const todayDay = this.data.ranges.get(7)?.dayByKey.get(todayKey);

    const lines = renderBreakdownBody(
      range,
      selectedDays,
      this.measurement,
      this.data.palette.modelColors,
      this.data.palette.orderedModels,
      this.data.palette.otherColor,
      this.isLight,
      inner,
      todayDay,
      this.rangeIndex,
      this.view,
      this.data.cwdPalette.cwdColors,
      this.data.cwdPalette.orderedCwds,
      this.data.cwdPalette.otherColor,
      this.data.dowPalette.dowColors,
      this.data.dowPalette.orderedDows,
      this.data.todPalette.todColors,
      this.data.todPalette.orderedTods,
    );

    return lines.map((l) => (visibleWidth(l) > inner ? l.slice(0, inner) : l));
  }

  invalidate(): void {
    // No cache to invalidate
  }

  handleInput(data: string): void {
    if (
      matchesKey(data, "escape") ||
      matchesKey(data, "ctrl+c") ||
      data.toLowerCase() === "q"
    ) {
      this.onDone();
      return;
    }

    if (
      matchesKey(data, "tab") ||
      matchesKey(data, "shift+tab") ||
      data.toLowerCase() === "t"
    ) {
      const order: MeasurementMode[] = ["sessions", "messages", "tokens"];
      const idx = Math.max(0, order.indexOf(this.measurement));
      const dir = matchesKey(data, "shift+tab") ? -1 : 1;
      this.measurement =
        order[(idx + order.length + dir) % order.length] ?? "sessions";
      this.tui.requestRender();
      return;
    }

    // ↑/↓ and j/k cycle through breakdown views
    const VIEWS: BreakdownView[] = ["model", "cwd", "dow", "tod"];
    if (matchesKey(data, "up") || data.toLowerCase() === "k") {
      const idx = VIEWS.indexOf(this.view);
      this.view = VIEWS[(idx + VIEWS.length - 1) % VIEWS.length] ?? "model";
      this.tui.requestRender();
      return;
    }
    if (matchesKey(data, "down") || data.toLowerCase() === "j") {
      const idx = VIEWS.indexOf(this.view);
      this.view = VIEWS[(idx + 1) % VIEWS.length] ?? "model";
      this.tui.requestRender();
      return;
    }

    const prev = () => {
      this.rangeIndex =
        (this.rangeIndex + RANGE_DAYS.length - 1) % RANGE_DAYS.length;
      this.tui.requestRender();
    };
    const next = () => {
      this.rangeIndex = (this.rangeIndex + 1) % RANGE_DAYS.length;
      this.tui.requestRender();
    };

    if (matchesKey(data, "left") || data.toLowerCase() === "h") prev();
    if (matchesKey(data, "right") || data.toLowerCase() === "l") next();

    if (data === "1") {
      this.rangeIndex = 0;
      this.tui.requestRender();
    }
    if (data === "2") {
      this.rangeIndex = 1;
      this.tui.requestRender();
    }
    if (data === "3") {
      this.rangeIndex = 2;
      this.tui.requestRender();
    }
  }

  render(width: number): string[] {
    const content = this.buildContent(width);
    const title =
      "Session breakdown · ←→/hl:range · ↑↓/jk:view · tab:metric · q:close";
    return this.box(content, width, title);
  }
}
