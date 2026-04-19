# Pi extensions

This directory contains local Pi extensions and one shared support module. Each entry below links to its directory and gives a short description of what it does.

| Extension                                             | Description                                                                                                                                       |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`active-skills`](./active-skills/)                   | Shows a widget with the `SKILL.md` files loaded in the current session.                                                                           |
| [`ask-user-question`](./ask-user-question/)           | Adds an interactive TUI prompt for asking the user one or more multiple-choice questions.                                                         |
| [`awesome-editor`](./awesome-editor/)                 | Replaces the editor with Vim-style modal editing and snippet autocomplete.                                                                        |
| [`btw`](./btw/)                                       | A pi extension that lets you have a separate, parallel conversation with the LLM while the main agent is working.                                 |
| [`context`](./context/)                               | Shows a TUI overview of loaded extensions, skills, project context files, and usage totals.                                                       |
| [`enforce-modern-cli`](./enforce-modern-cli/)         | Blocks legacy `grep` and `find` calls in Bash and points the agent to `rg` and `fd` instead.                                                      |
| [`execution-timer`](./execution-timer/)               | Tracks each run and shows elapsed time with a simple tool-versus-agent breakdown.                                                                 |
| [`footer`](./footer/)                                 | Replaces the default footer with richer status, directory, and usage lines...                                                                     |
| [`github-copilot`](./github-copilot/)                 | Shows Copilot premium usage and adds commands for refreshing usage and browsing Copilot models.                                                   |
| [`lsp-diagnostics`](./lsp-diagnostics/)               | Runs LSP diagnostics after edits and writes, then surfaces problems right away.                                                                   |
| [`minimal-mode`](./minimal-mode/)                     | Re-renders the built-in `read` tool in a compact view and removes `find`, `grep`, and `ls` from minimal-mode sessions.                            |
| [`model-switcher`](./model-switcher/)                 | Rotates through configured models with a command and keyboard shortcut.                                                                           |
| [`oracle`](./oracle/)                                 | Gets a second opinion from another AI model, optionally with files in context.                                                                    |
| [`plan-mode`](./plan-mode/)                           | Adds a read-only planning mode with safe Bash limits, todo tracking, and progress UI.                                                             |
| [`pre-tool-safety`](./pre-tool-safety/)               | Calls an external safety hook before risky Bash commands or sensitive file reads.                                                                 |
| [`sandbox`](./sandbox/)                               | Wraps bash commands in OS-level sandboxing (macOS sandbox-exec, Linux bubblewrap) with configurable filesystem and network restrictions.          |
| [`session-breakdown`](./session-breakdown/)           | Analyzes Pi session history and shows activity, token, cost, and model trends in a TUI view.                                                      |
| [`skill-breakdown`](./skill-breakdown/)               | Analyzes Pi session history and shows top skills, less-used skills, and per-project skill summaries over the last 7, 30, or 90 days.              |
| [`snippet`](./snippet/)                               | Expands prompt snippets before the input is sent to the agent.                                                                                    |
| [`subagent`](./subagent/)                             | Spawns interactive Pi subagents in tmux split panes and brings their results back to the main session.                                            |
| [`system-prompt-selector`](./system-prompt-selector/) | Lets you switch system prompts from discovered agent markdown files.                                                                              |
| [`tool-settings`](./tool-settings/)                   | Shared helpers for enable or disable toggles and persisted extension settings. It is support infrastructure, not a user-facing feature by itself. |
| [`web-fetch`](./web-fetch/)                           | Fetches a URL as readable text or raw page content.                                                                                               |
| [`web-search`](./web-search/)                         | Searches the web through Tavily, with filters and AI-generated summaries.                                                                         |
| [`working-message`](./working-message/)               | Replaces the default working message with rotating sarcastic status text and elapsed time.                                                        |
| [`yank`](./yank/)                                     | Copies the latest assistant text output to the system clipboard.                                                                                  |
