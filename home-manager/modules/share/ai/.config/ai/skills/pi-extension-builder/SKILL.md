---
name: pi-extension-builder
description: Create pi extensions (TypeScript modules) with tools, commands, events, or UI components. Use when user says "create pi extension", "build extension for pi", "extend pi", or wants to customize pi agent behavior.
---

# Pi Extension Builder

Build TypeScript extensions for the pi coding agent with proper structure, API usage, and testing.

## Step 1: Gather Requirements

Ask the user using `AskUserQuestion`:

**Question 1**: Extension name and purpose

- Extension name (kebab-case, e.g., "github-pr-helper")
- What should this extension do?

**Question 2**: Extension type

- Custom tool (LLM-callable function with parameters)
- Command (`/my-command` for user to invoke)
- Event handler (intercept tool calls, session events)
- UI component (widget, status line, footer)
- Combination of the above

**Question 3**: Capabilities (based on type selected)

For **Custom Tools**:

- What parameters does it need?
- Does it need user interaction (`ctx.ui.select/input/confirm`)?
- Custom rendering in TUI (`renderCall/renderResult`)?
- State persistence (`pi.appendEntry`)?

For **Commands**:

- Command arguments?
- Tab completions?

For **Events**:

- Which events to subscribe? (`session_start`, `tool_call`, `message_sent`)

For **UI**:

- Widget placement? (top-right, bottom-left, etc.)
- Custom footer content?

## Step 2: Create Extension File

Create at:

- Project-specific: `<project>/.pi/extensions/<name>.ts`
- Global: `~/.pi/agent/extensions/<name>.ts`

## Step 3: Generate Code

Use templates below based on type. All extensions:

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
  // Add more parameters as needed
});

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "my_tool",
    label: "MyTool",
    description: "What this tool does for the LLM",
    parameters: MyToolParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      // Tool logic here
      const result = `Processed: ${params.input}`;

      return {
        content: [{ type: "text", text: result }],
      };
    },
  });
}
```

### Template 2: Interactive Tool

With user prompts (`ctx.ui.select`, `ctx.ui.input`, `ctx.ui.confirm`):

```typescript
async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
  if (!ctx.hasUI) {
    return { content: [{ type: "text", text: "UI not available" }] };
  }

  const choice = await ctx.ui.select(
    "Choose an option",
    ["Option 1", "Option 2", "Option 3"]
  );

  const userInput = await ctx.ui.input("Enter something");
  const confirmed = await ctx.ui.confirm("Proceed?");

  return {
    content: [{ type: "text", text: `Selected: ${choice}` }]
  };
}
```

### Template 3: Custom Rendering

```typescript
pi.registerTool({
  name: "my_tool",
  // ... other fields ...

  async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
    const result = { status: "success", data: params.input };
    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
      details: result, // Pass to renderResult
    };
  },

  renderCall(args, theme) {
    const text = theme.fg("toolTitle", theme.bold("MyTool "));
    text += theme.fg("muted", args.input);
    return new Text(text, 0, 0);
  },

  renderResult(result, _opts, theme) {
    if (result.details?.status === "success") {
      return new Text(theme.fg("success", "✓ Done"), 0, 0);
    }
    return new Text(result.content[0]?.text || "", 0, 0);
  },
});
```

### Template 4: Command

```typescript
pi.registerCommand({
  name: "mycommand",
  description: "What this command does",

  async execute(args, ctx) {
    // Command logic
    ctx.ui.notify(`Executed with: ${args.join(" ")}`, "info");
  },

  complete(partial) {
    // Tab completions
    return ["option1", "option2"].filter((o) => o.startsWith(partial));
  },
});
```

### Template 5: Event Handler

```typescript
pi.on("tool_call", async (event, ctx) => {
  // Intercept tool calls before execution
  if (isToolCallEventType("bash", event)) {
    if (event.input.command.includes("rm -rf")) {
      ctx.ui.notify("🛑 Dangerous command blocked", "warning");
      return { block: true, reason: "Safety check failed" };
    }
  }
  return undefined; // Allow
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

Use the `tmux` skill to test:

```bash
# Launch pi with extension
pi --models "github-copilot/gpt-4o" -e ./path/to/extension.ts

# Or if pi is running, reload:
/reload
```

Verify:

1. Extension loads without errors
2. Tool/command appears in help
3. Functionality works as expected
4. Hot reload with `/reload` picks up changes

## Key APIs

| API                           | Purpose             |
| ----------------------------- | ------------------- |
| `pi.registerTool()`           | LLM-callable tools  |
| `pi.registerCommand()`        | User `/commands`    |
| `pi.on(event, handler)`       | Lifecycle hooks     |
| `ctx.ui.select/input/confirm` | User prompts        |
| `ctx.ui.setWidget()`          | Status display      |
| `ctx.ui.notify()`             | Notifications       |
| `pi.sendMessage()`            | Inject LLM messages |
| `pi.appendEntry()`            | Persist state       |

See ./reference.md for complete API documentation.

## Output

After creating the extension:

- Show file path
- Provide test command
- List verification steps
