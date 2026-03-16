/**
 * Data gathering functions
 */

import type { Theme } from "@mariozechner/pi-coding-agent";
import { TOOL_ORDER, TOOL_ICONS, ICONS } from "./constants.js";
import { getToolStatus } from "./settings.js";
import { formatTokens } from "./formatting.js";

export interface ContextData {
  display: string;
  percent: number;
}

export function getContextData(ctx: any): ContextData {
  const ctxUsage = ctx.getContextUsage();

  if (!ctxUsage) {
    return { display: ICONS["token-usage"], percent: 0 };
  }

  const { contextWindow = 0, percent = 0 } = ctxUsage;
  const usedTokens = Math.round((contextWindow * percent) / 100);
  const percentRounded = Math.round(percent);
  const display = `${ICONS["token-usage"]} ${formatTokens(usedTokens)}/${formatTokens(contextWindow)} (${percentRounded}%)`;

  return { display, percent };
}

export function calculateSessionSpend(ctx: any): number {
  let spend = 0;

  for (const entry of ctx.sessionManager.getEntries()) {
    if (
      entry.type === "message" &&
      (entry as any).message?.role === "assistant"
    ) {
      const usage = (entry as any).message?.usage;
      if (usage) spend += usage.cost?.total ?? 0;
    }
  }

  return spend;
}

export function getModelInfo(ctx: any): string {
  const model = ctx.model;
  return model ? `${model.provider}/${model.id}` : "no-model";
}

export function buildToolIcons(theme: Theme): string {
  const toolStatus = getToolStatus();

  return TOOL_ORDER.map((tool) => {
    const enabled = toolStatus.get(tool) ?? true;
    const icon = enabled ? TOOL_ICONS[tool].enabled : TOOL_ICONS[tool].disabled;
    return theme.fg("dim", icon);
  }).join(" ");
}
