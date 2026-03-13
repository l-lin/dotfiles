/**
 * Settings reading and tool status
 */

import * as fs from "node:fs";
import { SETTINGS_PATH, type SettingsStructure } from "./constants.js";

export function readSettings(): SettingsStructure | null {
  try {
    const raw = fs.readFileSync(SETTINGS_PATH, "utf-8");
    return JSON.parse(raw) as SettingsStructure;
  } catch {
    return null;
  }
}

export function getToolStatus(): Map<string, boolean> {
  const settings = readSettings();
  const ext = settings?.extensionSettings ?? {};

  return new Map([
    ["ask-user-question", ext.askUserQuestion?.enabled !== false],
    ["subagent", ext.subagent?.enabled !== false],
    ["web-fetch", ext.webFetch?.enabled !== false],
    ["web-search", ext.webSearch?.enabled !== false],
  ]);
}
