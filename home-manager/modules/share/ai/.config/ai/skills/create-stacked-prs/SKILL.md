---
name: create-stacked-prs
description: Use when staged changes contain a complete feature or bugfix that needs smaller, logical, dependent GitHub PRs for review.
disable-model-invocation: true
---

# Create stacked PRs

Split staged changes into reviewable PRs. Request approval before creating commits, branches, pushes, or PRs.
Use `gh` for all GitHub operations. Create draft PRs only.
This skill creates new stacks. It does not update, rebase, or merge existing stacks.

## 1. Inspect the input

1. Read repository instructions and PR conventions.
2. Inspect `git status --short`, the current branch, remotes, and the staged diff.
3. Read affected code, tests, and relevant callers to understand the complete change.
4. Identify unstaged changes, untracked files, submodules, unresolved conflicts, and existing commits outside the proposed base.
5. Stop if the index has conflicts or no staged changes.
6. Extract the Jira ticket from the branch name, such as `FOOBAR-123`.
7. Verify the Jira URL through repository configuration, existing PRs, or an available Jira tool.
8. Ask for the ticket or URL if either is missing or ambiguous. Never invent a Jira hostname or ticket details.
9. Identify the target repository and first PR base with `gh repo view` and repository conventions.
10. Check existing PRs and remote branch names for conflicts with the proposed stack.

Treat the staged diff as the complete feature input. Exclude unstaged changes and untracked files.
Include staged additions, deletions, renames, file modes, and binary files.
Stop if staged content depends on excluded files or changes. Ask the user to correct the input.
Do not silently include existing branch commits in the first PR. Ask how to handle commits outside the target base.

## 2. Propose the split

1. Map components, behavior, dependencies, and tests across the complete staged diff.
2. Choose the fewest PRs that separate distinct review concerns.
3. Order prerequisites before consumers. Keep each PR coherent, buildable, and testable.
4. Keep behavior tests with their implementation. Separate tests only when they remain useful and pass independently.
5. Split individual files into logical changes when file boundaries do not match review boundaries.
6. Keep required schema compatibility and rollout order explicit.
7. Avoid temporary stubs, broken intermediate states, and code added only to support the split.
8. Use one PR if no safe, useful split exists. Explain the reason.

Present a plan with these fields for each PR:

- Position, title, branch, and base branch.
- Purpose, included changes, dependencies, and review boundary.
- Tests and checks to run.

Use branch names such as `FOOBAR-123/01-progress-model`, subject to repository conventions.
Use titles such as `feat(FOOBAR-123): add the progress model`.
The first PR targets the approved integration branch. Each later PR targets the preceding stack branch.
Use the source HEAD as the starting commit unless the user approves another starting commit.
Include the starting commit, a proposed whole-feature diagram, and any exclusions or risks.
Explain that the original branch, index, and working tree will remain unchanged.
Request approval for the split, commits, pushes, and draft PR creation. Wait for approval.
Request new approval if the split or scope must change.

## 3. Build the stack without changing the source

1. Recheck the source HEAD, index, and working tree against the inspected input.
2. Stop and inspect again if the input changed after approval.
3. Record the source branch, HEAD, status, staged patch, and staged tree before building.
4. Save the complete staged patch with `git diff --cached --binary --full-index HEAD` outside the source working tree.
5. Record the staged tree with `git write-tree`. Do not change the source index.
6. Create a separate temporary worktree at the approved starting commit.
7. Build the first stack branch there. Create each subsequent branch from the preceding stack tip.
8. Apply only the approved changes for each PR. Use explicit paths or selected hunks when staging.
9. Inspect each staged diff before committing. Check for unrelated changes and secrets.
10. Run the planned checks at each stack tip. Record the exact commands and results.
11. Commit each logical change with the ticket and repository commit conventions.

Keep the original branch and staged changes as the recovery source.
Do not use `git reset --hard`, `git clean`, or a stash to prepare the source working tree.
Do not force-push, rewrite existing branches, bypass hooks, or overwrite remote branches.
Stop for unexpected failures. Do not repair unrelated code or add temporary implementation changes.

## 4. Verify the complete stack

1. Compare the final stack tree with the recorded staged tree. Require an exact tree match.
2. Check each adjacent branch diff against the approved PR boundary.
3. Check that the first PR has no unapproved inherited commits.
4. Run the complete feature checks at the final stack tip.
5. Verify that the source HEAD, index, and working tree remain unchanged.
6. Report failed or unavailable checks before publishing. Request approval to publish with those limits.

Use `git rev-parse <final-branch>^{tree}` to obtain the final tree.
Compare tree IDs, not patch text. Different commit boundaries must still produce exactly the staged result.
If the trees differ, correct the split before publishing. Do not silently drop or add changes.

## 5. Publish draft PRs

1. Push each approved branch without force, in dependency order.
2. Load `references/PR-TEMPLATE.md` and draft a description for each PR.
3. Create each PR with `gh pr create --draft --base <base> --head <branch> --title <title> --body-file <file>`.
4. Record each returned PR URL. Do not infer PR numbers.
5. Update all descriptions with `gh pr edit --body-file <file>` after every PR URL is available.
6. Use the same ordered stack list and whole-feature diagram in every description.
7. Highlight only the current PR components in each overview. Mark the current PR in its stack list.
8. Verify titles, draft status, bases, links, descriptions, and file boundaries through `gh pr view` and `gh pr diff`.

If publication stops, report the branches and PRs already created.
Inspect remote state before retrying. Do not create duplicate PRs or delete published work automatically.
Never merge PRs or change existing stack bases as part of this skill.

## 6. Report the result

List PR URLs in merge order. State each PR base and the checks that ran.
State any skipped checks, failures, or manual rollout requirements.
Name the unchanged source branch and the retained staged changes.
Report any remaining temporary worktree or recovery files with their paths.
Remove only temporary files and worktrees created by this run after successful verification.
Do not delete the original branch, stack branches, or source changes.
