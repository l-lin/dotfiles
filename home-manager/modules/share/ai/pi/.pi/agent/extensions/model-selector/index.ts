/**
 * Extension to switch between multiple configured models in a round-robin fashion.
 * Comes with a command and a keyboard shortcut to trigger the switch.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import {
  formatModelReference,
  normalizeKeybind,
  resolveConfiguredModel,
  rotateModels,
} from "./model-switching.js";
import { loadSettings, saveSettings } from "./settings.js";

async function switchConfiguredModel(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): Promise<void> {
  const settings = loadSettings();

  if (!settings.enabled) {
    ctx.ui.notify("model-selector is disabled in settings.json", "warning");
    return;
  }

  if (settings.models.length === 0) {
    ctx.ui.notify(
      "No models configured in extensionSettings.modelSelector.models.",
      "warning",
    );
    return;
  }

  const previousModelReference = formatModelReference(ctx.model);
  const rotatedModels = rotateModels(settings.models, previousModelReference);
  const nextModelReference = rotatedModels[0];

  let nextModel;
  try {
    nextModel = resolveConfiguredModel(ctx.modelRegistry, nextModelReference);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    ctx.ui.notify(message, "error");
    return;
  }

  const success = await pi.setModel(nextModel);
  if (!success) {
    ctx.ui.notify(
      `Cannot switch to ${nextModelReference}: no API key available.`,
      "error",
    );
    return;
  }

  saveSettings({ ...settings, models: rotatedModels });
  ctx.ui.notify(
    `Switched model: ${previousModelReference ?? "none"} → ${nextModelReference}`,
    "info",
  );
}

export default function modelSelectorExtension(pi: ExtensionAPI): void {
  const settings = loadSettings();

  if (!settings.enabled) return;

  const switchDescription = "Switch to the next configured model";

  async function switchHandler(ctx: ExtensionContext): Promise<void> {
    await switchConfiguredModel(pi, ctx);
  }

  pi.registerCommand("cmd:switch-model", {
    description: switchDescription,
    handler: async (_args, ctx) => {
      await switchHandler(ctx);
    },
  });

  pi.registerShortcut(normalizeKeybind(settings.keybind), {
    description: switchDescription,
    handler: switchHandler,
  });
}
