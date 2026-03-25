# AGENTS.md

## Scope

This repo contains local Pi extensions. In practice, each top-level directory with an `index.ts` is an extension entrypoint unless the folder is clearly a shared support module, such as `tool-settings/`.

## Repo map

- `README.md`: inventory of extensions, with one relative link and one short description per entry
- `package.json`: repo-level scripts, including `npm test` and `npm run typecheck`
- `tool-settings/`: shared helpers for extension enablement and persisted settings

## Execution and validation

1. **Compiled test output can go stale.**  
   Do instead: use `npm test`, which clears `.test-dist` before running compiled Node tests.
2. **Repo-wide typecheck can fail for unrelated extensions.**
   Do instead: validate the files you changed first, then call out unrelated `npm run typecheck` failures explicitly if they appear.
3. **Docs-only changes still need concrete checks.**
   Do instead: confirm every linked extension directory exists and keep directory names exact.

## Documentation rules

1. **`README.md` is an inventory, not a changelog.**
   Do instead: list every extension directory with a relative link like `[web-search](./web-search/)` and a one-sentence description.
2. **Describe behavior, not implementation trivia.**
   Do instead: explain what the extension lets Pi do, not which helper files it imports.
3. **Call out support modules plainly.**
   Do instead: note when a folder, such as `tool-settings/`, is shared infrastructure rather than a standalone feature.
4. **Keep prose short and concrete.**
   Do instead: use active voice, specific nouns, and one brief sentence per description.

## Extension conventions

1. **Follow the local toggle pattern.**
   Do instead: when an extension can be enabled or disabled, reuse `tool-settings/` and persist state under `~/.pi/agent/settings.json`.
2. **Match the repo structure.**
   Do instead: keep each extension in its own top-level folder, with `index.ts` as the main entrypoint.
3. **Prefer narrow edits.**
   Do instead: extend the nearest existing pattern before inventing a new one.

## When you add, remove, or rename an extension

1. Update `README.md` in the same change.
2. Keep links relative to this directory.
3. Mention clearly if the folder is a support module instead of a user-facing extension.
