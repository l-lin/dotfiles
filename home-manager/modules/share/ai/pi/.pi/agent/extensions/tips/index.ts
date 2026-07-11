/**
 * Tips Extension - Pattern-based message monitoring with footer status display.
 *
 * Matches the full user input (case-insensitive, whole-word) against known
 * commands and shows a follow-up tip in the footer status bar directly on
 * `input`, via `ctx.ui.setStatus('tips', ...)`.
 *
 * Clears the tip on `session_start` for a fresh session.
 */

import type { ExtensionAPI, InputEvent } from "@earendil-works/pi-coding-agent";
import { findRuleForInput, type TipRule } from "./rules.js";

const TIPS_STATUS_KEY = "tips";
// Dim ANSI code — tips appear muted in the footer status bar.
const DIM_START = "\x1b[2m";
const DIM_END = "\x1b[0m";

export default function (pi: ExtensionAPI): void {
  function setStatus(
    ctx: { ui: { setStatus: (key: string, text: string | undefined) => void } },
    text: string | undefined,
  ): void {
    ctx.ui.setStatus(TIPS_STATUS_KEY, text);
  }

  pi.on(
    "input",
    (
      event: InputEvent,
      ctx: {
        ui: { setStatus: (key: string, text: string | undefined) => void };
      },
    ) => {
      const text = event.text?.trim();
      if (!text) return;

      const rule: TipRule | undefined = findRuleForInput(text);
      if (rule) {
        // Wrap tip in dim ANSI codes so it renders muted in the footer.
        setStatus(ctx, `${DIM_START}${rule.tip}${DIM_END}`);
      }
    },
  );

  pi.on(
    "session_start",
    (
      _event: { type: string },
      ctx: {
        ui: { setStatus: (key: string, text: string | undefined) => void };
      },
    ) => {
      setStatus(ctx, undefined);
    },
  );
}
