/**
 * Dummy pi extension to export toggle tools functionality.
 */

import { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export type ToggleToolsArgs = {
  toolName: string;
  enabled: boolean;
}

export function updateActiveTools(pi: ExtensionAPI, args: ToggleToolsArgs) {
  const current = pi.getActiveTools();
  let updated: string[];
  if (args.enabled) {
    updated = current.includes(args.toolName)
      ? current
      : [...current, args.toolName];
  } else {
    updated = current.filter((t) => t !== args.toolName);
  }
  pi.setActiveTools(updated);
}

export default function (_pi: ExtensionAPI) {}
