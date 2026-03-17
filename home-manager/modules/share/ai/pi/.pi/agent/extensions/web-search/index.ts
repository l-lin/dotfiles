/**
 * Web Search Extension - Internet search via Tavily API
 *
 * Provides a tool for searching the web using Tavily's search API.
 * Supports both basic and advanced search options with markdown-formatted results.
 *
 * Use /web-search-toggle to enable/disable the tool. When disabled, the tool
 * is removed from the active tools list so it doesn't appear in the agent context.
 * State is persisted to ~/.pi/agent/settings.json under extensionSettings.webSearch.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { searchTavily } from "./api.js";
import { formatResultsAsMarkdown } from "./format.js";
import * as render from "./render.js";
import { loadSettings, saveEnabled } from "./settings.js";
import type { WebSearchDetails } from "./types.js";
import { WebSearchParams } from "./types.js";

export default function webSearchExtension(pi: ExtensionAPI) {
  const settings = loadSettings();

  pi.registerCommand("cmd:web-search-toggle", {
    description: "Toggle web-search tool on/off",
    handler: async (_args, ctx) => {
      settings.enabled = !settings.enabled;
      saveEnabled(settings.enabled);

      const current = pi.getActiveTools();
      let updated: string[];
      if (settings.enabled) {
        updated = current.includes("web-search")
          ? current
          : [...current, "web-search"];
      } else {
        updated = current.filter((t) => t !== "web-search");
      }
      pi.setActiveTools(updated);

      const status = settings.enabled ? "enabled" : "disabled";
      ctx.ui.notify(`web-search ${status}`, "info");
      pi.events.emit("custom-tool:changed", {
        tool: "web-search",
        enabled: settings.enabled,
      });
    },
  });

  if (!settings.enabled) return;

  pi.registerTool({
    name: "web-search",
    label: "Web Search",
    description:
      "Search the internet using Tavily API. Supports basic and advanced search with domain filtering and AI-generated summaries.",
    parameters: WebSearchParams,

    async execute(_toolCallId, params, _signal) {
      function errorResult(text: string, error: string) {
        return {
          content: [{ type: "text" as const, text }],
          details: {
            query: params.query,
            resultCount: 0,
            hasAnswer: false,
            responseTime: 0,
            error,
          } satisfies WebSearchDetails,
        };
      }

      const apiKey = process.env.TAVILY_API_KEY;
      if (!apiKey) {
        return errorResult(
          "Error: TAVILY_API_KEY environment variable is not set.",
          "missing_api_key",
        );
      }

      if (!params.query?.trim()) {
        return errorResult(
          "Error: Search query cannot be empty.",
          "empty_query",
        );
      }

      try {
        const results = await searchTavily(apiKey, params);
        const markdown = formatResultsAsMarkdown(
          results,
          params.include_raw_content || false,
        );

        return {
          content: [{ type: "text" as const, text: markdown }],
          details: {
            query: params.query,
            resultCount: (results.results || []).length,
            hasAnswer: !!results.answer,
            responseTime: results.response_time || 0,
          } satisfies WebSearchDetails,
        };
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        return errorResult(`Web search failed: ${message}`, message);
      }
    },

    renderCall: render.renderCall,
    renderResult: render.renderResult,
  });
}
