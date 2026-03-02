---
name: pi-extension-builder
description: Use when user says "create pi extension", "build extension for pi", "extend pi", or wants to customize pi agent behavior with tools, commands, events, or UI components.
---

# Pi Extension Builder

Build TypeScript extensions for the pi coding agent with proper structure, API usage, and testing.

## Step 1: Gather Requirements

Ask the user using `ask-user-question`:

**Question 1**: Extension name and purpose
- Extension name (kebab-case, e.g., `github-pr-helper`)
- What should this extension do?

**Question 2**: Extension type
- Custom tool (LLM-callable function with parameters)
- Command (`/my-command` for user to invoke)
- Event handler (intercept tool calls, session events)
- UI component (widget, status line, footer)
- Combination of the above

**Question 3**: Capabilities (based on type selected)

For **Custom Tools**: parameters needed, user interaction (`ctx.ui.select/input/confirm`), custom TUI rendering, state persistence?

For **Commands**: arguments, tab completions?

For **Events**: which events? (`session_start`, `tool_call`, `message_sent`)

For **UI**: widget placement? (`top-right`, `bottom-left`, etc.)

## Step 2: Create Extension File

- Project-specific: `<project>/.pi/extensions/<name>.ts`
- Global: `~/.pi/agent/extensions/<name>.ts`

## Step 3: Generate Code

All extensions share this base:

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  // Register tools, commands, or event handlers
}
```

### Template 1: Minimal Tool (Most Common)

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const MyToolParams = Type.Object({
  input: Type.String({ description: "Description of the input" }),
});

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "my_tool",          // snake_case
    label: "MyTool",          // display name
    description: "What this tool does for the LLM",
    parameters: MyToolParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      return {
        content: [{ type: "text", text: `Processed: ${params.input}` }],
      };
    },
  });
}
```

### Template 2: Interactive Tool

Always guard with `ctx.hasUI` before calling any `ctx.ui.*` method:

```typescript
async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
  if (!ctx.hasUI) {
    return { content: [{ type: "text", text: "UI not available" }] };
  }

  const choice = await ctx.ui.select("Choose an option", ["Option 1", "Option 2"]);
  const userInput = await ctx.ui.input("Enter something");
  const confirmed = await ctx.ui.confirm("Proceed?");

  return { content: [{ type: "text", text: `Selected: ${choice}` }] };
}
```

### Template 3: Custom Rendering

```typescript
import { Text } from "@mariozechner/pi-tui"; // required import
import { keyHint } from "@mariozechner/pi-coding-agent"; // for keybinding hints

pi.registerTool({
  name: "my_tool",
  // ... other fields ...

  async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
    const result = { status: "success", items: ["item1", "item2"], data: params.input };
    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
      details: result, // passed to renderResult
    };
  },

  renderCall(args, theme) {
    const text = theme.fg("toolTitle", theme.bold("MyTool ")) + theme.fg("muted", args.input);
    return new Text(text, 0, 0);
  },

  // expanded = false → collapsed (minimal, 1–2 lines)
  // expanded = true  → user pressed Ctrl+O to see full detail
  renderResult(result, { expanded, isPartial }, theme) {
    // Streaming: show progress indicator
    if (isPartial) {
      return new Text(theme.fg("warning", "⟳ Processing..."), 0, 0);
    }

    // Errors: always show clearly
    if (result.details?.status === "error") {
      return new Text(theme.fg("error", `✗ ${result.details.error}`), 0, 0);
    }

    // Collapsed (default): single summary line + expand hint
    if (!expanded) {
      const hint = keyHint("expandTools", "to expand");
      return new Text(theme.fg("success", "✓ Done") + theme.fg("muted", ` (${hint})`), 0, 0);
    }

    // Expanded (Ctrl+O): full detail
    let text = theme.fg("success", "✓ Done");
    if (result.details?.items) {
      for (const item of result.details.items) {
        text += "\n  " + theme.fg("dim", item);
      }
    }
    return new Text(text, 0, 0);
  },
});
```

### Template 4: Command

```typescript
pi.registerCommand({
  name: "mycommand",
  description: "What this command does",

  async execute(args, ctx) {
    ctx.ui.notify(`Executed with: ${args.join(" ")}`, "info");
  },

  complete(partial) {
    return ["option1", "option2"].filter((o) => o.startsWith(partial));
  },
});
```

### Template 5: Event Handler

```typescript
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

pi.on("tool_call", async (event, ctx) => {
  if (isToolCallEventType("bash", event)) {
    if (event.input.command.includes("rm -rf")) {
      ctx.ui.notify("🛑 Dangerous command blocked", "warning");
      return { block: true, reason: "Safety check failed" };
    }
  }
  return undefined; // allow
});

pi.on("session_start", (_event, ctx) => {
  ctx.ui.notify("Extension loaded", "info");
});
```

### Template 6: Widget

```typescript
pi.on("session_start", (_event, ctx) => {
  ctx.ui.setWidget({
    content: "📊 Status: Active",
    placement: "top-right",
  });
});
```

## Step 4: Test Extension

**REQUIRED SUB-SKILL:** Use `tmux` for running pi interactively.

```bash
# Launch pi with extension
pi --models "github-copilot/gpt-4o" -e ./path/to/extension.ts

# Hot reload after changes
/reload
```

Verify:
1. Extension loads without errors
2. Tool/command appears in help
3. Functionality works as expected

## Key APIs

| API                           | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| `pi.registerTool()`           | LLM-callable tools                         |
| `pi.registerCommand()`        | User `/commands`                           |
| `pi.on(event, handler)`       | Lifecycle hooks                            |
| `ctx.ui.select/input/confirm` | User prompts                               |
| `ctx.ui.setWidget()`          | Status display                             |
| `ctx.ui.notify()`             | Notifications                              |
| `pi.sendMessage()`            | Inject LLM messages                        |
| `pi.appendEntry()`            | Persist state                              |
| `keyHint(action, desc)`       | Keybinding hint in `renderResult` text     |
| `expanded` (renderResult opt) | `false` = collapsed (minimal), `true` = full detail (Ctrl+O) |
| `isPartial` (renderResult opt)| `true` = tool still streaming, show progress |

See `./reference.md` for complete API documentation.

## Common Mistakes

- **No `ctx.hasUI` guard** — always check `if (!ctx.hasUI)` before any `ctx.ui.*` call
- **Tool name in kebab-case** — tool names must be `snake_case` (`my_tool`, not `my-tool`)
- **Missing `Text` import for custom rendering** — add `import { Text } from "@mariozechner/pi-tui"`
- **Missing `isToolCallEventType` import** — add `import { isToolCallEventType } from "@mariozechner/pi-coding-agent"`
- **Ignoring `expanded` in `renderResult`** — always branch on `expanded`: collapsed = minimal 1-line summary, expanded = full detail
- **Ignoring `isPartial` in `renderResult`** — show a progress indicator when `isPartial` is true (streaming in progress)
- **Missing keybind hint in collapsed view** — use `keyHint("expandTools", "to expand")` so users know Ctrl+O works
- **Unconditional `{ block: true }` in event handler** — always return `undefined` on the allow path
- **Missing entry point** — every extension must have `export default function(pi: ExtensionAPI)`

## Output

After creating the extension:
- Show file path
- Provide test command
- List verification steps
