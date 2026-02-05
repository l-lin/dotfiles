# Pi Extension API Reference

Complete reference for `@mariozechner/pi-coding-agent` extension development.

## Core Types

### ExtensionAPI

Main interface passed to extension default export:

```typescript
export default function (pi: ExtensionAPI) {
  // Extension code
}
```

**Methods:**

- `registerTool(config: ToolConfig)` - Register LLM-callable tool
- `registerCommand(config: CommandConfig)` - Register user command
- `on(event: EventType, handler: EventHandler)` - Subscribe to events
- `sendMessage(message: Message)` - Inject message into conversation
- `appendEntry(entry: Entry)` - Persist state to session file

### ExtensionContext

Provided in tool `execute()`, command `execute()`, and event handlers:

```typescript
async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionContext) {
  // ...
}
```

**Properties:**

- `cwd: string` - Current working directory
- `hasUI: boolean` - Whether UI is available
- `sessionManager: SessionManager` - Session file access
- `ui: UIContext` - UI interaction methods

**UI Methods (`ctx.ui.*`):**

- `select(prompt: string, options: string[]): Promise<string>` - Show selection list
- `input(prompt: string, initial?: string): Promise<string>` - Text input
- `confirm(prompt: string): Promise<boolean>` - Yes/no prompt
- `notify(message: string, level: "info" | "warning" | "error")` - Show notification
- `setWidget(config: WidgetConfig)` - Display widget
- `custom<T>(renderer: CustomRenderer): Promise<T>` - Full custom TUI

### Tool Configuration

```typescript
pi.registerTool({
  name: string;              // Tool name (snake_case)
  label?: string;            // Display name
  description: string;       // What it does (for LLM)
  parameters: TypeBoxSchema; // @sinclair/typebox schema

  execute(
    toolCallId: string,
    params: T,
    signal: AbortSignal,
    onUpdate: (update: ToolUpdate) => void,
    ctx: ExtensionContext
  ): Promise<ToolResult>;

  // Optional custom rendering
  renderCall?(args: unknown, theme: Theme): Text;
  renderResult?(result: ToolResult, opts: RenderOpts, theme: Theme): Text;
});
```

**ToolResult:**

```typescript
{
  content: Array<{ type: "text", text: string }>;
  details?: unknown;  // Passed to renderResult
}
```

### Command Configuration

```typescript
pi.registerCommand({
  name: string;        // Command name (no slash)
  description: string; // Help text

  execute(
    args: string[],
    ctx: ExtensionContext
  ): Promise<void>;

  complete?(partial: string): string[];  // Tab completions
});
```

### Event Types

Subscribe with `pi.on(event, handler)`:

**Events:**

- `"session_start"` - Session initialized
- `"session_end"` - Session ending
- `"tool_call"` - Before tool execution
- `"message_sent"` - After LLM sends message
- `"message_received"` - User message received

**Tool Call Event:**

```typescript
pi.on("tool_call", async (event: ToolCallEvent, ctx) => {
  // Check tool type
  if (isToolCallEventType("bash", event)) {
    const command = event.input.command;
    // Analyze and potentially block
    return { block: true, reason: "Not allowed" };
  }
  return undefined; // Allow
});
```

**Block Response:**

```typescript
{
  block: true;
  reason: string;
}
```

**Helper:**

```typescript
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

isToolCallEventType("bash", event); // true if bash tool
isToolCallEventType("read", event); // true if read tool
```

## TypeBox Schemas

Use `@sinclair/typebox` for parameter schemas:

```typescript
import { Type } from "@sinclair/typebox";

const Schema = Type.Object({
  required: Type.String({ description: "Required field" }),
  optional: Type.Optional(Type.String({ description: "Optional" })),
  number: Type.Number({ minimum: 0, maximum: 100 }),
  array: Type.Array(Type.String()),
  enum: Type.Union([Type.Literal("option1"), Type.Literal("option2")]),
});
```

## Custom UI Rendering

### Basic Components

```typescript
import { Text } from "@mariozechner/pi-tui";

new Text(content: string, x: number, y: number);
```

### Theme Methods

```typescript
theme.fg(color: ColorName, text: string): string;
theme.bg(color: ColorName, text: string): string;
theme.bold(text: string): string;
```

**Colors:**

