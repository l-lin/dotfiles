/**
 * custom-editor — configurable vi/emacs editing + snippet autocomplete.
 *
 * Vi keybindings:
 *   Escape         insert → normal (in normal mode, aborts agent)
 *   i / a / A / I  enter insert mode
 *   o / O          open line below / above
 *   hjkl           navigation
 *   0 / $          line start / end
 *   w / b / e      word navigation
 *   x              delete char
 *   D              delete to end of line
 *   S              substitute line
 *   s              substitute char
 *   d{motion}      delete with motion (dw db de d$ d0 dd df…)
 *   c{motion}      change with motion
 *   f/F/t/T{char}  jump to character
 *   ; / ,          repeat last f/F/t/T (same / reverse)
 *   Shift+Alt+A    end of line (insert mode shortcut)
 *   Shift+Alt+I    start of line (insert mode shortcut)
 *   Alt+o          open line below (insert mode shortcut)
 *   Alt+Shift+O    open line above (insert mode shortcut)
 *
 * Snippet autocomplete:
 *   $ / ?          Auto-trigger autocomplete for $- and ?-prefixed snippets
 *   Tab/Enter      Apply selected completion (keeps trigger, e.g. "$date")
 *   Ctrl-E         Apply + expand immediately (e.g. "$da" → "2026-03-07")
 *
 * Dependencies:
 * - ../snippet/
 */

import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { AwesomeEditor } from "./editor.js";
import {
  type AwesomeEditorMode,
  isAwesomeEditorMode,
  loadAwesomeEditorSettings,
  saveAwesomeEditorMode,
} from "./settings.js";

export const AWESOME_EDITOR_MODE_COMMAND = "cmd:awesome-editor-mode";

const AWESOME_EDITOR_MODE_OPTIONS: AwesomeEditorMode[] = ["vi", "emacs"];

function createAwesomeEditorFactory(mode: AwesomeEditorMode) {
  return (tui: unknown, theme: unknown, keybindings: unknown) =>
    new AwesomeEditor(
      tui as ConstructorParameters<typeof AwesomeEditor>[0],
      theme as ConstructorParameters<typeof AwesomeEditor>[1],
      keybindings as ConstructorParameters<typeof AwesomeEditor>[2],
      mode,
    );
}

function applyAwesomeEditorMode(
  ctx: Pick<ExtensionCommandContext, "ui"> | Pick<ExtensionContext, "ui">,
  mode: AwesomeEditorMode,
): void {
  ctx.ui.setEditorComponent(createAwesomeEditorFactory(mode));
}

function parseAwesomeEditorMode(args: string): AwesomeEditorMode | null {
  const trimmedArgs = args.trim();

  return isAwesomeEditorMode(trimmedArgs) ? trimmedArgs : null;
}

export default function (pi: ExtensionAPI) {
  const settings = loadAwesomeEditorSettings();

  pi.registerCommand(AWESOME_EDITOR_MODE_COMMAND, {
    description: "Switch awesome-editor between vi and emacs modes",
    getArgumentCompletions(argumentPrefix) {
      const actual = AWESOME_EDITOR_MODE_OPTIONS.filter((mode) =>
        mode.startsWith(argumentPrefix),
      ).map((mode) => ({ value: mode, label: mode }));

      return actual.length > 0 ? actual : null;
    },
    handler: async (args, ctx) => {
      const nextMode = parseAwesomeEditorMode(args);

      if (!nextMode) {
        ctx.ui.notify("Usage: /awesome-editor-mode vi|emacs", "warning");
        return;
      }

      saveAwesomeEditorMode(nextMode);
      settings.mode = nextMode;
      applyAwesomeEditorMode(ctx, nextMode);
      ctx.ui.notify(`Awesome editor mode: ${nextMode}`, "info");
    },
  });

  pi.on("session_start", (_event, ctx) => {
    applyAwesomeEditorMode(ctx, settings.mode);
  });
}
