import * as fs from "node:fs";
import * as path from "node:path";
import type { LspDiagnosticsFileConfig } from "./types.js";

const IGNORED_DIR_NAMES = new Set([
  "node_modules",
  ".git",
  "dist",
  "build",
  ".next",
  ".test-dist",
  ".tmp-tests",
]);

export function collectTargetFiles(
  targetPath: string,
  fileConfig: LspDiagnosticsFileConfig | null,
): string[] {
  if (!fs.existsSync(targetPath)) return [];

  const stat = fs.statSync(targetPath);
  if (!stat.isDirectory()) return [targetPath];

  const allowedExtensions = getSupportedFileExtensions(fileConfig);
  return collectFilesRecursively(targetPath, allowedExtensions);
}

export function collectFilesRecursively(
  dirPath: string,
  allowedExtensions: Set<string>,
): string[] {
  const files: string[] = [];

  try {
    for (const entry of fs.readdirSync(dirPath, { withFileTypes: true })) {
      const entryPath = path.join(dirPath, entry.name);

      if (entry.isDirectory()) {
        if (!IGNORED_DIR_NAMES.has(entry.name)) {
          files.push(...collectFilesRecursively(entryPath, allowedExtensions));
        }
        continue;
      }

      if (entry.isFile()) {
        if (
          allowedExtensions.size === 0 ||
          allowedExtensions.has(path.extname(entry.name).toLowerCase())
        ) {
          files.push(entryPath);
        }
      }
    }
  } catch {
    // Ignore unreadable directories.
  }

  return files;
}

function getSupportedFileExtensions(
  fileConfig: LspDiagnosticsFileConfig | null,
): Set<string> {
  if (!fileConfig) return new Set();

  return new Set(
    Object.values(fileConfig.servers).flatMap((server) => server.fileTypes),
  );
}
