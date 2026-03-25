/**
 * Web Fetch Extension - Fetch and read content from URLs
 *
 * Use /web-fetch-toggle to enable/disable. State persisted to
 * ~/.pi/agent/settings.json under extensionSettings.webFetch.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { executeFetch } from "./fetch.js";
import * as render from "./render.js";
import { DEFAULT_MAX_LENGTH, WebFetchParams } from "./types.js";
import {
  loadEnabledSettings,
  registerEnabledToggleCommand,
  saveExtensionSettings,
  updateActiveTools,
} from "../tool-settings/index.js";

const TOOL_NAME = "web-fetch";
const SETTINGS_KEY = "webFetch";
const DEFAULT_SETTINGS = { enabled: true };

export default function webFetchExtension(pi: ExtensionAPI) {
  const settings = loadEnabledSettings(SETTINGS_KEY, DEFAULT_SETTINGS);

  registerEnabledToggleCommand(pi, {
    toolName: TOOL_NAME,
    description: `Toggle ${TOOL_NAME} tool on/off`,
    settings,
    saveEnabled(enabled: boolean) {
      saveExtensionSettings({
        extensionKey: SETTINGS_KEY,
        enabled,
      });
    },
  });

  pi.registerTool({
    name: TOOL_NAME,
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

  pi.on("session_start", () =>
    updateActiveTools(pi, { toolName: TOOL_NAME, enabled: settings.enabled }),
  );
}
