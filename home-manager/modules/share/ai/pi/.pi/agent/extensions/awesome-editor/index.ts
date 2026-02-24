/**
 * custom-editor — vim modal editing + snippet autocomplete.
 *
 * Vim keybindings:
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
 * Snippet autocomplete (type trigger, press Tab):
 *   ?q             → clarification instruction
 *   $date          → today's date (YYYY-MM-DD)
 *   $tdd           → red/green TDD instruction
 *   $test_pi       → test pi extension via tmux instruction
 *
 * Dependencies:
 * - ../snippet/
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { AwesomeEditor } from "./editor.js";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setEditorComponent((tui, theme, kb) => new AwesomeEditor(tui, theme, kb));
  });
}
