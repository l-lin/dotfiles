/**
 * Self-Review Extension
 *
 * Automates self-review by repeatedly prompting the agent to review its own work.
 *
 * Usage:
 * - `/self-review` - Start review loop with default 3 iterations
 * - `/self-review 5` - Start review loop with 5 iterations
 * - `/self-review-stop` - Manually stop the loop
 *
 * src: https://github.com/nicobailon/pi-review-loop
 * Adapted with the following changes:
 * - simpler implementation (no need to install anything)
 * - renamed to self-review
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let active = false;
  let currentIteration = 0;
  let maxIterations = 3;

  const EXIT_PATTERNS = [
    /no\s+(\w+\s+)?issues?\s+found/i,
    /no\s+(\w+\s+)?bugs?\s+found/i,
    /(?:^|\n)\s*(?:looks\s+good|all\s+good)[\s.,!]*(?:$|\n)/im,
  ];

  const ISSUES_FIXED_PATTERNS = [
    /fixed\s+\d+\s+issues?/i,
    /fixed\s+(the\s+)?(following|these|this|issues?|bugs?)/i,
    /ready\s+for\s+(another|the\s+next)\s+review/i,
  ];

  const REVIEW_PROMPT = `Review all the code you just wrote with fresh eyes. Look for:

- Obvious bugs, errors, or typos
- Edge cases not handled
- Forgotten error handling
- Dead code or unused parameters
- Unnecessary complexity

**Response format:**
- If you find ANY issues: fix them, then end with "Fixed [N] issue(s). Ready for another review."
- If you find ZERO issues: describe what you verified, then conclude with "No issues found."

Think deeply before responding. Don't rush to a verdict.`;

  function updateStatus(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;
    if (active) {
      ctx.ui.setStatus("self-review", `Self-review (${currentIteration + 1}/${maxIterations})`);
    } else {
      ctx.ui.setStatus("self-review", undefined);
    }
  }

  function exitLoop(ctx: ExtensionContext, reason: string) {
    active = false;
    currentIteration = 0;
    updateStatus(ctx);
    if (ctx.hasUI) ctx.ui.notify(`Self-review ended: ${reason}`, "info");
  }

  function enterLoop(ctx: ExtensionContext, iterations: number) {
    active = true;
    currentIteration = 0;
    maxIterations = iterations;
    updateStatus(ctx);
    if (ctx.hasUI) ctx.ui.notify("Self-review started", "info");
  }

  function resetState() {
    active = false;
    currentIteration = 0;
    maxIterations = 3;
  }

  // Reset state on session start/switch
  pi.on("session_start", async () => {
    resetState();
  });

  pi.on("session_switch", async () => {
    resetState();
  });

  // Cancel loop on user input
  pi.on("input", async (event, ctx) => {
    if (!ctx.hasUI) return { action: "continue" as const };

    if (active && event.source === "interactive") {
      exitLoop(ctx, "user interrupted");
    }

    return { action: "continue" as const };
  });

  // Main loop logic
  pi.on("agent_end", async (event, ctx) => {
    if (!ctx.hasUI || !active) return;

    const assistantMessages = event.messages.filter((m) => m.role === "assistant");
    const lastMsg = assistantMessages[assistantMessages.length - 1];

    if (!lastMsg) {
      exitLoop(ctx, "aborted");
      return;
    }

    const text = lastMsg.content
      .filter((c): c is { type: "text"; text: string } => c.type === "text")
      .map((c) => c.text)
      .join("\n");

    if (!text.trim()) {
      exitLoop(ctx, "aborted");
      return;
    }

    const hasExit = EXIT_PATTERNS.some((p) => p.test(text));
    const hasFixed = ISSUES_FIXED_PATTERNS.some((p) => p.test(text));

    // Exit only if "no issues" AND no fixes were made
    if (hasExit && !hasFixed) {
      exitLoop(ctx, "no issues found");
      return;
    }

    currentIteration++;
    if (currentIteration >= maxIterations) {
      exitLoop(ctx, `max iterations (${maxIterations}) reached`);
      return;
    }

    updateStatus(ctx);
    pi.sendUserMessage(REVIEW_PROMPT, { deliverAs: "followUp" });
  });

  // Main command
  pi.registerCommand("self-review", {
    description: "Start self-review loop (default: 3 iterations)",
    handler: async (args, ctx) => {
      if (active) {
        ctx.ui.notify("Self-review already active", "info");
        return;
      }

      const n = parseInt(args?.trim() || "3", 10);
      const iterations = isNaN(n) || n < 1 ? 3 : n;

      enterLoop(ctx, iterations);
      pi.sendUserMessage(REVIEW_PROMPT);
    },
  });

  // Stop command
  pi.registerCommand("self-review-stop", {
    description: "Stop self-review loop",
    handler: async (_args, ctx) => {
      if (!active) {
        ctx.ui.notify("Self-review not active", "info");
        return;
      }
      exitLoop(ctx, "manual stop");
    },
  });
}
