/**
 * Task Workflow Extension
 *
 * A 4-phase development workflow: Scout → Planning → Implementation → Review
 * Each phase produces artifacts and requires user validation before proceeding.
 *
 * Usage:
 *   /task JIRA-1234              - Start task with ticket ID
 *   /task Fix the login bug      - Start task with description
 *   /task --resume planning JIRA-1234 - Resume from a specific phase
 *   /task --status               - Show current task status
 *   /task --next                 - Manually proceed to next phase
 *
 * Artifacts stored in: .sandbox/tasks/YYYY-MM-DD-JIRA-XXXX-description/
 *   - context.md   (Scout phase)
 *   - plan.md      (Planning phase)
 *   - progress.md  (Implementation & Review phases)
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  ExtensionCommandContext,
} from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

// Types
type Phase = "scout" | "planning" | "implementation" | "review" | "complete";

interface TaskState {
  phase: Phase;
  taskId: string | null;
  description: string;
  artifactDir: string | null;
  saveArtifacts: boolean;
  branchCreated: string | null;
}

interface PhasePrompts {
  scout: string;
  planning: string;
  implementation: string;
  review: string;
}

// Constants
const JIRA_PATTERN = /^[A-Z]+-\d+$/;
const CONTEXT_THRESHOLD = 0.7; // 70% context usage triggers new session suggestion

const PHASE_PROMPTS: PhasePrompts = {
  scout: `# Scout Phase

You are in the SCOUT phase of the task workflow. Your goal is to deeply understand the codebase context for this task.

## Instructions

1. **Understand the request**: Analyze what needs to be done (feature or bug fix)
2. **Explore the codebase**: 
   - Identify affected files and their relationships
   - Understand existing patterns and conventions
   - Map dependencies and integration points
   - Review related tests
3. **Document architecture insights**: Note any patterns, conventions, or constraints
4. **Identify potential challenges**: Flag any risks or complexities
5. **Ask questions to user**: Use the AskUserQuestion tool to the user if there are any points that require clarification

## Output Format

Create a comprehensive context document covering:
- Task summary
- Affected areas (files, modules, systems)
- Existing patterns to follow
- Dependencies and integration points
- Potential challenges or risks
- Questions that need clarification

Be thorough - this context will drive the planning phase.`,

  planning: `# Planning Phase

You are in the PLANNING phase of the task workflow. Based on the scout context, create a detailed implementation plan.

## Instructions

1. **Review the context**: Use the information gathered in the scout phase
2. **Design the solution**: 
   - Define the approach and architecture decisions
   - Break down into concrete, atomic steps
   - Identify test requirements for each step
   - Consider edge cases and error handling
3. **Estimate complexity**: Flag any high-risk areas
4. **Define success criteria**: What does "done" look like?
5. **Ask questions to user**: Use the AskUserQuestion tool to the user if there are any points that require clarification

## Output Format

Create a structured plan with:
- Solution overview
- Step-by-step implementation tasks (numbered)
- Test strategy for each step
- Edge cases to handle
- Success criteria checklist
- Rollback considerations (if applicable)

Each step should be small enough to implement and verify independently.`,

  implementation: `# Implementation Phase

You are in the IMPLEMENTATION phase of the task workflow. Execute the plan step by step.

## Instructions

1. **Follow the plan**: Implement each step in order
2. **Write tests first**: TDD approach - test before implementation
3. **Track progress**: After completing each step, update the progress
4. **Verify continuously**: Run tests after each change
5. **Document changes**: Note what was modified and why

## Progress Tracking

Update the progress with:
- [x] Completed steps with timestamp
- [ ] Remaining steps
- Detailed log of what was done, files modified, any deviations from plan

Mark each step complete as you finish it.`,

  review: `# Review Phase

You are in the REVIEW phase of the task workflow. Verify the implementation is complete and correct.

## Review Checklist

### Technical
- [ ] All tests pass
- [ ] No linter errors
- [ ] No compiler/build errors
- [ ] No console errors or warnings

### Correctness
- [ ] Implementation matches the plan
- [ ] All edge cases are handled
- [ ] No regressions introduced
- [ ] Error handling is appropriate

### Quality
- [ ] Code follows project conventions
- [ ] Naming is clear and consistent
- [ ] No typos in code, comments, or strings
- [ ] Documentation is updated if needed
- [ ] No dead code or debug statements

## Instructions

1. Run the full test suite
2. Run linter/formatter
3. Build the project
4. Review each item in the checklist
5. Document any issues found
6. Fix issues or flag for discussion

Report the final status with all checklist items addressed.`,
};

// Helper functions
function getTodayDate(): string {
  const now = new Date();
  return now.toISOString().split("T")[0];
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .substring(0, 50);
}

function extractTicketFromBranch(branchName: string): string | null {
  const match = branchName.match(/([A-Z]+-\d+)/);
  return match ? match[1] : null;
}

async function getCurrentBranch(pi: ExtensionAPI): Promise<string | null> {
  try {
    const result = await pi.exec("git", ["rev-parse", "--abbrev-ref", "HEAD"], {
      timeout: 5000,
    });
    return result.code === 0 ? result.stdout.trim() : null;
  } catch {
    return null;
  }
}

async function createBranch(
  pi: ExtensionAPI,
  branchName: string,
): Promise<boolean> {
  try {
    const result = await pi.exec("git", ["checkout", "-b", branchName], {
      timeout: 5000,
    });
    return result.code === 0;
  } catch {
    return false;
  }
}

function getArtifactDir(
  cwd: string,
  taskId: string | null,
  description: string,
): string {
  const date = getTodayDate();
  const slug = slugify(description);
  let dirName: string;
  if (taskId && slug) {
    dirName = `${date}-${taskId}-${slug}`;
  } else if (taskId) {
    dirName = `${date}-${taskId}`;
  } else if (slug) {
    dirName = `${date}-${slug}`;
  } else {
    dirName = `${date}-task`;
  }
  return path.join(cwd, ".sandbox", "tasks", dirName);
}

function ensureDir(dir: string): void {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function readArtifact(dir: string, filename: string): string | null {
  const filepath = path.join(dir, filename);
  if (fs.existsSync(filepath)) {
    return fs.readFileSync(filepath, "utf-8");
  }
  return null;
}

function writeArtifact(dir: string, filename: string, content: string): void {
  ensureDir(dir);
  fs.writeFileSync(path.join(dir, filename), content, "utf-8");
}

function findExistingTaskDir(cwd: string, taskId: string): string | null {
  const tasksDir = path.join(cwd, ".sandbox", "tasks");
  if (!fs.existsSync(tasksDir)) return null;

  const dirs = fs.readdirSync(tasksDir);
  const matching = dirs.find((d) => d.includes(taskId));
  return matching ? path.join(tasksDir, matching) : null;
}

function getPhaseArtifact(phase: Phase): string | null {
  switch (phase) {
    case "scout":
      return "context.md";
    case "planning":
      return "plan.md";
    case "implementation":
    case "review":
      return "progress.md";
    default:
      return null;
  }
}

function getNextPhase(phase: Phase): Phase {
  switch (phase) {
    case "scout":
      return "planning";
    case "planning":
      return "implementation";
    case "implementation":
      return "review";
    case "review":
      return "complete";
    default:
      return "complete";
  }
}

function getPhaseName(phase: Phase): string {
  return phase.charAt(0).toUpperCase() + phase.slice(1);
}

// Extension
export default function taskWorkflowExtension(pi: ExtensionAPI): void {
  let state: TaskState = {
    phase: "scout",
    taskId: null,
    description: "",
    artifactDir: null,
    saveArtifacts: false,
    branchCreated: null,
  };

  function resetState(): void {
    state = {
      phase: "scout",
      taskId: null,
      description: "",
      artifactDir: null,
      saveArtifacts: false,
      branchCreated: null,
    };
  }

  function updateStatus(ctx: ExtensionContext): void {
    if (!state.taskId && !state.description) {
      ctx.ui.setStatus("task-workflow", undefined);
      ctx.ui.setWidget("task-workflow", undefined);
      return;
    }

    const phaseEmoji: Record<Phase, string> = {
      scout: " ",
      planning: " ",
      implementation: " ",
      review: " ",
      complete: "󱁖 ",
    };

    const statusText = `${phaseEmoji[state.phase]} ${state.taskId || "task"}: ${getPhaseName(state.phase)}`;
    ctx.ui.setStatus("task-workflow", ctx.ui.theme.fg("accent", statusText));

    // Widget with task info
    const taskLabel =
      state.taskId || state.description.substring(0, 30) || "unnamed";
    const lines = [
      ctx.ui.theme.fg("accent", `Task: ${taskLabel}`),
      ctx.ui.theme.fg("muted", `Phase: ${getPhaseName(state.phase)}`),
    ];
    if (state.artifactDir) {
      lines.push(
        ctx.ui.theme.fg(
          "dim",
          `Artifacts: ${path.basename(state.artifactDir)}`,
        ),
      );
    }
    ctx.ui.setWidget("task-workflow", lines);
  }

  function persistState(): void {
    pi.appendEntry("task-workflow-state", { ...state });
  }

  async function checkContextUsage(ctx: ExtensionContext): Promise<boolean> {
    const usage = ctx.getContextUsage();
    if (!usage) return false;
    return usage.percent >= CONTEXT_THRESHOLD * 100;
  }

  async function handlePhaseTransition(
    ctx: ExtensionCommandContext,
  ): Promise<boolean> {
    const nextPhase = getNextPhase(state.phase);

    if (nextPhase === "complete") {
      ctx.ui.notify("󱁖 Task workflow complete!", "success");
      resetState();
      updateStatus(ctx);
      persistState();
      return true;
    }

    // Check if we should suggest a new session
    const highContextUsage = await checkContextUsage(ctx);

    // Ask for review & edit before proceeding
    const artifact = getPhaseArtifact(state.phase);
    let reviewContent = "";

    if (artifact && state.artifactDir) {
      reviewContent = readArtifact(state.artifactDir, artifact) || "";
    }

    // Show phase summary and ask for modifications
    const choice = await ctx.ui.select(
      `${getPhaseName(state.phase)} phase complete. What next?`,
      [
        `Proceed to ${getPhaseName(nextPhase)} phase`,
        "Edit phase output before proceeding",
        "Abort workflow",
      ],
    );

    if (!choice || choice.includes("Abort")) {
      const saveChoice = await ctx.ui.confirm(
        "Save Progress?",
        "Save current progress before aborting?",
      );
      if (saveChoice && state.artifactDir) {
        ctx.ui.notify(`Progress saved to ${state.artifactDir}`, "info");
      }
      resetState();
      updateStatus(ctx);
      persistState();
      return false;
    }

    if (choice.includes("Edit")) {
      const edited = await ctx.ui.editor(
        `Edit ${getPhaseName(state.phase)} output:`,
        reviewContent,
      );
      if (edited && artifact && state.artifactDir && state.saveArtifacts) {
        writeArtifact(state.artifactDir, artifact, edited);
      }
    }

    // Check if new session needed
    if (highContextUsage) {
      const newSessionChoice = await ctx.ui.confirm(
        "High Context Usage",
        "Context is at 70%+ usage. Start a new session for the next phase? Artifacts will be auto-loaded.",
      );

      if (newSessionChoice) {
        // Prepare handoff
        state.phase = nextPhase;
        persistState();

        const currentSessionFile = ctx.sessionManager.getSessionFile();
        await ctx.newSession({ parentSession: currentSessionFile });

        // Auto-load context for new session
        const contextPrompt = buildPhasePrompt(nextPhase);
        ctx.ui.setEditorText(contextPrompt);
        ctx.ui.notify(
          `New session started. Phase: ${getPhaseName(nextPhase)}`,
          "info",
        );
        return true;
      }
    }

    // Continue in same session
    state.phase = nextPhase;
    updateStatus(ctx);
    persistState();

    // Inject next phase prompt
    const phasePrompt = PHASE_PROMPTS[nextPhase as keyof PhasePrompts];
    if (phasePrompt) {
      pi.sendMessage(
        {
          customType: "task-workflow-phase",
          content: phasePrompt,
          display: false,
        },
        { triggerTurn: true },
      );
    }

    return true;
  }

  function buildPhasePrompt(phase: Phase): string {
    let prompt = PHASE_PROMPTS[phase as keyof PhasePrompts] || "";

    // Add context from previous phases
    if (state.artifactDir) {
      if (phase === "planning") {
        const context = readArtifact(state.artifactDir, "context.md");
        if (context) {
          prompt += `\n\n---\n\n# Context from Scout Phase\n\n${context}`;
        }
      } else if (phase === "implementation") {
        const context = readArtifact(state.artifactDir, "context.md");
        const plan = readArtifact(state.artifactDir, "plan.md");
        if (context) prompt += `\n\n---\n\n# Context\n\n${context}`;
        if (plan) prompt += `\n\n---\n\n# Plan\n\n${plan}`;
      } else if (phase === "review") {
        const plan = readArtifact(state.artifactDir, "plan.md");
        const progress = readArtifact(state.artifactDir, "progress.md");
        if (plan) prompt += `\n\n---\n\n# Plan\n\n${plan}`;
        if (progress) prompt += `\n\n---\n\n# Progress\n\n${progress}`;
      }
    }

    if (state.taskId) {
      prompt = `Task: ${state.taskId}\n\n${prompt}`;
    }
    if (state.description) {
      prompt = `Description: ${state.description}\n\n${prompt}`;
    }

    return prompt;
  }

  // Register command
  pi.registerCommand("task", {
    description:
      "Start or manage a phased task workflow (scout → planning → implementation → review)",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/task requires interactive mode", "error");
        return;
      }

      const trimmedArgs = args.trim();

      // Handle --status flag
      if (trimmedArgs === "--status") {
        if (!state.taskId && !state.description) {
          ctx.ui.notify("No active task", "info");
        } else {
          ctx.ui.notify(
            `Task: ${state.taskId || state.description}\nPhase: ${getPhaseName(state.phase)}\nArtifacts: ${state.artifactDir || "none"}`,
            "info",
          );
        }
        return;
      }

      // Handle --resume flag: /task --resume planning JIRA-1234
      if (trimmedArgs.startsWith("--resume")) {
        const resumeParts = trimmedArgs
          .replace("--resume", "")
          .trim()
          .split(/\s+/);
        const resumePhase = resumeParts[0]?.toLowerCase() as Phase;
        const resumeTaskId = resumeParts[1];
        const validPhases: Phase[] = [
          "scout",
          "planning",
          "implementation",
          "review",
        ];

        if (!resumePhase || !validPhases.includes(resumePhase)) {
          ctx.ui.notify(
            `Usage: /task --resume <phase> [TASK-ID]\nPhases: ${validPhases.join(", ")}`,
            "error",
          );
          return;
        }

        // Find existing task dir - use provided task ID, or fall back to current state
        const taskIdToFind = resumeTaskId || state.taskId;
        if (!state.artifactDir && taskIdToFind) {
          state.artifactDir = findExistingTaskDir(ctx.cwd, taskIdToFind);
          if (resumeTaskId) {
            state.taskId = resumeTaskId;
          }
        }

        if (!state.artifactDir) {
          ctx.ui.notify(
            "No task artifacts found. Specify task ID: /task --resume <phase> TASK-ID",
            "error",
          );
          return;
        }

        // Extract description from artifact dir name if not already set
        // Format: YYYY-MM-DD-TASK-XXX-description or YYYY-MM-DD-description
        if (!state.description && state.artifactDir) {
          const dirName = path.basename(state.artifactDir);
          // Remove date prefix (YYYY-MM-DD-)
          let remainder = dirName.replace(/^\d{4}-\d{2}-\d{2}-/, "");
          // Remove task ID if present
          if (state.taskId) {
            remainder = remainder.replace(
              new RegExp(`^${state.taskId}-?`, "i"),
              "",
            );
          }
          // Convert slug back to readable text
          state.description = remainder.replace(/-/g, " ");
        }

        state.phase = resumePhase;
        state.saveArtifacts = true;
        updateStatus(ctx);
        persistState();

        const prompt = buildPhasePrompt(resumePhase);
        ctx.ui.setEditorText(prompt);
        ctx.ui.notify(
          `Resuming from ${getPhaseName(resumePhase)} phase`,
          "info",
        );
        return;
      }

      // Handle --next flag (proceed to next phase)
      if (trimmedArgs === "--next") {
        if (!state.taskId && !state.description) {
          ctx.ui.notify(
            "No active task. Start one with /task <description>",
            "error",
          );
          return;
        }
        await handlePhaseTransition(ctx);
        return;
      }

      // Start new task
      if (!trimmedArgs) {
        ctx.ui.notify("Usage: /task <JIRA-ID or description>", "error");
        return;
      }

      // Parse task input
      let taskId: string | null = null;
      let description = trimmedArgs;

      if (JIRA_PATTERN.test(trimmedArgs.split(" ")[0])) {
        taskId = trimmedArgs.split(" ")[0];
        const remainingText = trimmedArgs.slice(taskId.length).trim();
        description = remainingText || ""; // Don't duplicate ticket ID as description
      }

      // Check current branch for ticket
      const currentBranch = await getCurrentBranch(pi);
      if (currentBranch) {
        const branchTicket = extractTicketFromBranch(currentBranch);
        if (branchTicket && !taskId) {
          taskId = branchTicket;
        } else if (taskId && branchTicket !== taskId) {
          // Need to create new branch
          const slug = slugify(description);
          const newBranchName = slug ? `${taskId}-${slug}` : taskId;
          ctx.ui.notify(`Creating branch: ${newBranchName}`, "info");
          const created = await createBranch(pi, newBranchName);
          if (created) {
            state.branchCreated = newBranchName;
          } else {
            ctx.ui.notify(
              "Failed to create branch. Continuing on current branch.",
              "warning",
            );
          }
        }
      }

      // Ask about saving artifacts
      const saveChoice = await ctx.ui.confirm(
        "Save Artifacts?",
        "Save phase outputs to .sandbox/tasks/? (Recommended for complex tasks)",
      );

      state.taskId = taskId;
      state.description = description;
      state.saveArtifacts = saveChoice;
      state.phase = "scout";

      if (saveChoice) {
        state.artifactDir = getArtifactDir(ctx.cwd, taskId, description);
        ensureDir(state.artifactDir);
        ctx.ui.notify(
          `Artifacts will be saved to: ${state.artifactDir}`,
          "info",
        );
      }

      updateStatus(ctx);
      persistState();

      // Start scout phase
      const scoutPrompt = buildPhasePrompt("scout");
      pi.sendMessage(
        {
          customType: "task-workflow-phase",
          content: scoutPrompt,
          display: true,
        },
        { triggerTurn: true },
      );

      pi.setSessionName(
        `Task: ${taskId || description.substring(0, 30) || "unnamed"}`,
      );
    },
  });

  // Track phase completion in agent responses
  pi.on("agent_end", async (event, ctx) => {
    if (!state.taskId && !state.description) return;
    if (state.phase === "complete") return;
    if (!ctx.hasUI) return;

    // Look for phase completion signals in the last message
    const messages = event.messages;
    const lastAssistant = [...messages]
      .reverse()
      .find((m) => m.role === "assistant");

    if (!lastAssistant) return;

    const content =
      lastAssistant.content
        ?.filter((c): c is { type: "text"; text: string } => c.type === "text")
        .map((c) => c.text)
        .join("\n") || "";

    // Save artifact if configured
    if (state.saveArtifacts && state.artifactDir) {
      const artifact = getPhaseArtifact(state.phase);
      if (artifact) {
        // Append to progress.md for implementation/review, overwrite for others
        if (artifact === "progress.md") {
          const existing = readArtifact(state.artifactDir, artifact) || "";
          const timestamp = new Date().toISOString();
          const entry = `\n\n---\n\n## ${getPhaseName(state.phase)} - ${timestamp}\n\n${content}`;
          writeArtifact(state.artifactDir, artifact, existing + entry);
        } else {
          writeArtifact(state.artifactDir, artifact, content);
        }
      }
    }

    // Ask user if phase is complete
    const isComplete = await ctx.ui.confirm(
      `${getPhaseName(state.phase)} Phase`,
      "Is this phase complete? Ready to proceed?",
    );

    if (isComplete) {
      // Phase transition in agent_end - we don't have full ExtensionCommandContext
      // so we handle it inline without newSession support
      const nextPhase = getNextPhase(state.phase);

      if (nextPhase === "complete") {
        ctx.ui.notify("󱁖 Task workflow complete!", "success");
        resetState();
        updateStatus(ctx);
        persistState();
        return;
      }

      // Check if we should suggest a new session
      const highContextUsage = await checkContextUsage(ctx);

      // Ask for review & edit before proceeding
      const artifact = getPhaseArtifact(state.phase);
      let reviewContent = "";

      if (artifact && state.artifactDir) {
        reviewContent = readArtifact(state.artifactDir, artifact) || "";
      }

      // Show phase summary and ask for modifications
      const choice = await ctx.ui.select(
        `${getPhaseName(state.phase)} phase complete. What next?`,
        [
          `Proceed to ${getPhaseName(nextPhase)} phase`,
          "Edit phase output before proceeding",
          "Abort workflow",
        ],
      );

      if (!choice || choice.includes("Abort")) {
        const saveChoice = await ctx.ui.confirm(
          "Save Progress?",
          "Save current progress before aborting?",
        );
        if (saveChoice && state.artifactDir) {
          ctx.ui.notify(`Progress saved to ${state.artifactDir}`, "info");
        }
        resetState();
        updateStatus(ctx);
        persistState();
        return;
      }

      if (choice.includes("Edit")) {
        const edited = await ctx.ui.editor(
          `Edit ${getPhaseName(state.phase)} output:`,
          reviewContent,
        );
        if (edited && artifact && state.artifactDir && state.saveArtifacts) {
          writeArtifact(state.artifactDir, artifact, edited);
        }
      }

      // Notify about high context usage (can't create new session from agent_end)
      if (highContextUsage) {
        ctx.ui.notify(
          "Context usage is high (70%+). Consider using /task --resume after starting a new session.",
          "warning",
        );
      }

      // Continue in same session
      state.phase = nextPhase;
      updateStatus(ctx);
      persistState();

      // Inject next phase prompt
      const phasePrompt = PHASE_PROMPTS[nextPhase as keyof PhasePrompts];
      if (phasePrompt) {
        pi.sendMessage(
          {
            customType: "task-workflow-phase",
            content: phasePrompt,
            display: false,
          },
          { triggerTurn: true },
        );
      }
    }
  });

  // Handle abort
  pi.on("session_shutdown", async (_event, ctx) => {
    if (!state.taskId && !state.description) return;
    if (!ctx.hasUI) return;

    if (state.saveArtifacts && state.artifactDir) {
      const saveChoice = await ctx.ui.confirm(
        "Save Progress?",
        "Save current progress before exiting?",
      );
      if (saveChoice) {
        ctx.ui.notify(`Progress saved to ${state.artifactDir}`, "info");
      }
    }
  });

  // Restore state on session start
  pi.on("session_start", async (_event, ctx) => {
    const entries = ctx.sessionManager.getEntries();

    // Find last task-workflow-state entry
    const stateEntry = entries
      .filter(
        (e: { type: string; customType?: string }) =>
          e.type === "custom" && e.customType === "task-workflow-state",
      )
      .pop() as { data?: TaskState } | undefined;

    if (stateEntry?.data) {
      state = { ...state, ...stateEntry.data };

      if (ctx.hasUI) {
        updateStatus(ctx);

        if (state.phase !== "complete" && (state.taskId || state.description)) {
          ctx.ui.notify(
            `Restored task: ${state.taskId || state.description} (${getPhaseName(state.phase)} phase)`,
            "info",
          );
        }
      }
    }
  });

  // Inject phase context before agent starts
  pi.on("before_agent_start", async (_event, _ctx) => {
    if (!state.taskId && !state.description) return;
    if (state.phase === "complete") return;

    return {
      message: {
        customType: "task-workflow-context",
        content: `[TASK WORKFLOW - ${getPhaseName(state.phase).toUpperCase()} PHASE]
Task: ${state.taskId || "N/A"}
Description: ${state.description}
Artifacts: ${state.artifactDir || "Not saving"}

Follow the phase instructions. When complete, the user will be prompted to proceed.`,
        display: false,
      },
    };
  });
}
