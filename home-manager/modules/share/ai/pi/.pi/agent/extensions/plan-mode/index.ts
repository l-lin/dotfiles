/**
 * Plan Mode Extension
 *
 * Read-only exploration mode for safe code analysis.
 * When enabled, only read-only tools are available.
 *
 * Features:
 * - /plan command or Ctrl+Alt+P to toggle
 * - Bash restricted to allowlisted read-only commands
 * - Extracts numbered plan steps from "Plan:" sections
 * - plan_todos tool for step completion tracking
 * - Progress tracking widget during execution
 */

import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import { StringEnum } from "@mariozechner/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import {
  extractTodoItems,
  isSafeCommand,
  type TodoItem,
} from "./utils.js";

// Type guard for assistant messages
function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
  return m.role === "assistant" && Array.isArray(m.content);
}

// Extract text content from an assistant message
function getTextContent(message: AssistantMessage): string {
  return message.content
    .filter((block): block is TextContent => block.type === "text")
    .map((block) => block.text)
    .join("\n");
}

export default function planModeExtension(pi: ExtensionAPI): void {
  let planModeEnabled = false;
  let executionMode = false;
  let todoItems: TodoItem[] = [];

  const WRITE_TOOLS = ["edit", "write"];

  // Plan mode: drop write tools, inject plan_todos
  const toPlanMode = () => [
    ...new Set([...pi.getActiveTools().filter((t) => !WRITE_TOOLS.includes(t)), "plan_todos"]),
  ];
  // Execution mode: restore write tools, keep plan_todos
  const toExecutionMode = () => [
    ...new Set([...pi.getActiveTools(), ...WRITE_TOOLS, "plan_todos"]),
  ];
  // Normal mode: restore write tools, drop plan_todos
  const toNormalMode = () => [
    ...new Set([...pi.getActiveTools().filter((t) => t !== "plan_todos"), ...WRITE_TOOLS]),
  ];

  pi.registerFlag("plan", {
    description: "Start in plan mode (read-only exploration)",
    type: "boolean",
    default: false,
  });

  function updateStatus(ctx: ExtensionContext): void {
    // Footer status
    if (executionMode && todoItems.length > 0) {
      const completed = todoItems.filter((t) => t.completed).length;
      ctx.ui.setStatus(
        "plan-mode",
        ctx.ui.theme.fg("accent", ` ${completed}/${todoItems.length}`),
      );
    } else if (planModeEnabled) {
      ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("warning", "⏸ plan"));
    } else {
      ctx.ui.setStatus("plan-mode", undefined);
    }

    // Widget showing todo list
    if (executionMode && todoItems.length > 0) {
      const lines = todoItems.map((item) => {
        if (item.completed) {
          return (
            ctx.ui.theme.fg("success", "☑ ") +
            ctx.ui.theme.fg("muted", ctx.ui.theme.strikethrough(item.text))
          );
        }
        return `${ctx.ui.theme.fg("muted", "☐ ")}${item.text}`;
      });
      ctx.ui.setWidget("plan-todos", lines);
    } else {
      ctx.ui.setWidget("plan-todos", undefined);
    }
  }

  function togglePlanMode(ctx: ExtensionContext): void {
    planModeEnabled = !planModeEnabled;
    executionMode = false;
    todoItems = [];

    if (planModeEnabled) {
      pi.setActiveTools(toPlanMode());
    } else {
      pi.setActiveTools(toNormalMode());
    }
    updateStatus(ctx);
  }

  function persistState(): void {
    pi.appendEntry("plan-mode", {
      enabled: planModeEnabled,
      todos: todoItems,
      executing: executionMode,
    });
  }

  pi.registerTool({
    name: "plan_todos",
    label: "Plan Todos",
    description:
      "List and manage plan todo items. Use 'list' to view all steps and their status. " +
      "Use 'complete' or 'uncomplete' to mark a step by its number.",
    parameters: Type.Object({
      action: StringEnum(["list", "complete", "uncomplete"] as const, {
        description: "Action to perform",
      }),
      step: Type.Optional(
        Type.Number({ description: "Step number (required for complete/uncomplete)" }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (params.action === "list") {
        if (todoItems.length === 0) {
          return { content: [{ type: "text", text: "No todos yet." }], details: {} };
        }
        const list = todoItems
          .map((t) => `${t.step}. [${t.completed ? "x" : " "}] ${t.text}`)
          .join("\n");
        return { content: [{ type: "text", text: list }], details: { items: todoItems } };
      }

      if (params.action === "complete" || params.action === "uncomplete") {
        if (params.step == null) {
          return {
            content: [{ type: "text", text: "Error: step number is required." }],
            details: {},
            isError: true,
          };
        }
        const item = todoItems.find((t) => t.step === params.step);
        if (!item) {
          return {
            content: [{ type: "text", text: `Step ${params.step} not found.` }],
            details: {},
            isError: true,
          };
        }
        item.completed = params.action === "complete";
        updateStatus(ctx);
        persistState();
        return {
          content: [
            {
              type: "text",
              text: `Step ${item.step} marked as ${item.completed ? "complete ✓" : "incomplete"}.`,
            },
          ],
          details: { items: todoItems },
        };
      }

      return { content: [{ type: "text", text: "Unknown action." }], details: {}, isError: true };
    },
  });

  pi.registerCommand("plan", {
    description: "Toggle plan mode (read-only exploration)",
    handler: async (_args, ctx) => togglePlanMode(ctx),
  });

  pi.registerCommand("todos", {
    description: "Show current plan todo list",
    handler: async (_args, ctx) => {
      if (todoItems.length === 0) {
        ctx.ui.notify("No todos. Create a plan first with /plan", "info");
        return;
      }
      const list = todoItems
        .map(
          (item, i) => `${i + 1}. ${item.completed ? "✓" : "○"} ${item.text}`,
        )
        .join("\n");
      ctx.ui.notify(`Plan Progress:\n${list}`, "info");
    },
  });

  // Block destructive bash commands in plan mode
  pi.on("tool_call", async (event) => {
    if (!planModeEnabled || event.toolName !== "bash") return;

    const command = event.input.command as string;
    if (!isSafeCommand(command)) {
      return {
        block: true,
        reason: `Plan mode: command blocked (not allowlisted). Use /plan to disable plan mode first.\nCommand: ${command}`,
      };
    }
  });

  // Filter out stale plan mode context when not in plan mode
  pi.on("context", async (event) => {
    if (planModeEnabled) return;

    return {
      messages: event.messages.filter((m) => {
        const msg = m as AgentMessage & { customType?: string };
        if (msg.customType === "plan-mode-context") return false;
        if (msg.role !== "user") return true;

        const content = msg.content;
        if (typeof content === "string") {
          return !content.includes("[PLAN MODE ACTIVE]");
        }
        if (Array.isArray(content)) {
          return !content.some(
            (c) =>
              c.type === "text" &&
              (c as TextContent).text?.includes("[PLAN MODE ACTIVE]"),
          );
        }
        return true;
      }),
    };
  });

  // Inject plan/execution context before agent starts
  pi.on("before_agent_start", async () => {
    if (planModeEnabled) {
      return {
        message: {
          customType: "plan-mode-context",
          content: `[PLAN MODE ACTIVE]
You are in plan mode - a read-only exploration mode for safe code analysis.

Restrictions:
- You can only use: ${pi.getActiveTools().join(", ")}
- You CANNOT use: edit, write (file modifications are disabled)
- Bash is restricted to an allowlist of read-only commands

Ask clarifying questions using the AskUserQuestion tool.
Use the plan_todos tool to list and manage plan steps.
Use brave-search skill via bash for web research.

Create a detailed numbered plan under a "Plan:" header:

Plan:
1. First step description
2. Second step description
...

Do NOT attempt to make changes - just describe what you would do.`,
          display: false,
        },
      };
    }

    if (executionMode && todoItems.length > 0) {
      const remaining = todoItems.filter((t) => !t.completed);
      const todoList = remaining.map((t) => `${t.step}. ${t.text}`).join("\n");
      return {
        message: {
          customType: "plan-execution-context",
          content: `[EXECUTING PLAN - Full tool access enabled]

Remaining steps:
${todoList}

Execute each step in order.
After completing a step, call plan_todos with action "complete" and the step number.
You can call plan_todos with action "list" at any time to check remaining steps.`,
          display: false,
        },
      };
    }
  });

  // Handle plan completion and plan mode UI
  pi.on("agent_end", async (event, ctx) => {
    // Check if execution is complete
    if (executionMode && todoItems.length > 0) {
      if (todoItems.every((t) => t.completed)) {
        const completedList = todoItems.map((t) => `~~${t.text}~~`).join("\n");
        pi.sendMessage(
          {
            customType: "plan-complete",
            content: `**Plan Complete!** ✓\n\n${completedList}`,
            display: true,
          },
          { triggerTurn: false },
        );
        executionMode = false;
        todoItems = [];
        pi.setActiveTools(toNormalMode());
        updateStatus(ctx);
        persistState(); // Save cleared state so resume doesn't restore old execution mode
      }
      return;
    }

    if (!planModeEnabled || !ctx.hasUI) return;

    // Extract todos from last assistant message
    const lastAssistant = [...event.messages]
      .reverse()
      .find(isAssistantMessage);
    if (lastAssistant) {
      const extracted = extractTodoItems(getTextContent(lastAssistant));
      if (extracted.length > 0) {
        todoItems = extracted;
      }
    }

    // Show plan steps and prompt for next action
    if (todoItems.length > 0) {
      const todoListText = todoItems
        .map((t, i) => `${i + 1}. ☐ ${t.text}`)
        .join("\n");
      pi.sendMessage(
        {
          customType: "plan-todo-list",
          content: `**Plan Steps (${todoItems.length}):**\n\n${todoListText}`,
          display: true,
        },
        { triggerTurn: false },
      );
    }

    const choice = await ctx.ui.select("Plan mode - what next?", [
      todoItems.length > 0
        ? "Execute the plan (track progress)"
        : "Execute the plan",
      "Stay in plan mode",
      "Refine the plan",
    ]);

    if (choice?.startsWith("Execute")) {
      planModeEnabled = false;
      executionMode = todoItems.length > 0;
      pi.setActiveTools(executionMode ? toExecutionMode() : toNormalMode());
      updateStatus(ctx);

      const execMessage =
        todoItems.length > 0
          ? `Execute the plan. Start with: ${todoItems[0].text}`
          : "Execute the plan you just created.";
      pi.sendMessage(
        {
          customType: "plan-mode-execute",
          content: execMessage,
          display: true,
        },
        { triggerTurn: true },
      );
    } else if (choice === "Refine the plan") {
      const refinement = await ctx.ui.editor("Refine the plan:", "");
      if (refinement?.trim()) {
        pi.sendUserMessage(refinement.trim());
      }
    }
  });

  // Clear all plan state when starting a fresh session
  pi.on("session_switch", async (event, ctx) => {
    if (event.reason !== "new") return;
    planModeEnabled = false;
    executionMode = false;
    todoItems = [];
    pi.setActiveTools(toNormalMode());
    updateStatus(ctx);
  });

  // Restore state on session start/resume
  pi.on("session_start", async (_event, ctx) => {
    if (pi.getFlag("plan") === true) {
      planModeEnabled = true;
    }

    const entries = ctx.sessionManager.getEntries();

    // Restore persisted state
    const planModeEntry = entries
      .filter(
        (e: { type: string; customType?: string }) =>
          e.type === "custom" && e.customType === "plan-mode",
      )
      .pop() as
      | { data?: { enabled: boolean; todos?: TodoItem[]; executing?: boolean } }
      | undefined;

    if (planModeEntry?.data) {
      planModeEnabled = planModeEntry.data.enabled ?? planModeEnabled;
      todoItems = planModeEntry.data.todos ?? todoItems;
      executionMode = planModeEntry.data.executing ?? executionMode;
    }

    if (planModeEnabled) {
      pi.setActiveTools(toPlanMode());
    } else if (executionMode) {
      pi.setActiveTools(toExecutionMode());
    } else {
      pi.setActiveTools(toNormalMode());
    }
    updateStatus(ctx);
  });
}
