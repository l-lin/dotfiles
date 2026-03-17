import * as path from "node:path";
import type { AvailableModel } from "./types.js";
import {
  bold,
  cyan,
  dim,
  green,
  magenta,
  yellow,
  padLine,
  boxLine,
  boxTop,
  boxMid,
  boxBottom,
  truncate,
  isNavUp,
  isNavDown,
  isConfirm,
  isCancel,
} from "./ui-helpers.js";

export class ModelPickerComponent {
  private selected = 0;
  private cachedLines: string[] = [];
  private cachedWidth = 0;

  constructor(
    private models: AvailableModel[],
    private prompt: string,
    private files: string[],
    private tui: { requestRender: () => void },
    private onSelect: (model: AvailableModel) => void,
    private onCancel: () => void,
  ) {}

  handleInput(data: string): void {
    if (isCancel(data) || data === "q" || data === "Q") {
      this.onCancel();
      return;
    }
    if (isConfirm(data)) {
      this.onSelect(this.models[this.selected]);
      return;
    }
    if (isNavUp(data)) {
      this.selected = Math.max(0, this.selected - 1);
    } else if (isNavDown(data)) {
      this.selected = Math.min(this.models.length - 1, this.selected + 1);
    } else if (data >= "1" && data <= "9") {
      const idx = parseInt(data) - 1;
      if (idx < this.models.length) {
        this.onSelect(this.models[idx]);
        return;
      }
    } else {
      return; // unhandled key — no re-render needed
    }
    this.invalidate();
    this.tui.requestRender();
  }

  invalidate(): void {
    this.cachedWidth = 0;
  }

  render(width: number): string[] {
    if (this.cachedWidth === width) return this.cachedLines;

    const bw = Math.min(60, width - 4);
    const pad = (l: string) => padLine(l, width);
    const box = (c: string) => boxLine(c, bw);

    const lines: string[] = [
      "",
      pad(boxTop(bw)),
      pad(box(bold(magenta("🔮 Oracle - Second Opinion")))),
      pad(boxMid(bw)),
      pad(box(dim("Prompt: ") + truncate(this.prompt, bw - 12))),
    ];

    if (this.files.length > 0) {
      const filesStr = this.files
        .map((f) => cyan("@" + path.basename(f)))
        .join(" ");
      lines.push(pad(box(dim("Files:  ") + filesStr)));
    }

    lines.push(pad(boxMid(bw)));
    lines.push(pad(box(dim("↑↓/jk navigate • 1-9 quick select • Enter send"))));
    lines.push(pad(box("")));

    for (let i = 0; i < this.models.length; i++) {
      const m = this.models[i];
      const num = i < 9 ? yellow(`${i + 1}`) : " ";
      const pointer = i === this.selected ? green("❯ ") : "  ";
      const name = i === this.selected ? green(bold(m.name)) : m.name;
      lines.push(
        pad(box(`${pointer}${num}. ${name}${dim(` (${m.provider})`)}`)),
      );
    }

    lines.push(pad(box("")), pad(boxMid(bw)));
    lines.push(pad(box(dim("Esc") + " cancel")));
    lines.push(pad(boxBottom(bw)), "");

    this.cachedLines = lines;
    this.cachedWidth = width;
    return lines;
  }
}
