/**
 * Web Fetch Extension - Fetch and read content from URLs
 *
 * Provides a tool to fetch a URL and return its content as either raw HTML
 * or extracted readable text (stripped of tags/scripts/styles).
 *
 * Use /web-fetch-toggle to enable/disable the tool. When disabled, the tool
 * is removed from the active tools list so it doesn't appear in the agent context.
 * State is persisted to ~/.pi/agent/settings.json under extensionSettings.webFetch.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { keyHint } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

// ============================================================================
// Settings
// ============================================================================

const SETTINGS_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

interface WebFetchConfig {
  enabled: boolean;
}

const DEFAULTS: WebFetchConfig = { enabled: true };

function loadConfig(): WebFetchConfig {
  try {
    const raw = fs.readFileSync(SETTINGS_PATH, "utf-8");
    const settings = JSON.parse(raw) as {
      extensionSettings?: { webFetch?: Partial<WebFetchConfig> };
    };
    const parsed = settings.extensionSettings?.webFetch ?? {};
    return {
      enabled:
        typeof parsed.enabled === "boolean" ? parsed.enabled : DEFAULTS.enabled,
    };
  } catch {
    return { ...DEFAULTS };
  }
}

function saveEnabled(enabled: boolean): void {
  let settings: Record<string, unknown> = {};
  try {
    settings = JSON.parse(fs.readFileSync(SETTINGS_PATH, "utf-8"));
  } catch {
    // File missing or malformed — start fresh
  }
  const extensionSettings = (settings.extensionSettings ?? {}) as Record<
    string,
    unknown
  >;
  const existing = (extensionSettings.webFetch ?? {}) as Record<
    string,
    unknown
  >;
  extensionSettings.webFetch = { ...existing, enabled };
  settings.extensionSettings = extensionSettings;
  fs.mkdirSync(path.dirname(SETTINGS_PATH), { recursive: true });
  fs.writeFileSync(
    SETTINGS_PATH,
    JSON.stringify(settings, null, 2) + "\n",
    "utf-8",
  );
}

// ============================================================================
// Constants
// ============================================================================

const DEFAULT_MAX_LENGTH = 50_000;
const FETCH_TIMEOUT_MS = 30_000;

// ============================================================================
// Schema
// ============================================================================

const WebFetchParams = Type.Object({
  url: Type.String({
    description: "URL to fetch (must include scheme, e.g. https://example.com)",
  }),
  mode: Type.Optional(
    Type.Union([Type.Literal("raw"), Type.Literal("readable")], {
      description:
        '"raw" returns the full HTML/text body; "readable" strips tags and extracts human-readable text (default: "readable")',
    }),
  ),
  max_length: Type.Optional(
    Type.Number({
      description: `Maximum number of characters to return (default: ${DEFAULT_MAX_LENGTH})`,
      minimum: 100,
      maximum: 500_000,
    }),
  ),
});

// ============================================================================
// HTML → readable text
// ============================================================================

function extractReadableText(html: string): string {
  // Remove <script> and <style> blocks entirely (including content)
  let text = html
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
    .replace(/<!--[\s\S]*?-->/g, " ");

  // Replace block-level tags with newlines for readability
  text = text.replace(
    /<\/(p|div|section|article|header|footer|h[1-6]|li|tr|blockquote|pre)>/gi,
    "\n",
  );

  // Replace <br> and <hr> with newlines
  text = text.replace(/<br\s*\/?>/gi, "\n").replace(/<hr\s*\/?>/gi, "\n---\n");

  // Strip remaining HTML tags
  text = text.replace(/<[^>]+>/g, "");

  // Decode common HTML entities
  text = text
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&mdash;/g, "—")
    .replace(/&ndash;/g, "–")
    .replace(/&hellip;/g, "…");

  // Collapse whitespace: multiple spaces → single space, 3+ newlines → 2
  text = text
    .replace(/[ \t]+/g, " ")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();

  return text;
}

// ============================================================================
// Details type
// ============================================================================

interface FetchDetails {
  url: string;
  mode: "raw" | "readable";
  status: number;
  contentType: string;
  originalLength: number;
  returnedLength: number;
  truncated: boolean;
  error?: string;
}

// ============================================================================
// Extension
// ============================================================================

export default function webFetchExtension(pi: ExtensionAPI) {
  const config = loadConfig();

  pi.registerCommand("cmd:web-fetch-toggle", {
    description: "Toggle web-fetch tool on/off",
    handler: async (_args, ctx) => {
      config.enabled = !config.enabled;
      saveEnabled(config.enabled);
      if (config.enabled) {
        pi.setActiveTools([...new Set([...pi.getActiveTools(), "web-fetch"])]);
      } else {
        pi.setActiveTools(pi.getActiveTools().filter((t) => t !== "web-fetch"));
      }
      ctx.ui.notify(
        `web-fetch ${config.enabled ? "enabled" : "disabled"}`,
        "info",
      );
    },
  });

  if (!config.enabled) return;

  pi.registerTool({
    name: "web-fetch",
    label: "Web Fetch",
    description:
      'Fetch the content of a URL. Use mode="readable" (default) to get clean human-readable text with HTML tags stripped, or mode="raw" to get the full HTML/text body. Useful for reading documentation, articles, or any web page.',
    parameters: WebFetchParams,

    async execute(_toolCallId, params, signal) {
      const mode = params.mode ?? "readable";
      const maxLength = params.max_length ?? DEFAULT_MAX_LENGTH;

      const errorResult = (
        message: string,
      ): {
        content: { type: "text"; text: string }[];
        details: FetchDetails;
      } => ({
        content: [{ type: "text" as const, text: `Error: ${message}` }],
        details: {
          url: params.url,
          mode,
          status: 0,
          contentType: "",
          originalLength: 0,
          returnedLength: 0,
          truncated: false,
          error: message,
        },
      });

      // Basic URL validation
      let parsedUrl: URL;
      try {
        parsedUrl = new URL(params.url);
      } catch {
        return errorResult(`Invalid URL: "${params.url}"`);
      }

      if (!["http:", "https:"].includes(parsedUrl.protocol)) {
        return errorResult(
          `Unsupported protocol "${parsedUrl.protocol}" — only http/https are allowed`,
        );
      }

      // Fetch with timeout — track whether the abort was ours (timeout) or external (cancellation)
      const controller = new AbortController();
      let timedOut = false;
      const timeoutId = setTimeout(() => {
        timedOut = true;
        controller.abort();
      }, FETCH_TIMEOUT_MS);

      // Forward external cancellation into our controller; clean up listener when done
      const onExternalAbort = () => controller.abort();
      signal?.addEventListener("abort", onExternalAbort);

      let response: Response;
      try {
        response = await fetch(params.url, {
          signal: controller.signal,
          headers: {
            // Identify as a bot, request plain text where possible
            "User-Agent": "pi-coding-agent/web-fetch",
            Accept: "text/html,text/plain,application/xhtml+xml,*/*",
          },
          redirect: "follow",
        });
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        return errorResult(
          timedOut
            ? `Request timed out after ${FETCH_TIMEOUT_MS / 1000}s`
            : `Network error: ${msg}`,
        );
      } finally {
        clearTimeout(timeoutId);
        signal?.removeEventListener("abort", onExternalAbort);
      }

      const contentType = response.headers.get("content-type") ?? "";

      if (!response.ok) {
        // Consume/cancel the body to release the connection back to the pool
        response.body?.cancel().catch(() => {});
        return errorResult(`HTTP ${response.status} ${response.statusText}`);
      }

      let body: string;
      try {
        body = await response.text();
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        return errorResult(`Failed to read response body: ${msg}`);
      }

      const originalLength = body.length;

      // Process content
      let content = mode === "readable" ? extractReadableText(body) : body;

      const truncated = content.length > maxLength;
      if (truncated) {
        content =
          content.slice(0, maxLength) +
          `\n\n…[truncated — ${originalLength.toLocaleString()} chars total, showing first ${maxLength.toLocaleString()}]`;
      }

      const details: FetchDetails = {
        url: params.url,
        mode,
        status: response.status,
        contentType,
        originalLength,
        returnedLength: content.length,
        truncated,
      };

      return {
        content: [{ type: "text" as const, text: content }],
        details,
      };
    },

    renderCall(args, theme) {
      const url = (args.url as string) || "(no url)";
      const mode = (args.mode as string) || "readable";

      let text = theme.fg("toolTitle", theme.bold("Web Fetch "));
      text += theme.fg("accent", url);
      text += theme.fg("dim", ` [${mode}]`);

      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded, isPartial }, theme) {
      if (isPartial) {
        return new Text(theme.fg("warning", " ⟳ Fetching…"), 0, 0);
      }

      const details = result.details as FetchDetails | undefined;

      if (details?.error) {
        return new Text(theme.fg("error", ` ✗ ${details.error}`), 0, 0);
      }

      if (!details) {
        return new Text(theme.fg("success", " ✓ Fetched"), 0, 0);
      }

      if (!expanded) {
        const truncNote = details.truncated ? " (truncated)" : "";
        const hint = keyHint("expandTools", "to expand");
        let text = theme.fg("success", "✓ ");
        text += theme.fg(
          "text",
          `${details.returnedLength.toLocaleString()} chars`,
        );
        text += theme.fg("muted", `${truncNote} • HTTP ${details.status}`);
        text += theme.fg("dim", ` (${hint})`);
        return new Text(text, 0, 0);
      }

      // Expanded: show metadata + first 500 chars of content
      let text = theme.fg("success", "✓ Fetched\n");
      text +=
        theme.fg("dim", `  URL:      `) + theme.fg("text", details.url) + "\n";
      text +=
        theme.fg("dim", `  Mode:     `) + theme.fg("text", details.mode) + "\n";
      text +=
        theme.fg("dim", `  Status:   `) +
        theme.fg("text", String(details.status)) +
        "\n";
      text +=
        theme.fg("dim", `  Type:     `) +
        theme.fg("text", details.contentType || "unknown") +
        "\n";
      text +=
        theme.fg("dim", `  Size:     `) +
        theme.fg("text", `${details.returnedLength.toLocaleString()} chars`) +
        theme.fg(
          "dim",
          ` (raw HTML: ${details.originalLength.toLocaleString()})`,
        ) +
        "\n";
      if (details.truncated) {
        text += theme.fg("warning", "  ⚠ Output was truncated\n");
      }

      const preview =
        result.content[0]?.type === "text"
          ? result.content[0].text.slice(0, 500)
          : "";
      if (preview) {
        text +=
          "\n" +
          theme.fg("dim", "── preview ──\n") +
          theme.fg("muted", preview);
        if (preview.length === 500) text += theme.fg("dim", "\n…");
      }

      return new Text(text, 0, 0);
    },
  });
}
