---
name: tmux
description: "Use tmux as an automation harness: create isolated tmux servers/sessions, split panes, send keys/commands, capture pane output, and synchronize with `tmux wait-for`. Use when you need an interactive/long-running terminal environment (debugging servers, REPLs, tui apps, or running other tools) while the agent continues executing commands."
---

# tmux (agent automation) skill

## Purpose

You are not teaching the human tmux. You are using tmux yourself as a controllable terminal multiplexer so you can:

- run long-lived processes (servers, watchers, debuggers)
- interact with programs that need a TTY
- keep state across multiple commands (REPLs, shells)
- run multiple concurrent terminals (logs in one pane, debugger in another)

## Prime directive (don't trash the user's tmux)

Use a **dedicated session** in the user's existing tmux server to avoid interfering with their work sessions.

- Use session name: `ai-agent-sandbox`
- Do NOT create a separate socket (`-L`) — work within the user's existing tmux server
- Only manipulate the `ai-agent-sandbox` session, never touch user's other sessions

Define a consistent session target in your own head:

- **AI_AGENT_SESSION** := `ai-agent-sandbox`

## Targets (tmux addressing)

Use explicit targets so you don't "send keys into the wrong universe".

- session: `ai-agent-sandbox`
- window: `1` or `main`
- pane: `1`
- full target examples:
  - `ai-agent-sandbox:1.1`
  - `ai-agent-sandbox:main.1`

**Note**: If user's tmux uses 1-based indexing (`base-index 1`), adjust accordingly. Default tmux uses 0-based indexing.

## Standard workflow

### 1) Ensure server + session exists

```sh
tmux start-server

tmux has-session -t ai-agent-sandbox 2>/dev/null \
  || tmux new-session -d -s ai-agent-sandbox -n main
```

### 2) Create panes/windows as needed

```sh
# split current pane into two
 tmux split-window -t ai-agent-sandbox:main -h

# optional: make it readable
 tmux select-layout -t ai-agent-sandbox:main even-horizontal
```

### 3) Send commands/keys

Send a command followed by Enter (`C-m`).

```sh
tmux send-keys -t ai-agent-sandbox:main.1 "bash -lc 'rg -n \"TODO\" .'" C-m
```

Key notes:

- Prefer `bash -lc '…'` so the command runs in a predictable shell.
- Be careful with quoting. When in doubt, keep the tmux string simple and let `bash -lc` handle the complexity.

### 4) Synchronize (don't guess with sleep)

Use `tmux wait-for` for deterministic completion.

Pattern:

- Pick a unique token: `AI_AGENT_DONE_<something>`
- In the pane: run command, then signal token.
- Outside: wait for token.

```sh
TOKEN="AI_AGENT_DONE_$$"

# in pane
 tmux send-keys -t ai-agent-sandbox:main.1 \
  "bash -lc 'set -e; rg -n \"TODO\" .; tmux wait-for -S ${TOKEN}'" C-m

# outside
 tmux wait-for "${TOKEN}"
```

If the tool might fail but you still want completion, do:

```sh
bash -lc 'set +e; <cmd>; echo EXIT:$?; tmux wait-for -S TOKEN'
```

### 5) Capture output for analysis

```sh
# last 200 lines
tmux capture-pane -p -t ai-agent-sandbox:main.1 -S -200
```

If you need the _entire_ buffer, first increase history in the isolated server:

```sh
tmux set-option -t ai-agent-sandbox -g history-limit 20000
```

## Common automation recipes

### Run a long-lived server + tail logs

- Pane 1: start server
- Pane 2: follow logs / run curl

```sh
# server
tmux send-keys -t ai-agent-sandbox:main.1 "bash -lc 'bin/dev'" C-m

# logs/test pane
tmux send-keys -t ai-agent-sandbox:main.2 "bash -lc 'sleep 1; curl -fsS localhost:3000/health || true'" C-m
```

If you need ongoing logs on disk:

```sh
LOG=/tmp/ai-agent-tmux-main1.log
: >"$LOG"
tmux pipe-pane -o -t ai-agent-sandbox:main.1 "cat >> '$LOG'"
```

### Stop a stuck command

Prefer targeted interruption over murdering the whole server.

```sh
# Ctrl-C
tmux send-keys -t ai-agent-sandbox:main.1 C-c

# If a shell is wedged, you can also send Enter to get a prompt back
 tmux send-keys -t ai-agent-sandbox:main.1 C-m
```

### Interactive REPL / debugger

- Start the REPL in a pane.
- Send subsequent lines via `send-keys`.
- Capture output after each step.
- Synchronize with `wait-for` when you can (or detect prompts via captured output).

## Guardrails

- Don't use `tmux kill-server` unless explicitly told; kill only the session you created.
- Always use explicit `-t <target>`.
- Don't depend on user keybindings/prefix; automation should be via `tmux` CLI.
- Don't attach (`tmux attach`) unless the user asked for a live view.

## Cleanup

When done (and only for the isolated server/session):

```sh
tmux kill-session -t ai-agent-sandbox
```

## Output expectations (what you produce in the chat)

When you use this skill in a task, include:

- the tmux targets you created/used (session/window/pane)
- the exact commands you sent
- captured output snippets relevant to the task
- what is still running (if anything) and how to stop it
