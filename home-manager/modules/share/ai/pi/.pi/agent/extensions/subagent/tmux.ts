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

/** Split a specific pane horizontally, return new pane ID */
export function splitPane(targetPaneId: string, cwd: string): string {
  return execSync(
    `tmux split-window -h -d -P -F '#{pane_id}' -t ${esc(targetPaneId)} -c ${esc(cwd)}`,
    { encoding: "utf-8" },
  ).trim();
}

/** Get the window ID for a given pane */
export function getWindowId(paneId: string): string {
  try {
    return execSync(
      `tmux display-message -t ${esc(paneId)} -p '#{window_id}'`,
      { encoding: "utf-8" },
    ).trim();
  } catch {
    return "";
  }
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

export function rebalance(windowId?: string): void {
  try {
    const target = windowId ? `-t ${esc(windowId)}` : "";
    execSync(`tmux select-layout ${target} even-horizontal`, {
      stdio: "ignore",
    });
  } catch {
    /* ignore */
  }
}

/** Return the visible pane index (e.g. "2") for display purposes */
export function getPaneIndex(paneId: string): string {
  try {
    return execSync(
      `tmux display-message -t ${esc(paneId)} -p '#{pane_index}'`,
      { encoding: "utf-8" },
    ).trim();
  } catch {
    return "?";
  }
}
