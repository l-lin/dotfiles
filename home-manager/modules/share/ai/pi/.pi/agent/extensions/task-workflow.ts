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
 *   /task --next                 - Proceed to next phase
 *   /task --abort                - Abort current task workflow
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

type Phase = "scout" | "planning" | "implementation" | "review" | "complete";

interface TaskState {
  phase: Phase;
  taskId: string | null;
  description: string;
  artifactDir: string | null;
  saveArtifacts: boolean;
  branchCreated: string | null;
}

const JIRA_PATTERN = /^[A-Z]+-\d+$/;
const CONTEXT_THRESHOLD = 70;

const PHASE_META: Record<Phase, { emoji: string; artifact: string | null; next: Phase }> = {
  scout: { emoji: " ", artifact: "context.md", next: "planning" },
  planning: { emoji: " ", artifact: "plan.md", next: "implementation" },
  implementation: { emoji: " ", artifact: "progress.md", next: "review" },
  review: { emoji: " ", artifact: "progress.md", next: "complete" },
  complete: { emoji: "󱁖 ", artifact: null, next: "complete" },
};

const PHASE_PROMPTS: Record<Exclude<Phase, "complete">, string> = {
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

Be thorough - this context will drive the planning phase.

When done, the user will run \`/task --next\` to proceed.`,

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

Each step should be small enough to implement and verify independently.

When done, the user will run \`/task --next\` to proceed.`,

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

Mark each step complete as you finish it.

When done, the user will run \`/task --next\` to proceed.`,

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

Report the final status with all checklist items addressed.

When done, the user will run \`/task --next\` to complete the workflow.`,
};

const today = () => new Date().toISOString().split("T")[0];
const slugify = (text: string) => text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").substring(0, 50);
const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

function readArtifact(dir: string, filename: string): string | null {
  const filepath = path.join(dir, filename);
  return fs.existsSync(filepath) ? fs.readFileSync(filepath, "utf-8") : null;
}

function getArtifactDir(cwd: string, taskId: string | null, description: string): string {
  const parts = [today(), taskId, slugify(description)].filter(Boolean);
  return path.join(cwd, ".sandbox", "tasks", parts.join("-") || `${today()}-task`);
}

function findExistingTaskDir(cwd: string, taskId: string): string | null {
  const tasksDir = path.join(cwd, ".sandbox", "tasks");
  if (!fs.existsSync(tasksDir)) return null;
  const match = fs.readdirSync(tasksDir).find((d) => d.includes(taskId));
  return match ? path.join(tasksDir, match) : null;
}

async function gitBranch(pi: ExtensionAPI, args: string[]): Promise<string | null> {
  try {
    const result = await pi.exec("git", args, { timeout: 5000 });
    return result.code === 0 ? result.stdout.trim() : null;
  } catch {
    return null;
  }
}

