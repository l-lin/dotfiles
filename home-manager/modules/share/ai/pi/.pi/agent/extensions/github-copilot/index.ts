/**
 * GitHub Copilot Extension
 *
 * - Usage widget: shows premium request quota + days remaining above editor
 * - /cmd:copilot-models: interactive model picker with search + multiplier info
 * - /cmd:copilot-usage: manual usage refresh
 * - /cmd:copilot-usage-toggle: show/hide the usage widget
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { getOAuthToken } from "./auth.js";
import { fetchUsage, fetchCopilotModels } from "./api.js";
import { loadSettings, saveSettings } from "./settings.js";
import { updateWidget, WIDGET_ID, WIDGET_PLACEMENT } from "./widget.js";
import { ModelsOverlayComponent } from "./models-overlay.js";
import type { UsageData, AuthStatus } from "./types.js";

export default function githubCopilotExtension(pi: ExtensionAPI) {
  let cachedUsage: UsageData | null = null;
  let cachedAuth: AuthStatus | null = null;
  let sessionStartUsage: UsageData | null = null;

  const settings = loadSettings();
  let widgetVisible = settings.visible !== false;

  async function refresh(ctx: ExtensionContext): Promise<void> {
    if (!ctx.hasUI) return;

    if (!widgetVisible) {
      ctx.ui.setWidget(WIDGET_ID, [], WIDGET_PLACEMENT);
      return;
    }

    cachedAuth = getOAuthToken();
    cachedUsage =
      cachedAuth.hasToken && cachedAuth.token
        ? await fetchUsage(cachedAuth.token)
        : null;

    const delta = calculateDelta(sessionStartUsage, cachedUsage);
    updateWidget(ctx, cachedUsage, cachedAuth, delta);
  }

  function calculateDelta(
    baseline: UsageData | null,
    current: UsageData | null,
  ): number {
    if (!baseline || !current) return 0;
    if (baseline.unlimited || current.unlimited) return 0;
    return Math.max(0, current.used - baseline.used);
  }

  pi.on("session_start", async (_event, ctx) => {
    if (widgetVisible && ctx.hasUI) {
      cachedAuth = getOAuthToken();
      sessionStartUsage =
        cachedAuth.hasToken && cachedAuth.token
          ? await fetchUsage(cachedAuth.token)
          : null;
      cachedUsage = sessionStartUsage;

      updateWidget(ctx, cachedUsage, cachedAuth, 0);
    }
  });

  pi.on("session_switch", async (_event, ctx) => {
    if (widgetVisible) {
      sessionStartUsage = cachedUsage;
      await refresh(ctx);
    }
  });

  pi.on("agent_end", async (_event, ctx) => {
    if (widgetVisible) await refresh(ctx);
  });

  // ─── Commands ────────────────────────────────────────────────────────────

  pi.registerCommand("cmd:copilot-usage", {
    description: "Refresh GitHub Copilot premium request usage",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;
      ctx.ui.notify("Refreshing Copilot usage…", "info");

      // Fetch directly — refresh() is widget-visibility-gated and would bail
      // early if the widget is hidden, leaving the cache stale.
      cachedAuth = getOAuthToken();
      cachedUsage =
        cachedAuth.hasToken && cachedAuth.token
          ? await fetchUsage(cachedAuth.token)
          : null;

      if (widgetVisible) {
        const delta = calculateDelta(sessionStartUsage, cachedUsage);
        updateWidget(ctx, cachedUsage, cachedAuth, delta);
      }

      if (cachedUsage?.unlimited) {
        ctx.ui.notify("Unlimited premium requests", "info");
      } else if (cachedUsage) {
        ctx.ui.notify(
          `${cachedUsage.used}/${cachedUsage.quota} requests used (${cachedUsage.remaining} remaining)`,
          "info",
        );
      } else if (cachedAuth?.error) {
        ctx.ui.notify(cachedAuth.error, "error");
      } else {
        ctx.ui.notify("Failed to fetch usage data", "error");
      }
    },
  });

  pi.registerCommand("cmd:copilot-models", {
    description: "Browse Copilot models with multipliers and switch to one",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      const auth = getOAuthToken();
      if (!auth.hasToken || !auth.token) {
        ctx.ui.notify(auth.error ?? "No Copilot token found", "error");
        return;
      }

      ctx.ui.notify("Fetching Copilot models…", "info");
      const models = await fetchCopilotModels(auth.token);

      if (models.length === 0) {
        ctx.ui.notify("Failed to fetch Copilot models", "error");
        return;
      }

      // ctx.model?.id may be from any provider — compare by id only
      const currentModelId = ctx.model?.id;

      const selected = await ctx.ui.custom<string | null>(
        (tui, theme, _kb, done) => {
          const overlay = new ModelsOverlayComponent(
            models,
            currentModelId,
            tui,
            theme,
            done,
          );
          return {
            render: (width: number) => overlay.render(width),
            invalidate: () => overlay.invalidate(),
            handleInput: (data: string) => overlay.handleInput(data),
          };
        },
        { overlay: true },
      );

      if (!selected) return;

      // These models come exclusively from the Copilot API, so search by provider.
      // getAll().find(m => m.id === selected) would be wrong: multiple providers
      // can share the same model ID (e.g. both OpenAI and github-copilot have gpt-4o),
      // and it would resolve to the wrong provider — causing setModel to fail.
      const model = ctx.modelRegistry.find("github-copilot", selected);
      if (!model) {
        ctx.ui.notify(`Model not found in registry: ${selected}`, "error");
        return;
      }

      const ok = await pi.setModel(model);
      if (ok) {
        const picked = models.find((m) => m.id === selected);
        ctx.ui.notify(`Switched to ${picked?.name ?? selected}`, "info");
      } else {
        ctx.ui.notify(`No API key available for ${selected}`, "error");
      }
    },
  });

  pi.registerCommand("cmd:copilot-usage-toggle", {
    description: "Toggle GitHub Copilot usage widget visibility",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;
      widgetVisible = !widgetVisible;
      saveSettings({ visible: widgetVisible });
      await refresh(ctx);
      ctx.ui.notify(
        `Copilot usage widget ${widgetVisible ? "shown" : "hidden"}`,
        "info",
      );
    },
  });
}
