import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { ReplyComponent, type ReplyComponentResult } from "./component.js";
import { fromAssistantContent } from "./model.js";
import { REPLY_KEYMAP } from "./settings.js";

export default function replyExtension(pi: ExtensionAPI): void {
  const keymap = REPLY_KEYMAP;
  const openKey = keymap.open;

  pi.registerShortcut(openKey, {
    description: "Annotate the last assistant message",
    handler: async (ctx) => {
      if (ctx.mode !== "tui" || !ctx.hasUI) return;

      const source = getLastAssistantSource(ctx);
      if (source === null) {
        ctx.ui.notify(
          "No text in the last assistant message to reply to.",
          "error",
        );
        return;
      }

      let insertionError: unknown;
      const result = await ctx.ui.custom<ReplyComponentResult | undefined>(
        (tui, theme, _keybindings, done) =>
          new ReplyComponent(
            tui,
            theme,
            source,
            keymap,
            done,
            (text) => {
              try {
                // Insert before closing so the overlay's render includes the updated editor.
                ctx.ui.pasteToEditor(text);
              } catch (error) {
                insertionError = error;
              }
            },
            () => {
              const refreshedSource = getLastAssistantSource(ctx);
              if (refreshedSource === null) {
                ctx.ui.notify(
                  "No text in the last assistant message to reply to.",
                  "error",
                );
              }
              return refreshedSource;
            },
          ),
        {
          overlay: true,
          overlayOptions: {
            anchor: "center",
            width: "75%",
            minWidth: 30,
            maxHeight: "85%",
            margin: 1,
          },
        },
      );

      if (result?.action !== "save" || result.text === undefined) return;
      if (insertionError !== undefined) {
        ctx.ui.notify(
          `Could not insert the annotated reply: ${insertionError instanceof Error ? insertionError.message : String(insertionError)}`,
          "error",
        );
      }
    },
  });
}

export function getLastAssistantSource(ctx: ExtensionContext): string | null {
  const branch = ctx.sessionManager.getBranch();
  for (let index = branch.length - 1; index >= 0; index--) {
    const entry = branch[index];
    if (entry?.type !== "message") continue;

    const message = entry.message;
    if (message.role !== "assistant") continue;
    return fromAssistantContent(message.content);
  }
  return null;
}
