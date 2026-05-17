import * as path from "node:path";
import type { LspDiagnosticsFileConfig, SavedConfig } from "./types.js";
import { collectTargetFiles } from "./files.js";
import { resolveLspCommands, type ResolvedLspCommand } from "./resolver.js";

export interface ResolvedTargetCommand {
  resolved: ResolvedLspCommand;
  rootSourcePath: string;
}

export interface ResolvedTargetContext {
  targetPath: string;
  files: string[];
  commands: ResolvedTargetCommand[];
}

export function resolveTargetContext(
  targetInput: string | undefined,
  cwd: string,
  savedConfig: SavedConfig | null,
  fileConfig: LspDiagnosticsFileConfig | null,
): ResolvedTargetContext {
  const targetPath = path.resolve(cwd, targetInput ?? ".");
  const files = collectTargetFiles(targetPath, fileConfig);
  const commandMap = new Map<string, ResolvedTargetCommand>();

  for (const filePath of files) {
    const resolvedList = resolveLspCommands(
      [filePath],
      undefined,
      savedConfig,
      fileConfig,
    );

    for (const resolved of resolvedList) {
      const commandKey = resolved.command.join(" ");
      if (!commandMap.has(commandKey)) {
        commandMap.set(commandKey, {
          resolved,
          rootSourcePath: filePath,
        });
      }
    }
  }

  return {
    targetPath,
    files,
    commands: [...commandMap.values()],
  };
}

export function resolveFileCommands(
  filePath: string,
  savedConfig: SavedConfig | null,
  fileConfig: LspDiagnosticsFileConfig | null,
): ResolvedTargetCommand[] {
  return resolveLspCommands([filePath], undefined, savedConfig, fileConfig).map(
    (resolved) => ({
      resolved,
      rootSourcePath: filePath,
    }),
  );
}
