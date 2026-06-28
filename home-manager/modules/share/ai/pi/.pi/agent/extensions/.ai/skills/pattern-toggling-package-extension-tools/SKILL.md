---
name: pattern-toggling-package-extension-tools
description: Use when a Pi extension must enable or disable tools that come from another installed extension or package, especially when the tool definitions should disappear from prompts without disabling slash commands or forking the upstream package.
---

# Toggling Package Extension Tools

## Overview

Use Pi's active tool list as the switch. It removes the target tool definitions from later prompts, but leaves the package loaded.

## Pattern

1. Persist your own enabled flag. Do not try to mutate the upstream package.
2. Call `pi.getAllTools()` and collect names whose `sourceInfo.source` matches the package, for example `npm:pi-mcp-adapter`.
3. On `session_start`, apply the saved state with `pi.setActiveTools(...)`. The prompt is built from the active tool list, so waiting until later is too late.
4. When disabling, remove only the matching tool names.
5. When re-enabling, merge the matching tool names back in without dropping other active tools or adding duplicates.
6. If footer or widget state depends on the toggle, emit a companion event such as `mcp-adapter:state-changed`.

## What This Does Not Do

This does not unload the package. Its commands, runtime initialization, or status handlers may still run. It only removes tools from the active prompt surface.

## Minimal Example

```ts
const source = "npm:pi-mcp-adapter";

function getPackageToolNames(pi: Pick<ExtensionAPI, "getAllTools">): string[] {
  return pi
    .getAllTools()
    .filter((tool) => tool.sourceInfo.source === source)
    .map((tool) => tool.name);
}

function applyEnabledState(
  pi: Pick<
    ExtensionAPI,
    "getAllTools" | "getActiveTools" | "setActiveTools" | "events"
  >,
  enabled: boolean,
) {
  const packageToolNames = getPackageToolNames(pi);
  const current = pi.getActiveTools();
  const packageTools = new Set(packageToolNames);

  const next = enabled
    ? [...current, ...packageToolNames.filter((name) => !current.includes(name))]
    : current.filter((name) => !packageTools.has(name));

  pi.setActiveTools(next);
  pi.events.emit("package-tools:state-changed", enabled);
}
```

## Verify

- Saved disabled state removes the package tools on `session_start`
- Toggle off removes every matching tool
- Toggle on restores them
- Slash commands still work because `setActiveTools(...)` only affects tools
- Footer or widget state updates on the companion event
