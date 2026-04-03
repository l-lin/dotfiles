export interface SandboxConfig {
  enabled: boolean;
  network: {
    allowedDomains: string[];
    deniedDomains: string[];
    allowUnixSockets?: string[];
    allowLocalBinding?: boolean;
  };
  filesystem: {
    denyRead: string[];
    allowWrite: string[];
    denyWrite: string[];
  };
  ignoreViolations?: Record<string, string[]>;
  enableWeakerNestedSandbox?: boolean;
}

export interface SandboxRuntimeState {
  enabled: boolean;
  initialized: boolean;
}

export interface SandboxNotification {
  message: string;
  type: "info" | "warning" | "error";
}

export interface DisableSandboxArgs {
  state: SandboxRuntimeState;
  reset: () => Promise<void>;
  emitStateChanged: (enabled: boolean) => void;
}

export interface EnsureSandboxActiveArgs extends DisableSandboxArgs {
  settingsEnabled: boolean;
  noSandbox: boolean;
  platform: NodeJS.Platform;
  cwd: string;
  loadConfig: (cwd: string) => SandboxConfig;
  initialize: (config: SandboxConfig) => Promise<void>;
}

export async function disableSandbox(args: DisableSandboxArgs): Promise<void> {
  const wasActive = args.state.enabled || args.state.initialized;

  if (args.state.initialized) {
    try {
      await args.reset();
    } catch {
      // Ignore cleanup errors while disabling the sandbox.
    }
  }

  args.state.enabled = false;
  args.state.initialized = false;

  if (wasActive) {
    args.emitStateChanged(false);
  }
}

export async function ensureSandboxActive(
  args: EnsureSandboxActiveArgs,
): Promise<SandboxNotification | undefined> {
  if (!args.settingsEnabled) {
    await disableSandbox(args);
    return {
      message: "Sandbox disabled via extension setting",
      type: "info",
    };
  }

  if (args.noSandbox) {
    await disableSandbox(args);
    return {
      message: "Sandbox disabled via --no-sandbox",
      type: "warning",
    };
  }

  const config = args.loadConfig(args.cwd);

  if (!config.enabled) {
    await disableSandbox(args);
    return {
      message: "Sandbox disabled via config",
      type: "info",
    };
  }

  if (args.platform !== "darwin" && args.platform !== "linux") {
    await disableSandbox(args);
    return {
      message: `Sandbox not supported on ${args.platform}`,
      type: "warning",
    };
  }

  try {
    await args.initialize(config);
    args.state.enabled = true;
    args.state.initialized = true;
    args.emitStateChanged(true);
    return undefined;
  } catch (error) {
    args.state.enabled = false;
    args.state.initialized = false;
    return {
      message: `Sandbox initialization failed: ${error instanceof Error ? error.message : String(error)}`,
      type: "error",
    };
  }
}
