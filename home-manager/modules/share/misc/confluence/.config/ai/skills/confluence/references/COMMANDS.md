# Atlassian CLI Confluence page command patterns

Verified against local `acli --help`, `acli confluence --help`, and `acli confluence page --help` on 2026-08-10.

## Inspect one page

```bash
acli confluence page view --id 123456789
acli confluence page view --id 123456789 --body-format storage
acli confluence page view --id 123456789 --include-labels --include-version --json
acli confluence page view --id 123456789 --include-direct-children
```

## Troubleshoot

```bash
acli confluence auth status
acli confluence auth login
acli confluence auth switch
acli confluence page --help
acli confluence page view --id 123456789 --json
```

## Capability note

As of the verified help output above, local `acli confluence page` exposes `view` only. Running `acli confluence page create --help` and `acli confluence page edit --help` returns the same top-level page help, not dedicated create or edit commands. If a request needs page creation or editing, confirm that gap before promising an `acli` workflow.
