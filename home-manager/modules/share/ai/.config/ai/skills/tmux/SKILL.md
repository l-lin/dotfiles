---
name: tmux
description: Use when a task needs a persistent terminal, a TTY-only program, a REPL or debugger, or concurrent terminals while the agent runs other commands. Use ordinary command execution for short, noninteractive tasks.
disable-model-invocation: false
---

1. **Isolate.** Use only `ai-agent-sandbox` on the existing tmux server. Check that `tmux` is installed. Do not use alternate sockets (`-L`, `-S`), change global options (`-g`), or touch other sessions.

   ```sh
   tmux has-session -t '=ai-agent-sandbox' 2>/dev/null \
     || tmux new-session -d -s ai-agent-sandbox -n main
   ```

2. **Target.** Create a fresh window for each task, record its pane ID, and use that ID for every pane operation. Do not assume pane indexes or reuse a pane that may contain a running job. Set the working directory explicitly; use a clean Bash shell for the command examples below.

   ```sh
   pane=$(tmux new-window -d -P -F '#{pane_id}' \
     -t '=ai-agent-sandbox' -c "$PWD" 'bash --noprofile --norc')
   ```

3. **Verify.** Send text literally, then send `Enter` separately. For a finite command, report its exit status and signal completion even when it fails. Check for `uuidgen` and a timeout utility before launching this example; replace `printf "ready\\n"` with the task command, keeping the status and signal suffix outside it.

   ```sh
   command -v uuidgen >/dev/null || exit 1
   wait_timeout=$(command -v timeout || command -v gtimeout) || exit 1
   token="ai-agent-$(uuidgen)"
   tmux send-keys -l -t "$pane" \
     "bash -c 'printf \"ready\\n\"; status=\$?; printf \"EXIT:%s\\n\" \"\$status\"; tmux wait-for -S \"$token\"'"
   tmux send-keys -t "$pane" Enter
   "$wait_timeout" 30s tmux wait-for "$token"
   tmux capture-pane -p -t "$pane" -S -200
   ```

   Choose a timeout suited to the task. A completion signal proves only that the wrapper finished; inspect `EXIT:` and the output to determine success. A timeout stops waiting, not the pane's job. Capture output and decide whether to continue or interrupt; do not blindly resend commands. If no timeout utility exists, use bounded polling instead of an unbounded `wait-for`.

4. **Verify readiness.** Servers and interactive programs do not finish after each input. Use a bounded health probe for servers or bounded prompt polling for REPLs and debuggers. Inspect captured output before sending the next input. A fixed sleep is not evidence of readiness. Capture only includes retained terminal history, not a complete log.

5. **Preserve.** Leave jobs needed for the user's next step running and report their pane IDs, status, and how to inspect or stop them. Interrupt or remove only panes you created:

   ```sh
   tmux send-keys -t "$pane" C-c
   tmux capture-pane -p -t "$pane" -S -200
   # After confirming the task no longer needs this pane:
   tmux kill-pane -t "$pane"
   ```

   Never kill the tmux server. Kill `ai-agent-sandbox` only if you created it and all its jobs are disposable. Do not attach unless the user requests a live view; use the CLI, not user keybindings.
