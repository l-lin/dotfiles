---
name: tmux
description: "Use when you need a persistent terminal environment for long-running processes, programs requiring a TTY, REPLs, debuggers, TUI apps, or concurrent terminals — while the agent continues executing other commands."
---

# tmux (agent automation) skill

## Purpose

You are not teaching the human tmux. You are using tmux yourself as a controllable terminal multiplexer to:

- run long-lived processes (servers, watchers, debuggers)
- interact with programs that need a TTY
- keep state across multiple commands (REPLs, shells)
- run multiple concurrent terminals (logs in one pane, debugger in another)

## Prime directive (don't trash the user's tmux)

Use a **dedicated session** in the user's existing tmux server.

- Session name: `ai-agent-sandbox`
- Do NOT create a separate socket (`-L`) — work within the user's existing tmux server
- Only manipulate `ai-agent-sandbox`, never touch user's other sessions

## Targets (tmux addressing)

Always use explicit targets.

- full target format: `ai-agent-sandbox:<window>.<pane>`
- examples: `ai-agent-sandbox:main.1`, `ai-agent-sandbox:1.1`

**Check indexing first** — don't assume 0 or 1:
```sh
tmux display-message -p "#{base-index}"
```

## Standard workflow

### 1) Ensure session exists

```sh
tmux start-server
tmux has-session -t ai-agent-sandbox 2>/dev/null \
  || tmux new-session -d -s ai-agent-sandbox -n main
```

### 2) Create panes/windows as needed

```sh
tmux split-window -t ai-agent-sandbox:main -h
tmux select-layout -t ai-agent-sandbox:main even-horizontal
```

### 3) Send commands

```sh
tmux send-keys -t ai-agent-sandbox:main.1 "bash -lc 'rg -n \"TODO\" .'" C-m
```

- Prefer `bash -lc '…'` for a predictable shell environment
- Keep the tmux string simple; let `bash -lc` handle quoting complexity

### 4) Synchronize — never use `sleep`

Use `tmux wait-for` for deterministic completion:

```sh
TOKEN="AI_AGENT_DONE_$$"

# send command in pane, signal token on finish
tmux send-keys -t ai-agent-sandbox:main.1 \
  "bash -lc 'set -e; rg -n \"TODO\" .; tmux wait-for -S ${TOKEN}'" C-m

# block until done
tmux wait-for "${TOKEN}"
```

If the command might fail but you still need completion:

```sh
bash -lc 'set +e; <cmd>; echo EXIT:$?; tmux wait-for -S TOKEN'
```

### 5) Capture output

```sh
# last 200 lines
tmux capture-pane -p -t ai-agent-sandbox:main.1 -S -200
```

For full buffer, increase history first:

```sh
tmux set-option -t ai-agent-sandbox -g history-limit 20000
```

## Common recipes

### Long-lived server + health check

```sh
# start server in pane 1
tmux send-keys -t ai-agent-sandbox:main.1 "bash -lc 'bin/dev'" C-m

# check health in pane 2
tmux send-keys -t ai-agent-sandbox:main.2 "bash -lc 'sleep 1; curl -fsS localhost:3000/health'" C-m
```

Stream logs to disk:

```sh
LOG=/tmp/ai-agent-tmux-main1.log
: >"$LOG"
tmux pipe-pane -o -t ai-agent-sandbox:main.1 "cat >> '$LOG'"
```

### Stop a stuck command

```sh
tmux send-keys -t ai-agent-sandbox:main.1 C-c
```

### Interactive REPL / debugger

1. Start REPL in a pane
2. Send lines via `send-keys`
3. Capture output after each step
4. Synchronize with `wait-for` or detect prompts via captured output

## Guardrails

- Never `tmux kill-server` — kill only your session
- Always use explicit `-t <target>`
- Never `tmux attach` unless the user asked for a live view
- Don't rely on user keybindings; use the tmux CLI only

## Cleanup

```sh
tmux kill-session -t ai-agent-sandbox
```
