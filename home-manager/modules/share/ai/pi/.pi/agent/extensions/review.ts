/**
 * Code Review Extension
 *
 * Usage:
 * - `/review` - show interactive selector
 * - `/review pr 123` - review PR #123
 * - `/review uncommitted` - review uncommitted changes
 * - `/review branch main` - review against main branch
 * - `/review commit abc123` - review specific commit
 * - `/review custom "check for security issues"` - custom instructions
 *
 * src: https://github.com/mitsuhiko/agent-stuff/blob/327ebb565a5dc2b9959d646051606590383f7731/pi-extensions/review.ts
 * Adapted and simplified in the code (only code, no change on behavior).
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  ExtensionCommandContext,
} from "@mariozechner/pi-coding-agent";
import { DynamicBorder, BorderedLoader } from "@mariozechner/pi-coding-agent";
import {
  Container,
  type SelectItem,
  SelectList,
  Text,
} from "@mariozechner/pi-tui";
import path from "node:path";
import { promises as fs } from "node:fs";

// ─── State ────────────────────────────────────────────────────────────────────

const REVIEW_STATE_TYPE = "review-session";
let reviewOriginId: string | undefined;

type ReviewSessionState = { active: boolean; originId?: string };

type ReviewTarget =
  | { type: "uncommitted" }
  | { type: "baseBranch"; branch: string }
  | { type: "commit"; sha: string; title?: string }
  | { type: "custom"; instructions: string }
  | { type: "pullRequest"; prNumber: number; baseBranch: string; title: string };

// ─── Prompts ──────────────────────────────────────────────────────────────────

const PROMPTS = {
  uncommitted:
    "Review the current code changes (staged, unstaged, and untracked files) and provide prioritized findings.",

  baseBranchWithMerge: (branch: string, sha: string) =>
    `Review the code changes against the base branch '${branch}'. The merge base commit is ${sha}. Run \`git diff ${sha}\` to inspect the changes. Provide prioritized, actionable findings.`,

  baseBranchFallback: (branch: string) =>
    `Review the code changes against the base branch '${branch}'. Start by finding the merge base (\`git merge-base HEAD "$(git rev-parse --abbrev-ref "${branch}@{upstream}")"\`), then run \`git diff\` against that SHA. Provide prioritized, actionable findings.`,

  commit: (sha: string, title?: string) =>
    title
      ? `Review the code changes introduced by commit ${sha} ("${title}"). Provide prioritized, actionable findings.`
      : `Review the code changes introduced by commit ${sha}. Provide prioritized, actionable findings.`,

  prWithMerge: (num: number, title: string, base: string, sha: string) =>
    `Review pull request #${num} ("${title}") against '${base}'. The merge base is ${sha}. Run \`git diff ${sha}\` to inspect the changes. Provide prioritized, actionable findings.`,

  prFallback: (num: number, title: string, base: string) =>
    `Review pull request #${num} ("${title}") against '${base}'. Find the merge base (\`git merge-base HEAD ${base}\`), then run \`git diff\` against it. Provide prioritized, actionable findings.`,
};

const REVIEW_RUBRIC = `# Review Guidelines

You are acting as a code reviewer for a proposed code change.

## Determining what to flag

Flag issues that:
1. Meaningfully impact accuracy, performance, security, or maintainability.
2. Are discrete and actionable.
3. Were introduced in the changes being reviewed (not pre-existing).
4. The author would likely fix if aware.

## Untrusted User Input

1. Flag open redirects without domain validation.
2. Flag non-parameterized SQL.
3. In URL input systems, HTTP fetches need local resource protection.
4. Prefer escaping over sanitizing.

## Comment guidelines

1. Be clear about why the issue is a problem.
2. Communicate severity appropriately.
3. Be brief - at most 1 paragraph.
4. Keep code snippets under 3 lines.
5. Use a matter-of-fact tone.

## Priority levels

- [P0] - Drop everything. Blocking release.
- [P1] - Urgent. Next cycle.
- [P2] - Normal. Eventually.
- [P3] - Low. Nice to have.

## Output format

1. List each finding with priority tag, file location, and explanation.
2. At the end: "correct" (no blocking issues) or "needs attention".
3. If no qualifying findings, explicitly state the code looks good.`;

const REVIEW_SUMMARY_PROMPT = `Create a structured summary of this code review:

1. What was reviewed
2. Key findings with priority levels (P0-P3)
3. Overall verdict (correct vs needs attention)
4. Action items

End with:

## Next Steps
1. [What should happen next]

## Code Review Findings

[P0] Short Title
File: path/to/file.ext:line_number
\`\`\`
affected code snippet
\`\`\``;

// ─── Git Helpers ──────────────────────────────────────────────────────────────

const git = {
  async exec(pi: ExtensionAPI, args: string[]): Promise<{ stdout: string; code: number }> {
    return pi.exec("git", args);
  },

  async getMergeBase(pi: ExtensionAPI, branch: string): Promise<string | null> {
    // Try upstream first
    const { stdout: upstream, code: upCode } = await this.exec(pi, [
      "rev-parse", "--abbrev-ref", `${branch}@{upstream}`
    ]);
    if (upCode === 0 && upstream.trim()) {
      const { stdout, code } = await this.exec(pi, ["merge-base", "HEAD", upstream.trim()]);
      if (code === 0) return stdout.trim() || null;
    }
    // Fallback to branch directly
    const { stdout, code } = await this.exec(pi, ["merge-base", "HEAD", branch]);
    return code === 0 ? stdout.trim() || null : null;
  },

  async getBranches(pi: ExtensionAPI): Promise<string[]> {
    const { stdout, code } = await this.exec(pi, ["branch", "--format=%(refname:short)"]);
    return code === 0 ? stdout.trim().split("\n").filter(Boolean) : [];
  },

  async getRecentCommits(pi: ExtensionAPI, limit = 10): Promise<{ sha: string; title: string }[]> {
    const { stdout, code } = await this.exec(pi, ["log", "--oneline", `-n`, `${limit}`]);
    if (code !== 0) return [];
    return stdout.trim().split("\n").filter(Boolean).map(line => {
      const [sha, ...rest] = line.split(" ");
      return { sha, title: rest.join(" ") };
    });
  },

  async hasUncommittedChanges(pi: ExtensionAPI): Promise<boolean> {
    const { stdout, code } = await this.exec(pi, ["status", "--porcelain"]);
    return code === 0 && stdout.trim().length > 0;
  },

  async hasPendingChanges(pi: ExtensionAPI): Promise<boolean> {
    const { stdout, code } = await this.exec(pi, ["status", "--porcelain"]);
    if (code !== 0) return false;
    return stdout.split("\n").some(line => line.trim() && !line.startsWith("??"));
  },

  async getCurrentBranch(pi: ExtensionAPI): Promise<string | null> {
    const { stdout, code } = await this.exec(pi, ["branch", "--show-current"]);
    return code === 0 ? stdout.trim() || null : null;
  },

  async getDefaultBranch(pi: ExtensionAPI): Promise<string> {
    const { stdout, code } = await this.exec(pi, ["symbolic-ref", "refs/remotes/origin/HEAD", "--short"]);
    if (code === 0 && stdout.trim()) return stdout.trim().replace("origin/", "");
    const branches = await this.getBranches(pi);
    return branches.includes("main") ? "main" : branches.includes("master") ? "master" : "main";
  },

  async isRepo(pi: ExtensionAPI): Promise<boolean> {
    const { code } = await this.exec(pi, ["rev-parse", "--git-dir"]);
    return code === 0;
  },
};

// ─── GitHub Helpers ───────────────────────────────────────────────────────────

const gh = {
  async getPrInfo(pi: ExtensionAPI, num: number): Promise<{ baseBranch: string; title: string; headBranch: string } | null> {
    const { stdout, code } = await pi.exec("gh", ["pr", "view", String(num), "--json", "baseRefName,title,headRefName"]);
    if (code !== 0) return null;
    try {
      const data = JSON.parse(stdout);
      return { baseBranch: data.baseRefName, title: data.title, headBranch: data.headRefName };
    } catch { return null; }
  },

  async checkoutPr(pi: ExtensionAPI, num: number): Promise<{ success: boolean; error?: string }> {
    const { stdout, stderr, code } = await pi.exec("gh", ["pr", "checkout", String(num)]);
    return code === 0 ? { success: true } : { success: false, error: stderr || stdout || "Failed to checkout PR" };
  },

  parsePrRef(ref: string): number | null {
    const num = parseInt(ref.trim(), 10);
    if (!isNaN(num) && num > 0) return num;
    const match = ref.match(/github\.com\/[^/]+\/[^/]+\/pull\/(\d+)/);
    return match ? parseInt(match[1], 10) : null;
  },
};

// ─── Utilities ────────────────────────────────────────────────────────────────

async function loadProjectGuidelines(cwd: string): Promise<string | null> {
  let dir = path.resolve(cwd);
  while (true) {
    const piStats = await fs.stat(path.join(dir, ".pi")).catch(() => null);
    if (piStats?.isDirectory()) {
      try {
        const content = await fs.readFile(path.join(dir, "REVIEW_GUIDELINES.md"), "utf8");
        return content.trim() || null;
      } catch { return null; }
    }
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function getReviewState(ctx: ExtensionContext): ReviewSessionState | undefined {
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type === "custom" && entry.customType === REVIEW_STATE_TYPE) {
      return entry.data as ReviewSessionState | undefined;
    }
  }
}

function applyReviewState(ctx: ExtensionContext) {
  const state = getReviewState(ctx);
  if (state?.active && state.originId) {
    reviewOriginId = state.originId;
    setReviewWidget(ctx, true);
  } else {
    reviewOriginId = undefined;
    setReviewWidget(ctx, false);
  }
}

function setReviewWidget(ctx: ExtensionContext, active: boolean) {
  if (!ctx.hasUI) return;
  if (!active) { ctx.ui.setWidget("review", undefined); return; }
  ctx.ui.setWidget("review", (_tui, theme) => {
    const text = new Text(theme.fg("warning", "Review session active, return with /end-review"), 0, 0);
    return { render: (w: number) => text.render(w), invalidate: () => text.invalidate() };
  });
}

async function buildPrompt(pi: ExtensionAPI, target: ReviewTarget): Promise<string> {
  switch (target.type) {
    case "uncommitted": return PROMPTS.uncommitted;
    case "baseBranch": {
      const base = await git.getMergeBase(pi, target.branch);
      return base ? PROMPTS.baseBranchWithMerge(target.branch, base) : PROMPTS.baseBranchFallback(target.branch);
    }
    case "commit": return PROMPTS.commit(target.sha, target.title);
    case "custom": return target.instructions;
    case "pullRequest": {
      const base = await git.getMergeBase(pi, target.baseBranch);
      return base
        ? PROMPTS.prWithMerge(target.prNumber, target.title, target.baseBranch, base)
        : PROMPTS.prFallback(target.prNumber, target.title, target.baseBranch);
    }
  }
}

function getHint(target: ReviewTarget): string {
  switch (target.type) {
    case "uncommitted": return "current changes";
    case "baseBranch": return `changes against '${target.branch}'`;
    case "commit": return target.title ? `commit ${target.sha.slice(0, 7)}: ${target.title}` : `commit ${target.sha.slice(0, 7)}`;
    case "custom": return target.instructions.length > 40 ? target.instructions.slice(0, 37) + "..." : target.instructions;
    case "pullRequest": return `PR #${target.prNumber}: ${target.title.slice(0, 30)}${target.title.length > 30 ? "..." : ""}`;
  }
}

function parseArgs(args: string | undefined): ReviewTarget | { type: "pr"; ref: string } | null {
  if (!args?.trim()) return null;
  const [cmd, ...rest] = args.trim().split(/\s+/);
  const sub = cmd?.toLowerCase();
  switch (sub) {
    case "uncommitted": return { type: "uncommitted" };
    case "branch": return rest[0] ? { type: "baseBranch", branch: rest[0] } : null;
    case "commit": return rest[0] ? { type: "commit", sha: rest[0], title: rest.slice(1).join(" ") || undefined } : null;
    case "custom": return rest.length ? { type: "custom", instructions: rest.join(" ") } : null;
    case "pr": return rest[0] ? { type: "pr", ref: rest[0] } : null;
    default: return null;
  }
}

// ─── UI Helpers ───────────────────────────────────────────────────────────────

function createSelectUI<T>(
  ctx: ExtensionContext,
  title: string,
  items: SelectItem[],
  onSelect: (item: SelectItem) => T | null,
  searchable = false
): Promise<T | null> {
  return ctx.ui.custom<T | null>((tui, theme, _kb, done) => {
    const container = new Container();
    container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
    container.addChild(new Text(theme.fg("accent", theme.bold(title))));
    const list = new SelectList(items, Math.min(items.length, 10), {
      selectedPrefix: (t) => theme.fg("accent", t),
      selectedText: (t) => theme.fg("accent", t),
      description: (t) => theme.fg("muted", t),
      scrollInfo: (t) => theme.fg("dim", t),
      noMatch: (t) => theme.fg("warning", t),
    });
    list.searchable = searchable;
    list.onSelect = (item) => done(onSelect(item));
    list.onCancel = () => done(null);
    container.addChild(list);
    container.addChild(new Text(theme.fg("dim", searchable ? "Type to filter • enter to select • esc to cancel" : "Press enter to confirm or esc to go back")));
    container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
    return {
      render: (w: number) => container.render(w),
      invalidate: () => container.invalidate(),
      handleInput: (data: string) => { list.handleInput(data); tui.requestRender(); },
    };
  });
}

// ─── Extension ────────────────────────────────────────────────────────────────

export default function reviewExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_, ctx) => applyReviewState(ctx));
  pi.on("session_switch", (_, ctx) => applyReviewState(ctx));
  pi.on("session_tree", (_, ctx) => applyReviewState(ctx));

  async function getSmartDefault(pi: ExtensionAPI): Promise<string> {
    if (await git.hasUncommittedChanges(pi)) return "uncommitted";
    const current = await git.getCurrentBranch(pi);
    const def = await git.getDefaultBranch(pi);
    return current && current !== def ? "baseBranch" : "commit";
  }

  async function showReviewSelector(ctx: ExtensionContext): Promise<ReviewTarget | null> {
    const presets = [
      { value: "pullRequest", label: "Review a pull request", description: "(GitHub PR)" },
      { value: "baseBranch", label: "Review against a base branch", description: "(local)" },
      { value: "uncommitted", label: "Review uncommitted changes", description: "" },
      { value: "commit", label: "Review a commit", description: "" },
      { value: "custom", label: "Custom review instructions", description: "" },
    ];
    const smartDefault = await getSmartDefault(pi);
    const sorted = presets.sort((a, b) => (a.value === smartDefault ? -1 : b.value === smartDefault ? 1 : 0));

    while (true) {
      const result = await createSelectUI(ctx, "Select a review preset", sorted, (item) => item.value);
      if (!result) return null;

      switch (result) {
        case "uncommitted": return { type: "uncommitted" };
        case "baseBranch": {
          const branches = await git.getBranches(pi);
          if (!branches.length) { ctx.ui.notify("No branches found", "error"); break; }
          const def = await git.getDefaultBranch(pi);
          const items = branches.sort((a, b) => (a === def ? -1 : b === def ? 1 : a.localeCompare(b)))
            .map(b => ({ value: b, label: b, description: b === def ? "(default)" : "" }));
          const branch = await createSelectUI(ctx, "Select base branch", items, (i) => i.value, true);
          if (branch) return { type: "baseBranch", branch };
          break;
        }
        case "commit": {
          const commits = await git.getRecentCommits(pi, 20);
          if (!commits.length) { ctx.ui.notify("No commits found", "error"); break; }
          const items = commits.map(c => ({ value: c.sha, label: `${c.sha.slice(0, 7)} ${c.title}`, description: "" }));
          const commit = await createSelectUI(ctx, "Select commit to review", items, (i) => commits.find(c => c.sha === i.value), true);
          if (commit) return { type: "commit", sha: commit.sha, title: commit.title };
          break;
        }
        case "custom": {
          const text = await ctx.ui.editor("Enter review instructions:", "");
          if (text?.trim()) return { type: "custom", instructions: text.trim() };
          break;
        }
        case "pullRequest": {
          const target = await handlePrCheckout(ctx);
          if (target) return target;
          break;
        }
      }
    }
  }

  async function handlePrCheckout(ctx: ExtensionContext): Promise<ReviewTarget | null> {
    if (await git.hasPendingChanges(pi)) {
      ctx.ui.notify("Cannot checkout PR: uncommitted changes. Commit or stash first.", "error");
      return null;
    }
    const ref = await ctx.ui.editor("Enter PR number or URL:", "");
    if (!ref?.trim()) return null;
    const num = gh.parsePrRef(ref);
    if (!num) { ctx.ui.notify("Invalid PR reference.", "error"); return null; }

    ctx.ui.notify(`Fetching PR #${num}...`, "info");
    const info = await gh.getPrInfo(pi, num);
    if (!info) { ctx.ui.notify(`Could not find PR #${num}.`, "error"); return null; }

    ctx.ui.notify(`Checking out PR #${num}...`, "info");
    const checkout = await gh.checkoutPr(pi, num);
    if (!checkout.success) { ctx.ui.notify(`Failed: ${checkout.error}`, "error"); return null; }

    ctx.ui.notify(`Checked out PR #${num} (${info.headBranch})`, "info");
    return { type: "pullRequest", prNumber: num, baseBranch: info.baseBranch, title: info.title };
  }

  async function executeReview(ctx: ExtensionCommandContext, target: ReviewTarget, freshSession: boolean) {
    if (reviewOriginId) {
      ctx.ui.notify("Already in a review. Use /end-review first.", "warning");
      return;
    }

    if (freshSession) {
      const originId = ctx.sessionManager.getLeafId() ?? undefined;
      if (!originId) { ctx.ui.notify("Failed to determine review origin.", "error"); return; }
      reviewOriginId = originId;

      const entries = ctx.sessionManager.getEntries();
      const firstUser = entries.find(e => e.type === "message" && e.message.role === "user");
      if (!firstUser) { ctx.ui.notify("No user message found in session", "error"); reviewOriginId = undefined; return; }

      try {
        const result = await ctx.navigateTree(firstUser.id, { summarize: false, label: "code-review" });
        if (result.cancelled) { reviewOriginId = undefined; return; }
      } catch (e) {
        reviewOriginId = undefined;
        ctx.ui.notify(`Failed to start review: ${e instanceof Error ? e.message : String(e)}`, "error");
        return;
      }

      reviewOriginId = originId;
      ctx.ui.setEditorText("");
      setReviewWidget(ctx, true);
      pi.appendEntry(REVIEW_STATE_TYPE, { active: true, originId });
    }

    const prompt = await buildPrompt(pi, target);
    const guidelines = await loadProjectGuidelines(ctx.cwd);
    let fullPrompt = `${REVIEW_RUBRIC}\n\n---\n\n${prompt}`;
    if (guidelines) fullPrompt += `\n\nProject-specific guidelines:\n\n${guidelines}`;

    ctx.ui.notify(`Starting review: ${getHint(target)}${freshSession ? " (fresh session)" : ""}`, "info");
    pi.sendUserMessage(fullPrompt);
  }

  pi.registerCommand("review", {
    description: "Review code changes (PR, uncommitted, branch, commit, or custom)",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) { ctx.ui.notify("Review requires interactive mode", "error"); return; }
      if (reviewOriginId) { ctx.ui.notify("Already in a review. Use /end-review first.", "warning"); return; }
      if (!(await git.isRepo(pi))) { ctx.ui.notify("Not a git repository", "error"); return; }

      let target: ReviewTarget | null = null;
      const parsed = parseArgs(args);

      if (parsed) {
        target = parsed.type === "pr" ? await handlePrCheckout(ctx) : parsed as ReviewTarget;
      }
      if (!target) target = await showReviewSelector(ctx);
      if (!target) { ctx.ui.notify("Review cancelled", "info"); return; }

      const entries = ctx.sessionManager.getEntries();
      const hasMessages = entries.some(e => e.type === "message");
      let freshSession = false;

      if (hasMessages) {
        const choice = await ctx.ui.select("Start review in:", ["Empty branch", "Current session"]);
        if (choice === undefined) { ctx.ui.notify("Review cancelled", "info"); return; }
        freshSession = choice === "Empty branch";
      }

      await executeReview(ctx, target, freshSession);
    },
  });

  pi.registerCommand("end-review", {
    description: "Complete review and return to original position",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) { ctx.ui.notify("End-review requires interactive mode", "error"); return; }

      if (!reviewOriginId) {
        const state = getReviewState(ctx);
        if (state?.active && state.originId) {
          reviewOriginId = state.originId;
        } else if (state?.active) {
          setReviewWidget(ctx, false);
          pi.appendEntry(REVIEW_STATE_TYPE, { active: false });
          ctx.ui.notify("Review state was missing origin info; cleared.", "warning");
          return;
        } else {
          ctx.ui.notify("Not in a review branch.", "info");
          return;
        }
      }

      const choice = await ctx.ui.select("Summarize review branch?", ["Summarize", "No summary"]);
      if (choice === undefined) { ctx.ui.notify("Cancelled. Use /end-review to try again.", "info"); return; }

      const originId = reviewOriginId;

      if (choice === "Summarize") {
        const result = await ctx.ui.custom<{ cancelled: boolean; error?: string } | null>((tui, theme, _kb, done) => {
          const loader = new BorderedLoader(tui, theme, "Summarizing review branch...");
          loader.onAbort = () => done(null);
          ctx.navigateTree(originId!, { summarize: true, customInstructions: REVIEW_SUMMARY_PROMPT, replaceInstructions: true })
            .then(done)
            .catch(e => done({ cancelled: false, error: e instanceof Error ? e.message : String(e) }));
          return loader;
        });

        if (result === null) { ctx.ui.notify("Summarization cancelled. Use /end-review to try again.", "info"); return; }
        if (result.error) { ctx.ui.notify(`Summarization failed: ${result.error}`, "error"); return; }

        setReviewWidget(ctx, false);
        reviewOriginId = undefined;
        pi.appendEntry(REVIEW_STATE_TYPE, { active: false });

        if (result.cancelled) { ctx.ui.notify("Navigation cancelled", "info"); return; }
        if (!ctx.ui.getEditorText().trim()) ctx.ui.setEditorText("Act on the code review");
        ctx.ui.notify("Review complete! Returned to original position.", "info");
      } else {
        try {
          const result = await ctx.navigateTree(originId!, { summarize: false });
          if (result.cancelled) { ctx.ui.notify("Navigation cancelled. Use /end-review to try again.", "info"); return; }
          setReviewWidget(ctx, false);
          reviewOriginId = undefined;
          pi.appendEntry(REVIEW_STATE_TYPE, { active: false });
          ctx.ui.notify("Review complete! Returned to original position.", "info");
        } catch (e) {
          ctx.ui.notify(`Failed to return: ${e instanceof Error ? e.message : String(e)}`, "error");
        }
      }
    },
  });
}
