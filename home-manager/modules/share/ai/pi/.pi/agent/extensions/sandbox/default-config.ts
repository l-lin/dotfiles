import { join } from "node:path";

export interface DefaultSandboxConfigOptions {
  platform?: NodeJS.Platform;
  tmuxTmpDir?: string;
  uid?: number;
}

export interface DefaultSandboxConfig {
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
}

export function getDefaultAllowedUnixSockets(
  options: DefaultSandboxConfigOptions = {},
): string[] {
  const platform = options.platform ?? process.platform;
  const uid = options.uid ?? process.getuid?.();

  if (platform !== "darwin" || uid === undefined) {
    return [];
  }

  const tmuxTmpDir =
    options.tmuxTmpDir ?? process.env.TMUX_TMPDIR ?? "/private/tmp";
  return [join(tmuxTmpDir, `tmux-${uid}`)];
}

export function getDefaultAllowWritePaths(
  options: DefaultSandboxConfigOptions = {},
): string[] {
  const platform = options.platform ?? process.platform;
  const common = [".", "/tmp", "/private/tmp", "~/.cache", "~/.m2"];

  if (platform === "darwin") {
    return [...common, "~/Library/Application Support/kotlin"];
  }

  return common;
}

export function createDefaultConfig(
  options: DefaultSandboxConfigOptions = {},
): DefaultSandboxConfig {
  const platform = options.platform ?? process.platform;
  const allowUnixSockets = getDefaultAllowedUnixSockets(options);
  const allowWrite = getDefaultAllowWritePaths(options);
  const allowLocalBinding = platform === "darwin";

  return {
    enabled: true,
    network: {
      allowedDomains: [
        "npmjs.org",
        "*.npmjs.org",
        "registry.npmjs.org",
        "registry.yarnpkg.com",
        "pypi.org",
        "*.pypi.org",
        "github.com",
        "*.github.com",
        "api.github.com",
        "raw.githubusercontent.com",
      ],
      deniedDomains: [],
      ...(allowUnixSockets.length > 0 ? { allowUnixSockets } : {}),
      ...(allowLocalBinding ? { allowLocalBinding: true } : {}),
    },
    filesystem: {
      denyRead: ["~/.ssh", "~/.aws", "~/.gnupg"],
      allowWrite,
      denyWrite: [".env", ".env.*", "*.pem", "*.key"],
    },
  };
}