// Extension -------------------------------------------
export default function taskWorkflowExtension(pi: ExtensionAPI): void {
  const initialState = (): TaskState => ({
    phase: "scout",
    taskId: null,
    description: "",
    artifactDir: null,
    saveArtifacts: false,
    branchCreated: null,
  });

  let state = initialState();

  function updateStatus(ctx: ExtensionContext): void {
    if (!state.taskId && !state.description) {
      ctx.ui.setStatus("task-workflow", undefined);
      ctx.ui.setWidget("task-workflow", undefined);
      return;
    }
    const text = `${PHASE_META[state.phase].emoji} ${state.taskId || "task"}: ${capitalize(state.phase)}`;
    ctx.ui.setStatus("task-workflow", ctx.ui.theme.fg("accent", text));
  }

  function buildPhasePrompt(phase: Exclude<Phase, "complete">): string {
    let prompt = PHASE_PROMPTS[phase];
    const { artifact } = PHASE_META[phase];
    const dir = state.artifactDir;

    // Add context from previous phases
    if (dir) {
      const context = readArtifact(dir, "context.md");
      const plan = readArtifact(dir, "plan.md");
      const progress = readArtifact(dir, "progress.md");

      const additions: string[] = [];
      if (phase === "planning" && context) additions.push(`# Context from Scout Phase\n\n${context}`);
      if (phase === "implementation") {
        if (context) additions.push(`# Context\n\n${context}`);
        if (plan) additions.push(`# Plan\n\n${plan}`);
      }
      if (phase === "review") {
        if (plan) additions.push(`# Plan\n\n${plan}`);
        if (progress) additions.push(`# Progress\n\n${progress}`);
      }
      if (additions.length) prompt += "\n\n---\n\n" + additions.join("\n\n---\n\n");
    }

    // Artifact writing instructions
    if (state.saveArtifacts && dir && artifact) {
      const artifactPath = path.join(dir, artifact);
      const isProgress = artifact === "progress.md";
      const existing = isProgress ? readArtifact(dir, artifact) : null;

      prompt += `\n\n---\n\n## Output Instructions

**IMPORTANT**: Write your phase output directly to the artifact file using the write tool:
- Artifact file: \`${artifactPath}\`
- Use the \`write\` tool to save your analysis/plan/progress to this file
- Keep chat output minimal - only display a brief summary (1-2 sentences)
- Use \`AskUserQuestion\` tool for any questions that need user input
- Do NOT dump the full analysis in chat - write it to the file instead`;

      if (isProgress && existing) {
        prompt += `\n- **APPEND** to the existing content - do not overwrite previous progress
- Start your entry with a timestamp header: \`## ${capitalize(phase)} - [timestamp]\``;
      }
    }

    if (state.taskId) prompt = `Task: ${state.taskId}\n\n${prompt}`;
    if (state.description) prompt = `Description: ${state.description}\n\n${prompt}`;
    return prompt;
  }

  async function handleNext(ctx: ExtensionCommandContext): Promise<void> {
    if (!state.taskId && !state.description) {
      ctx.ui.notify("No active task. Start one with /task <description>", "error");
      return;
    }

    const nextPhase = PHASE_META[state.phase].next;
    if (nextPhase === "complete") {
      ctx.ui.notify("󱁖 Task workflow complete!", "success");
      state = initialState();
      updateStatus(ctx);
      pi.appendEntry("task-workflow-state", { ...state });
      return;
    }

    // Check context usage for new session suggestion
    const usage = ctx.getContextUsage();
    if (usage && usage.percent >= CONTEXT_THRESHOLD) {
      const newSession = await ctx.ui.confirm(
        "High Context Usage",
        "Context is at 70%+ usage. Start a new session for the next phase? Artifacts will be auto-loaded.",
      );
      if (newSession) {
        state.phase = nextPhase;
        pi.appendEntry("task-workflow-state", { ...state });
        await ctx.newSession({ parentSession: ctx.sessionManager.getSessionFile() });
        ctx.ui.setEditorText(buildPhasePrompt(nextPhase));
        ctx.ui.notify(`New session started. Phase: ${capitalize(nextPhase)}`, "info");
        return;
      }
    }

    state.phase = nextPhase;
    updateStatus(ctx);
    pi.appendEntry("task-workflow-state", { ...state });
    pi.sendMessage({ customType: "task-workflow-phase", content: PHASE_PROMPTS[nextPhase], display: false }, { triggerTurn: true });
  }

  async function handleResume(ctx: ExtensionCommandContext, args: string): Promise<void> {
    const [resumePhase, resumeTaskId] = args.split(/\s+/) as [Phase | undefined, string | undefined];
    const validPhases: Phase[] = ["scout", "planning", "implementation", "review"];

    if (!resumePhase || !validPhases.includes(resumePhase)) {
      ctx.ui.notify(`Usage: /task --resume <phase> [TASK-ID]\nPhases: ${validPhases.join(", ")}`, "error");
      return;
    }

    const taskIdToFind = resumeTaskId || state.taskId;
    if (!state.artifactDir && taskIdToFind) {
      state.artifactDir = findExistingTaskDir(ctx.cwd, taskIdToFind);
      if (resumeTaskId) state.taskId = resumeTaskId;
    }

    if (!state.artifactDir) {
      ctx.ui.notify("No task artifacts found. Specify task ID: /task --resume <phase> TASK-ID", "error");
      return;
    }

    // Extract description from dir name
    if (!state.description && state.artifactDir) {
      let remainder = path.basename(state.artifactDir).replace(/^\d{4}-\d{2}-\d{2}-/, "");
      if (state.taskId) remainder = remainder.replace(new RegExp(`^${state.taskId}-?`, "i"), "");
      state.description = remainder.replace(/-/g, " ");
    }

    state.phase = resumePhase;
    state.saveArtifacts = true;
    updateStatus(ctx);
    pi.appendEntry("task-workflow-state", { ...state });
    ctx.ui.setEditorText(buildPhasePrompt(resumePhase));
    ctx.ui.notify(`Resuming from ${capitalize(resumePhase)} phase`, "info");
  }

  async function handleStart(ctx: ExtensionCommandContext, args: string): Promise<void> {
    let taskId: string | null = null;
    let description = args;
    const firstWord = args.split(" ")[0];

    if (JIRA_PATTERN.test(firstWord)) {
      taskId = firstWord;
      description = args.slice(taskId.length).trim();
    }

    // Check/create branch
    const currentBranch = await gitBranch(pi, ["rev-parse", "--abbrev-ref", "HEAD"]);
    if (currentBranch) {
      const branchTicket = currentBranch.match(/([A-Z]+-\d+)/)?.[1] ?? null;
      if (branchTicket && !taskId) {
        taskId = branchTicket;
      } else if (taskId && branchTicket !== taskId) {
        const slug = slugify(description);
        const newBranch = slug ? `${taskId}-${slug}` : taskId;
        ctx.ui.notify(`Creating branch: ${newBranch}`, "info");
        const created = await gitBranch(pi, ["checkout", "-b", newBranch]);
        state.branchCreated = created ? newBranch : null;
        if (!created) ctx.ui.notify("Failed to create branch. Continuing on current branch.", "warning");
      }
    }

    const saveChoice = await ctx.ui.confirm(
      "Save Artifacts?",
      "Save phase outputs to .sandbox/tasks/? (Recommended for complex tasks)",
    );

    state = { ...initialState(), taskId, description, saveArtifacts: saveChoice, phase: "scout", branchCreated: state.branchCreated };

    if (saveChoice) {
      state.artifactDir = getArtifactDir(ctx.cwd, taskId, description);
      fs.mkdirSync(state.artifactDir, { recursive: true });
      ctx.ui.notify(`Artifacts will be saved to: ${state.artifactDir}`, "info");
    }

    updateStatus(ctx);
    pi.appendEntry("task-workflow-state", { ...state });
    pi.sendMessage({ customType: "task-workflow-phase", content: buildPhasePrompt("scout"), display: true }, { triggerTurn: true });
    pi.setSessionName(`Task: ${taskId || description.substring(0, 30) || "unnamed"}`);
  }

  // Command
  pi.registerCommand("task", {
    description: "Start or manage a phased task workflow (scout → planning → implementation → review)",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/task requires interactive mode", "error");
        return;
      }

      const trimmed = args.trim();

      if (trimmed === "--status") {
        const msg = !state.taskId && !state.description
          ? "No active task"
          : ` ${state.taskId || state.description}\n${PHASE_META[state.phase].emoji} ${capitalize(state.phase)}\n ${state.artifactDir || "none"}`;
        ctx.ui.notify(msg, "info");
        return;
      }

      if (trimmed === "--next") return handleNext(ctx);
      if (trimmed.startsWith("--resume")) return handleResume(ctx, trimmed.replace("--resume", "").trim());

      if (trimmed === "--abort") {
        if (!state.taskId && !state.description) {
          ctx.ui.notify("No active task to abort", "info");
          return;
        }
        const label = state.taskId || state.description;
        ctx.ui.notify(`Task "${label}" aborted${state.artifactDir ? `. Artifacts saved to ${state.artifactDir}` : ""}`, "info");
        state = initialState();
        updateStatus(ctx);
        pi.appendEntry("task-workflow-state", { ...state });
        return;
      }

      if (!trimmed) {
        ctx.ui.notify("Usage: /task <JIRA-ID or description>", "error");
        return;
      }

      return handleStart(ctx, trimmed);
    },
  });

  // Events
  pi.on("agent_end", async (_event, ctx) => {
    if ((!state.taskId && !state.description) || state.phase === "complete") return;
    if (!ctx.hasUI) return;
    const next = PHASE_META[state.phase].next;
    const action = next === "complete" ? "complete the workflow" : `proceed to ${capitalize(next)}`;
    ctx.ui.notify(`Run /task --next to ${action}`, "info");
  });

  pi.on("session_start", async (_event, ctx) => {
    const entries = ctx.sessionManager.getEntries();
    const stateEntry = entries
      .filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "task-workflow-state")
      .pop() as { data?: TaskState } | undefined;

    if (stateEntry?.data) {
      state = { ...state, ...stateEntry.data };
      if (ctx.hasUI) {
        updateStatus(ctx);
        if (state.phase !== "complete" && (state.taskId || state.description)) {
          ctx.ui.notify(`Restored task: ${state.taskId || state.description} (${capitalize(state.phase)} phase)`, "info");
        }
      }
    }
  });

  pi.on("before_agent_start", async () => {
    if ((!state.taskId && !state.description) || state.phase === "complete") return;
    return {
      message: {
        customType: "task-workflow-context",
        content: `[TASK WORKFLOW - ${state.phase.toUpperCase()} PHASE]
Task: ${state.taskId || "N/A"}
Description: ${state.description}
Artifacts: ${state.artifactDir || "Not saving"}

Follow the phase instructions. When complete, the user will be prompted to proceed.`,
        display: false,
      },
    };
  });
}
