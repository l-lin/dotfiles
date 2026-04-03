/** Thin wrappers around tmux CLI commands */

import { execSync } from "node:child_process";

export function isInsideTmux(): boolean {
  return !!process.env.TMUX;
}

/** Shell-escape a string for safe use in tmux commands */
export function esc(s: string): string {
  return `'${s.replace(/'/g, "'\\''")}'`;
}

/** Create a new window and return its pane ID */
export function createWindow(cwd: string, name: string): string {
  const result = execSync(
    `tmux new-window -d -P -F '#{pane_id}' -c ${esc(cwd)} -n ${esc(name)}`,
    { encoding: "utf-8" },
  ).trim();
  return result;
}

/** Send literal text + Enter to a pane */
export function sendMessage(paneId: string, text: string): void {
  execSync(`tmux send-keys -t ${esc(paneId)} -l ${esc(text)}`);
  execSync(`tmux send-keys -t ${esc(paneId)} Enter`);
}

/** Send a command string to a pane (keys interpreted) */
export function sendCommand(paneId: string, cmd: string): void {
  execSync(`tmux send-keys -t ${esc(paneId)} ${esc(cmd)} C-m`);
}

export function killPane(paneId: string): void {
  try {
    execSync(`tmux kill-pane -t ${esc(paneId)}`, { stdio: "ignore" });
  } catch {
    /* pane may already be dead */
  }
}

export function paneAlive(paneId: string): boolean {
  try {
    execSync(`tmux display-message -t ${esc(paneId)} -p ""`, {
      stdio: "ignore",
    });
    return true;
  } catch {
    return false;
  }
}