- `"text"` - Normal text
- `"muted"` - Dimmed text
- `"dim"` - Very dimmed
- `"accent"` - Highlight color
- `"success"` - Green
- `"warning"` - Yellow
- `"error"` - Red
- `"toolTitle"` - Tool name color
- `"selectedBg"` - Selection background

### Custom TUI

Full control with `ctx.ui.custom()`:

```typescript
const result = await ctx.ui.custom<ResultType>((tui, theme, appKb, done) => {
  let state = initialState;

  const handleInput = (data: string) => {
    // Handle keyboard input
    if (data === "\x1b") {
      // Escape
      done(null);
    }
  };

  const render = (width: number): string[] => {
    const lines: string[] = [];
    lines.push(theme.fg("accent", "Custom UI"));
    // Add more lines...
    return lines;
  };

  return {
    render,
    handleInput,
    invalidate: () => {
      /* force re-render */
    },
  };
});
```

## Session Management

```typescript
// Get session file path
const sessionFile = ctx.sessionManager.getSessionFile();

// Persist data
pi.appendEntry({
  type: "custom",
  timestamp: Date.now(),
  data: { key: "value" },
});
```

## Editor Utilities

```typescript
import { Editor, getEditorKeybindings } from "@mariozechner/pi-tui";

const kb = getEditorKeybindings();

// Check keybindings
kb.matches(data, "selectUp"); // Arrow up
kb.matches(data, "selectDown"); // Arrow down
kb.matches(data, "selectConfirm"); // Enter
kb.matches(data, "selectCancel"); // Escape

// Create editor
const editor = new Editor(tui, theme);
editor.onSubmit = (text) => {
  // Handle submission
};
editor.handleInput(data);
const lines = editor.render(width);
```

## Common Patterns

### Error Handling

```typescript
async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
  if (!ctx.hasUI) {
    return { content: [{ type: "text", text: "UI required" }] };
  }

  try {
    const result = await doWork(params);
    return { content: [{ type: "text", text: result }] };
  } catch (err) {
    return {
      content: [{ type: "text", text: `Error: ${err.message}` }]
    };
  }
}
```

### Multi-Question Flow

```typescript
const name = await ctx.ui.input("Name?");
const options = await ctx.ui.select("Choose", ["A", "B", "C"]);
const confirmed = await ctx.ui.confirm(`Create ${name} with ${options}?`);

if (!confirmed) {
  return { content: [{ type: "text", text: "Cancelled" }] };
}
```

### State Persistence

```typescript
pi.on("session_start", async (_event, ctx) => {
  // Load state from session file
  const sessionFile = ctx.sessionManager.getSessionFile();
  if (sessionFile) {
    const data = JSON.parse(fs.readFileSync(sessionFile, "utf8"));
    // Restore state
  }
});

// Later: persist state
pi.appendEntry({
  type: "extension_state",
  data: { counter: 42 },
});
```

### Async Operations with Progress

```typescript
async execute(_toolCallId, params, _signal, onUpdate, ctx) {
  onUpdate({ status: "Starting..." });

  const results = [];
  for (let i = 0; i < items.length; i++) {
    onUpdate({ status: `Processing ${i + 1}/${items.length}` });
    results.push(await processItem(items[i]));
  }

  return { content: [{ type: "text", text: `Processed ${results.length}` }] };
}
```

## Examples from Codebase

### Ask User Question Extension

See: `~/.pi/agent/extensions/ask-user-question.ts`

- Multi-question flow with tabs
- Custom TUI with selection
- Editor integration for text input
- Custom rendering

### Pre-Tool Safety Extension

See: `~/.pi/agent/extensions/pre-tool-safety.ts`

- Event interception (`tool_call`)
- Blocking dangerous operations
- External script integration (Ruby)
- Notifications

## Testing

```bash
# Load extension
pi -e ./my-extension.ts

# Hot reload
/reload

# Debug mode
SAFETY_HOOK_DEBUG=1 pi -e ./extension.ts
```

## TypeScript Imports

```typescript
// Core API
import type {
  ExtensionAPI,
  ExtensionContext,
  ToolCallEvent,
} from "@mariozechner/pi-coding-agent";

import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

// TUI components
import {
  Editor,
  Text,
  Key,
  matchesKey,
  getEditorKeybindings,
  truncateToWidth,
} from "@mariozechner/pi-tui";

// Schema validation
import { Type } from "@sinclair/typebox";

// Node.js as needed
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
```
