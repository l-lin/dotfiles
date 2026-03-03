import {
  Container,
  Key,
  Text,
  matchesKey,
  type Component,
  type TUI,
  visibleWidth,
} from "@mariozechner/pi-tui";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import type { BreakdownData, MeasurementMode } from "./types.ts";
import { RANGE_DAYS } from "./constants.ts";
import { bold, dim } from "./color-utils.ts";
import { toLocalDayKey } from "./date-utils.ts";
import { renderBreakdownBody } from "./renderer.ts";

export class BreakdownComponent implements Component {
  private data: BreakdownData;
  private tui: TUI;
  private onDone: () => void;
  private rangeIndex = 1; // default 30d
  private measurement: MeasurementMode = "sessions";
  private cachedWidth?: number;
  private isLight = false;
  private container: Container;
  private body: Text;

  constructor(data: BreakdownData, tui: TUI, onDone: () => void, theme?: any) {
    this.data = data;
    this.tui = tui;
    this.onDone = onDone;
    // Theme provided by pi; detect light vs dark by name when possible.
    try {
      this.isLight = !!(
        theme &&
        typeof theme.name === "string" &&
        theme.name.toLowerCase().includes("light")
      );
    } catch {
      this.isLight = false;
    }

    const accentBorder = (s: string) => (theme ? theme.fg("accent", s) : s);

    this.container = new Container();
    this.container.addChild(new DynamicBorder(accentBorder));
    this.container.addChild(
      new Text(
        (theme
          ? theme.fg("accent", theme.bold("Session breakdown"))
          : bold("Session breakdown")) +
          (theme
            ? theme.fg("dim", "  (←/→ range · tab metric · q close)")
            : dim("  (←/→ range · tab metric · q close)")),
        1,
        0,
      ),
    );
    this.container.addChild(new Text("", 1, 0));
    this.body = new Text("", 1, 0);
    this.container.addChild(this.body);
    this.container.addChild(new Text("", 1, 0));
    this.container.addChild(new DynamicBorder(accentBorder));
  }

  private rebuild(width: number): void {
    // Text children have 1-char left indent; use inner width for content that is width-sensitive.
    const inner = Math.max(1, width - 1);

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
    );

    this.body.setText(
      lines
        .map((l) => (visibleWidth(l) > inner ? l.slice(0, inner) : l))
        .join("\n"),
    );
    this.cachedWidth = width;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.container.invalidate();
  }

  handleInput(data: string): void {
    if (
      matchesKey(data, Key.escape) ||
      matchesKey(data, Key.ctrl("c")) ||
      data.toLowerCase() === "q"
    ) {
      this.onDone();
      return;
    }

    if (
      matchesKey(data, Key.tab) ||
      matchesKey(data, Key.shift("tab")) ||
      data.toLowerCase() === "t"
    ) {
      const order: MeasurementMode[] = ["sessions", "messages", "tokens"];
      const idx = Math.max(0, order.indexOf(this.measurement));
      const dir = matchesKey(data, Key.shift("tab")) ? -1 : 1;
      this.measurement =
        order[(idx + order.length + dir) % order.length] ?? "sessions";
      this.invalidate();
      this.tui.requestRender();
      return;
    }

    const prev = () => {
      this.rangeIndex =
        (this.rangeIndex + RANGE_DAYS.length - 1) % RANGE_DAYS.length;
      this.invalidate();
      this.tui.requestRender();
    };
    const next = () => {
      this.rangeIndex = (this.rangeIndex + 1) % RANGE_DAYS.length;
      this.invalidate();
      this.tui.requestRender();
    };

    if (matchesKey(data, Key.left) || data.toLowerCase() === "h") prev();
    if (matchesKey(data, Key.right) || data.toLowerCase() === "l") next();

    if (data === "1") {
      this.rangeIndex = 0;
      this.invalidate();
      this.tui.requestRender();
    }
    if (data === "2") {
      this.rangeIndex = 1;
      this.invalidate();
      this.tui.requestRender();
    }
    if (data === "3") {
      this.rangeIndex = 2;
      this.invalidate();
      this.tui.requestRender();
    }
  }

  render(width: number): string[] {
    if (this.cachedWidth !== width) this.rebuild(width);
    return this.container.render(width);
  }
}
