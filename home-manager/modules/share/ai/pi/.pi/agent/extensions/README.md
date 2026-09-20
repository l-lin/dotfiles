# Pi extensions

This directory contains local Pi extensions and shared support modules. Each entry below links to its directory and gives a short description of what it does.

| Extension                                   | Description                                                                                                                                          |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`active-skills`](./active-skills/)         | Shows a widget with the `SKILL.md` files loaded in the current session.                                                                              |
| [`ask-user-question`](./ask-user-question/) | Adds an interactive TUI prompt for asking the user one or more multiple-choice questions.                                                            |
| [`awesome-editor`](./awesome-editor/)       | Replaces the editor with configurable vi or emacs editing and snippet autocomplete.                                                                  |
| [`context`](./context/)                     | Shows a TUI overview of loaded extensions, skills, project context files, and usage totals.                                                          |
| [`reply`](./reply/)                         | Opens the latest assistant message in a Vim-style popup so you can annotate or yank selected text and insert review prompts into the composer.       |
| [`execution-timer`](./execution-timer/)     | Tracks each run and shows elapsed time with a simple tool-versus-agent breakdown.                                                                    |
| [`footer`](./footer/)                       | Replaces the default footer with richer status, directory, and usage lines.                                                                          |
| [`session-breakdown`](./session-breakdown/) | Analyzes Pi session history and shows activity, token, cost, and model trends in a TUI view.                                                         |
| [`skill-breakdown`](./skill-breakdown/)     | Analyzes Pi session history and shows top skills, less-used skills, and per-project skill summaries over the last 7, 30, or 90 days.                 |
| [`snippet`](./snippet/)                     | Leaves submitted prompts literal and keeps the shared snippet catalog available for `awesome-editor` `Ctrl-E` expansion.                             |
| [`token-speed`](./token-speed/)             | Tracks assistant token speed and publishes live `tok/s` snapshots over the extension event bus.                                                      |
| [`tool-settings`](./tool-settings/)         | Shared helpers for enable or disable toggles and persisted extension settings. It is support infrastructure, not a user-facing feature by itself.    |
| [`vim`](./vim/)                             | Shared Vim motion primitives used by the `reply` and `awesome-editor` extensions. It is support infrastructure, not a user-facing feature by itself. |
| [`web-fetch`](./web-fetch/)                 | Fetches a URL as readable text or raw page content.                                                                                                  |
| [`web-search`](./web-search/)               | Searches the web through Tavily, with filters and AI-generated summaries.                                                                            |
| [`working-message`](./working-message/)     | Replaces the default working message with rotating sarcastic status text and elapsed time.                                                           |
