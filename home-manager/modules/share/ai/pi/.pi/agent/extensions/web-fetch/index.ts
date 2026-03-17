/**
 * Web Fetch Extension - Fetch and read content from URLs
 *
 * Use /web-fetch-toggle to enable/disable. State persisted to
 * ~/.pi/agent/settings.json under extensionSettings.webFetch.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { executeFetch } from "./fetch.js";
import * as render from "./render.js";
import { loadSettings, saveEnabled } from "./settings.js";
import { DEFAULT_MAX_LENGTH, WebFetchParams } from "./types.js";

export default function webFetchExtension(pi: ExtensionAPI) {
  const settings = loadSettings();

  pi.registerCommand("cmd:web-fetch-toggle", {
    description: "Toggle web-fetch tool on/off",
    handler: async (_args, ctx) => {
      settings.enabled = !settings.enabled;
      saveEnabled(settings.enabled);
      if (settings.enabled) {
        pi.setActiveTools([...new Set([...pi.getActiveTools(), "web-fetch"])]);
      } else {
        pi.setActiveTools(pi.getActiveTools().filter((t) => t !== "web-fetch"));
      }
      ctx.ui.notify(
        `web-fetch ${settings.enabled ? "enabled" : "disabled"}`,
        "info",
      );
      pi.events.emit("custom-tool:changed", {
        tool: "web-fetch",
        enabled: settings.enabled,
      });
    },
  });

  pi.registerTool({
    name: "web-fetch",
    label: "Web Fetch",
    description:
      'Fetch the content of a URL. Use mode="readable" (default) to get clean human-readable text with HTML tags stripped, or mode="raw" to get the full HTML/text body. Useful for reading documentation, articles, or any web page.',
    parameters: WebFetchParams,

    execute(_toolCallId, params, signal) {
      return executeFetch(
        params.url,
        params.mode ?? "readable",
        params.max_length ?? DEFAULT_MAX_LENGTH,
        signal,
      );
    },

    renderCall: render.renderCall,
    renderResult: render.renderResult,
  });
}
