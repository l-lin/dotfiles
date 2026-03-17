import { matchesKey } from "@mariozechner/pi-tui";
import {
  bold,
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
  wrapText,
  isNavUp,
  isNavDown,
  isConfirm,
  isCancel,
} from "./ui-helpers.js";

const MAX_VISIBLE_LINES = 15;
const MIN_VISIBLE_LINES = 5;

export class OracleResultComponent {
  private selected = 0; // 0 = Yes, 1 = No
  private scrollOffset = 0;
  private cachedLines: string[] = [];
  private cachedWidth = 0;

  constructor(
    private result: string,
    private modelName: string,
    private prompt: string,
    private tui: { requestRender: () => void },
    private onDone: (addToContext: boolean) => void,
  ) {}

  handleInput(data: string): void {
    if (isCancel(data) || data === "n" || data === "N") {
      this.onDone(false);
      return;
    }
    if (isConfirm(data)) {
      this.onDone(this.selected === 0);
      return;
    }
    if (data === "y" || data === "Y") {
      this.onDone(true);
      return;
    }

    if (
      matchesKey(data, "left") ||
      matchesKey(data, "right") ||
      data === "h" ||
      data === "l" ||
      matchesKey(data, "tab")
    ) {
      this.selected = this.selected === 0 ? 1 : 0;
    } else if (isNavUp(data)) {
      this.scrollOffset = Math.max(0, this.scrollOffset - 1);
    } else if (isNavDown(data)) {
      const maxOffset = Math.max(0, this.result.split("\n").length - 1);
      this.scrollOffset = Math.min(this.scrollOffset + 1, maxOffset);
    } else {
      return;
    }
    this.invalidate();
    this.tui.requestRender();
  }

  invalidate(): void {
    this.cachedWidth = 0;
  }

  render(width: number): string[] {
    if (this.cachedWidth === width) return this.cachedLines;

    const bw = Math.min(80, width - 4);
    const contentWidth = bw - 4;
    const pad = (l: string) => padLine(l, width);
    const box = (c: string) => boxLine(c, bw);

    const lines: string[] = [
      "",
      pad(boxTop(bw)),
      pad(box(bold(magenta(`🔮 Oracle Response (${this.modelName})`)))),
      pad(boxMid(bw)),
      pad(box(dim("Q: ") + truncate(this.prompt, contentWidth - 10))),
      pad(boxMid(bw)),
    ];

    const resultLines = wrapText(this.result, contentWidth);
    const visible = resultLines.slice(
      this.scrollOffset,
      this.scrollOffset + MAX_VISIBLE_LINES,
    );

    for (const line of visible) {
      lines.push(pad(box(line)));
    }
    // Pad short results to minimum height
    for (
      let i = visible.length;
      i < Math.min(MAX_VISIBLE_LINES, MIN_VISIBLE_LINES);
      i++
    ) {
      lines.push(pad(box("")));
    }

    if (resultLines.length > MAX_VISIBLE_LINES) {
      const end = Math.min(
        this.scrollOffset + MAX_VISIBLE_LINES,
        resultLines.length,
      );
      lines.push(
        pad(
          box(
            dim(
              ` ↑↓ scroll (${this.scrollOffset + 1}-${end}/${resultLines.length})`,
            ),
          ),
        ),
      );
    }

    lines.push(pad(boxMid(bw)));
    lines.push(pad(box(bold("Add to current conversation context?"))));
    lines.push(pad(box("")));

    const yesBtn =
      this.selected === 0 ? green(bold(" [ YES ] ")) : dim("   YES   ");
    const noBtn =
      this.selected === 1 ? yellow(bold(" [ NO ] ")) : dim("   NO   ");
    lines.push(pad(box(`       ${yesBtn}          ${noBtn}`)));

    lines.push(pad(box("")));
    lines.push(pad(boxMid(bw)));
    lines.push(
      pad(
        box(
          dim("←→/Tab") +
            " switch  " +
            dim("Enter") +
            " confirm  " +
            dim("Y/N") +
            " quick",
        ),
      ),
    );
    lines.push(pad(boxBottom(bw)), "");

    this.cachedLines = lines;
    this.cachedWidth = width;
    return lines;
  }
}
