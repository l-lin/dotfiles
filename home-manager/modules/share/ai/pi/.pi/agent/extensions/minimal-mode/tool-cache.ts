import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
} from "@mariozechner/pi-coding-agent";

type BuiltInToolFactories = {
  bash: typeof createBashToolDefinition;
  edit: typeof createEditToolDefinition;
  find: typeof createFindToolDefinition;
  grep: typeof createGrepToolDefinition;
  ls: typeof createLsToolDefinition;
  read: typeof createReadToolDefinition;
  write: typeof createWriteToolDefinition;
};

export type BuiltInTools = {
  [ToolName in keyof BuiltInToolFactories]: ReturnType<
    BuiltInToolFactories[ToolName]
  >;
};

const toolCache = new Map<string, ReturnType<typeof createBuiltInTools>>();

function createBuiltInTools(cwd: string) {
  return {
    bash: createBashToolDefinition(cwd),
    edit: createEditToolDefinition(cwd),
    grep: createGrepToolDefinition(cwd),
    find: createFindToolDefinition(cwd),
    ls: createLsToolDefinition(cwd),
    read: createReadToolDefinition(cwd),
    write: createWriteToolDefinition(cwd),
  } satisfies BuiltInTools;
}

export function getBuiltInTools(cwd: string) {
  const cached = toolCache.get(cwd);
  if (cached) return cached;

  const tools = createBuiltInTools(cwd);
  toolCache.set(cwd, tools);
  return tools;
}
