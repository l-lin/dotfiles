import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { UserRules } from "./settings.js";
import {
  baseForms,
  rebuiltForms,
  expandHome,
  pathEquals,
  pathStartsWith,
} from "./paths.js";
import { selfProtectCheck, type ProtectedSet } from "./protection.js";

const GIT_GLOBAL_OPTS = String.raw`(?:-{1,2}[A-Za-z][\w-]*(?:[ =]\S+)?\s+){0,8}`;

const RAW_DEVICE = String.raw`sd[a-z](?:\d+)?|hd[a-z](?:\d+)?|nvme\d+n\d+(?:p\d+)?|mmcblk\d+(?:p\d+)?|vd[a-z](?:\d+)?|xvd[a-z](?:\d+)?`;

const BASH_DANGER_RULES: Array<{
  id: string;
  pattern: RegExp;
  reason: string;
}> = [
  {
    id: "rm-recursive",
    pattern:
      /\brm\b[^;|&]*(\s-(?:[a-zA-Z]*r[a-zA-Z]*f?|[a-zA-Z]*f[a-zA-Z]*r)\b|--recursive)/i,
    reason: "recursive delete (rm -r)",
  },
  {
    id: "rm-root",
    pattern:
      /\brm\s+(-[a-zA-Z]*\s+)*(--recursive\s+)?(\/|\/etc|\/usr|\/var|~|\$HOME)(?:\s|$)/i,
    reason: "delete root/system/home directory",
  },
  { id: "sudo", pattern: /\bsudo\b/i, reason: "privilege escalation (sudo)" },
  {
    id: "chmod-777",
    pattern:
      /\bchmod\b[^;|&]*\b(0?777|[2467][0-7][0-7][1357]|a\+rwx|ugo\+rwx|ugo=rwx|[ug]\+s|[ug]o\+s)\b/i,
    reason: "permission weakening (chmod 777/setuid)",
  },
  {
    id: "raw-device",
    pattern: new RegExp(
      String.raw`(?:\b(?:cp|mv|tee|dd)\b[^;|&]{0,256}\s|>\s*|of=)\/dev\/(?:${RAW_DEVICE})\b|\bmkfs\.`,
      "i",
    ),
    reason: "raw device write/format",
  },
  {
    id: "git-push-force",
    pattern: new RegExp(
      String.raw`\bgit\s+${GIT_GLOBAL_OPTS}push\b[^;|&]*(-f\b|--force\b)`,
      "i",
    ),
    reason: "git push --force",
  },
  {
    id: "git-reset-hard",
    pattern: new RegExp(
      String.raw`\bgit\s+${GIT_GLOBAL_OPTS}reset\s+--hard\b`,
      "i",
    ),
    reason: "git reset --hard",
  },
  {
    id: "git-clean-force",
    pattern: new RegExp(
      String.raw`\bgit\s+${GIT_GLOBAL_OPTS}clean\b[^;|&]*(\s-[a-zA-Z]*f|--force)`,
      "i",
    ),
    reason: "git clean -f",
  },
  {
    id: "git-checkout-dot",
    pattern: new RegExp(
      String.raw`\bgit\s+${GIT_GLOBAL_OPTS}checkout\s+(--\s+)?\.(?:\s|$)`,
      "i",
    ),
    reason: "git checkout . (discard working tree)",
  },
  {
    id: "git-restore",
    pattern: new RegExp(String.raw`\bgit\s+${GIT_GLOBAL_OPTS}restore\b`, "i"),
    reason: "git restore (discard changes)",
  },
  {
    id: "remote-exec",
    pattern:
      /\b(curl|wget)\b[^;|&|]*(?:\|[^;|&|]*){0,8}\|\s*(sudo\s+)?(ba|z|da)?sh\b/i,
    reason: "remote code execution (curl|sh)",
  },
  {
    id: "gh-repo",
    pattern: /\bgh\s+repo\s+(create|delete|rename|archive)\b/i,
    reason: "GitHub repository-level change",
  },
  {
    id: "gh-release",
    pattern: /\bgh\s+release\s+(create|delete|edit)\b/i,
    reason: "GitHub release change",
  },
  {
    id: "fork-bomb",
    pattern:
      /:\(\)\s*\{|(\w{1,64})\s*\(\)\s*\{[^}|&]*\|[^}|&]*&\s*\}\s*;\s*\1\b/,
    reason: "fork bomb",
  },
];

type RuleVerdict = "allow" | "deny" | "gray" | "ask";

export interface RuleResult {
  verdict: RuleVerdict;
  reason?: string;
  detail?: string;
}

export const BASH_MAX_MATCH_LEN = 8192;

export function classifyBash(
  command: string,
  denyFloorEnabled: boolean,
): RuleResult {
  if (denyFloorEnabled) {
    for (const rule of BASH_DANGER_RULES) {
      if (rule.pattern.test(command)) {
        return { verdict: "deny", reason: `rule ${rule.id}: ${rule.reason}` };
      }
    }
  }

  if (!command.trim()) {
    return { verdict: "allow", reason: "empty command" };
  }

  return { verdict: "gray", reason: "no built-in allowlist" };
}

const S0_SECRET = [
  /\.ssh(\/|$)/i,
  /\.aws(\/|$)/i,
  /\.gnupg(\/|$)/i,
  /(^|\/)\.env(\.|$)/i,
  /credentials?(\.|\/|$)/i,
  /(^|\/)id_rsa/i,
  /\.pem$/i,
  /_history$/i,
  /\.config\/gh(\/|$)/i,
  /\.(?:pi|omp)\/agent\/auth\.json$/i,
  /(^|\/)\.netrc$/i,
  /(^|\/)\.npmrc$/i,
  /(^|\/)\.pypirc$/i,
  /(^|\/)\.envrc$/i,
  /(^|\/)\.vault-token$/i,
  /\.kube(\/|$)/i,
  /\.docker\/config\.json$/i,
  /\.gem\/credentials$/i,
];

const S1_SYSTEM_DIRS = [
  /^\/etc(\/|$)/i,
  /^\/private\/(etc|var)(\/|$)/i,
  /^\/usr(\/|$)/i,
  /^\/var(\/|$)/i,
  /^\/System(\/|$)/i,
];

const S1_SYSTEM_FILES = [/(^|\/)authorized_keys$/i];

const S1_SYSTEM = [...S1_SYSTEM_DIRS, ...S1_SYSTEM_FILES];

export function computeTmpdirBases(
  platform: NodeJS.Platform,
  tmp: string,
  realpath: (rawPath: string) => string | null,
): string[] {
  if (platform !== "darwin" || !tmp) {
    return [];
  }

  const lexical = path.resolve(tmp);
  const real = realpath(lexical);
  const bases = real === null ? [lexical] : [lexical, real];
  const confstrFamily = /^(?:\/private)?\/var\/folders\/[^/]+\/[^/]+(?:\/|$)/;

  return bases.every((base) => confstrFamily.test(base)) ? bases : [];
}

function defaultTmpdirBases(): string[] {
  return computeTmpdirBases(process.platform, os.tmpdir(), (rawPath) => {
    try {
      return fs.realpathSync(rawPath);
    } catch {
      return null;
    }
  });
}

let tmpdirExemptBases = defaultTmpdirBases();

export function setTmpdirBasesForTests(bases: string[] | null): void {
  tmpdirExemptBases = bases ?? defaultTmpdirBases();
}

const tmpdirExempt = (forms: string[]): boolean =>
  tmpdirExemptBases.length > 0 &&
  forms.every((form) =>
    tmpdirExemptBases.some(
      (base) => form === base || form.startsWith(base + path.sep),
    ),
  );

const S2_USER_RC = [
  /\.(bashrc|zshrc|profile|bash_profile|gitconfig)$/i,
  /crontab/i,
  /Library\/LaunchAgents(\/|$)/i,
  /\.config\/systemd(\/|$)/i,
];

const S3_GIT_META = [
  /(^|\/)\.git\/(hooks|config|modules)(\/|$)/i,
  /(^|\/)\.gitmodules$/i,
];

function classifyPath(
  rawPath: string,
  cwd: string,
  isWrite: boolean,
  denyFloorEnabled: boolean,
): RuleResult {
  const absolutePath = path.resolve(cwd, expandHome(rawPath));
  const forms = rebuiltForms(absolutePath);
  const matchesPathRules = (rules: RegExp[]) =>
    forms.some((form) => rules.some((runEnd) => runEnd.test(form)));
  const restrictedPath = (reason: string): RuleResult => ({
    verdict: denyFloorEnabled ? "deny" : "gray",
    reason,
  });

  if (matchesPathRules(S0_SECRET)) {
    return restrictedPath(`S0 secrets/credential path: ${rawPath}`);
  }

  const s1Rules = tmpdirExempt(forms) ? S1_SYSTEM_FILES : S1_SYSTEM;

  if (!isWrite) {
    if (matchesPathRules(s1Rules)) {
      return { verdict: "gray", reason: `read system config path: ${rawPath}` };
    }

    return { verdict: "allow" };
  }

  if (matchesPathRules(s1Rules)) {
    return restrictedPath(`write to system directory: ${rawPath}`);
  }

  if (matchesPathRules(S3_GIT_META)) {
    return restrictedPath(
      `write to .git metadata (executable code entry point): ${rawPath}`,
    );
  }

  if (matchesPathRules(S2_USER_RC)) {
    return {
      verdict: "gray",
      reason: `write to user config/persistence entry point: ${rawPath}`,
    };
  }

  const projectBases = new Set(baseForms(cwd));
  const isInsideProject = (form: string) =>
    [...projectBases].some(
      (base) => form === base || form.startsWith(base + path.sep),
    );

  if (forms.every(isInsideProject)) {
    return { verdict: "allow" };
  }

  return {
    verdict: "gray",
    reason: `write outside project directory (CWD): ${rawPath}`,
  };
}

function toolKind(toolName: string): "command" | "file" | null {
  switch (toolName) {
    case "bash":
    case "powershell":
      return "command";
    case "read":
    case "write":
    case "edit":
    case "grep":
    case "find":
    case "ls":
      return "file";
    default:
      return null;
  }
}

export function isScopeTool(toolName: string): boolean {
  return toolName === "grep" || toolName === "find" || toolName === "ls";
}

const SCOPE_S0_MAX_DEPTH = 8;

const SCOPE_S0_MAX_ENTRIES = 500;

function scopeContainsS0(root: string): boolean {
  let directories: string[] = [root];
  let entries = 0;

  for (
    let depth = 0;
    depth <= SCOPE_S0_MAX_DEPTH && directories.length > 0;
    depth++
  ) {
    const next: string[] = [];

    for (const directory of directories) {
      let names: string[];

      try {
        names = fs.readdirSync(directory);
      } catch {
        continue;
      }

      for (const name of names) {
        if (name === "node_modules" || name === ".git") {
          continue;
        }

        const entryPath = path.join(directory, name);

        if (S0_SECRET.some((runEnd) => runEnd.test(entryPath))) {
          return true;
        }

        if (++entries > SCOPE_S0_MAX_ENTRIES) {
          return false;
        }

        let stats: fs.Stats;

        try {
          stats = fs.lstatSync(entryPath);
        } catch {
          continue;
        }

        if (stats.isDirectory()) {
          next.push(entryPath);
        }
      }
    }

    directories = next;
  }

  return false;
}

function userRuleTarget(
  toolName: string,
  input: Record<string, unknown>,
  cwd: string,
): string | null {
  const kind = toolKind(toolName);

  if (kind === "command") {
    return String(input.command ?? "");
  }

  if (kind === "file") {
    const rawPath =
      typeof input.path === "string" && input.path ? input.path : null;

    if (!rawPath) {
      return isScopeTool(toolName) ? path.resolve(cwd) : null;
    }

    return path.resolve(cwd, expandHome(rawPath));
  }

  return null;
}

export const BASH_PATH_TOKENS =
  /(?:~|\$HOME)(?:\/[\w.@*-]+)*|\/(?:[\w.@*-]+\/)*[\w.@*-]*|\.{1,2}(?:\/[\w.@*-]+)+|[\w.-]+(?:\/[\w.-]+)+/g;

const EXTENDED_PATH_CHARACTERS = new Uint8Array(128);

const RELATIVE_PATH_CHARACTERS = new Uint8Array(128);

for (let code = 0; code < 128; code++) {
  const character = String.fromCharCode(code);

  if (/[a-zA-Z0-9_]/.test(character) || ".@*-".includes(character)) {
    EXTENDED_PATH_CHARACTERS[code] = 1;
  }

  if (/[a-zA-Z0-9_]/.test(character) || ".-".includes(character)) {
    RELATIVE_PATH_CHARACTERS[code] = 1;
  }
}

const isExtendedPathCharacter = (commandText: string, i: number): boolean =>
  i < commandText.length &&
  commandText.charCodeAt(i) < 128 &&
  EXTENDED_PATH_CHARACTERS[commandText.charCodeAt(i)] === 1;

const isRelativePathCharacter = (commandText: string, i: number): boolean =>
  i < commandText.length &&
  commandText.charCodeAt(i) < 128 &&
  RELATIVE_PATH_CHARACTERS[commandText.charCodeAt(i)] === 1;

export function bashPathTokens(command: string): string[] {
  const length = command.length;
  // Cached run ends prevent repeated scans of long commands.
  const extendedRunEnds = new Int32Array(length + 1);
  const relativeRunEnds = new Int32Array(length + 1);
  extendedRunEnds[length] = length;
  relativeRunEnds[length] = length;

  for (let i = length - 1; i >= 0; i--) {
    extendedRunEnds[i] = isExtendedPathCharacter(command, i)
      ? extendedRunEnds[i + 1]
      : i;
    relativeRunEnds[i] = isRelativePathCharacter(command, i)
      ? relativeRunEnds[i + 1]
      : i;
  }

  const tokens: string[] = [];
  let position = 0;

  while (position < length) {
    const character = command[position];
    let tokenEnd = 0;

    if (character === "~" || command.startsWith("$HOME", position)) {
      let segmentEnd = character === "~" ? position + 1 : position + 5;

      while (
        command[segmentEnd] === "/" &&
        isExtendedPathCharacter(command, segmentEnd + 1)
      ) {
        segmentEnd = extendedRunEnds[segmentEnd + 1];
      }

      tokenEnd = segmentEnd;
    } else if (character === "/") {
      let segmentEnd = position + 1;

      while (isExtendedPathCharacter(command, segmentEnd)) {
        const runEnd = extendedRunEnds[segmentEnd];

        if (command[runEnd] !== "/") {
          segmentEnd = runEnd;
          break;
        }

        segmentEnd = runEnd + 1;
      }

      tokenEnd = segmentEnd;
    } else if (character === ".") {
      const relativePathEnd = (segmentEnd: number): number | null => {
        if (
          command[segmentEnd] !== "/" ||
          !isExtendedPathCharacter(command, segmentEnd + 1)
        ) {
          return null;
        }

        let runEnd = segmentEnd;

        while (
          command[runEnd] === "/" &&
          isExtendedPathCharacter(command, runEnd + 1)
        ) {
          runEnd = extendedRunEnds[runEnd + 1];
        }

        return runEnd;
      };

      if (command[position + 1] === ".") {
        tokenEnd = relativePathEnd(position + 2) ?? 0;
      }

      if (tokenEnd === 0) {
        tokenEnd = relativePathEnd(position + 1) ?? 0;
      }
    }

    if (tokenEnd === 0 && isRelativePathCharacter(command, position)) {
      const wordEnd = relativeRunEnds[position];

      if (
        command[wordEnd] === "/" &&
        isRelativePathCharacter(command, wordEnd + 1)
      ) {
        let segmentEnd = wordEnd;

        while (
          command[segmentEnd] === "/" &&
          isRelativePathCharacter(command, segmentEnd + 1)
        ) {
          segmentEnd = relativeRunEnds[segmentEnd + 1];
        }

        tokenEnd = segmentEnd;
      }
    }

    if (tokenEnd > position) {
      tokens.push(command.slice(position, tokenEnd));
      position = tokenEnd;
    } else {
      position++;
    }
  }

  return tokens;
}

function denyPathForms(raw: string, cwd: string): string[] {
  if (!raw) {
    return [];
  }

  const expanded = expandHome(raw.replace(/^\$HOME(?=\/|$)/, os.homedir()));

  return baseForms(path.resolve(cwd, expanded));
}

export const anchorDenyPaths = (paths: string[], cwd: string): string[] =>
  paths.flatMap((base) => denyPathForms(base, cwd));

function denyPathCandidates(
  toolName: string,
  input: Record<string, unknown>,
  cwd: string,
): string[] {
  const kind = toolKind(toolName);

  if (kind === "command") {
    return bashPathTokens(String(input.command ?? ""));
  }

  if (kind === "file") {
    const rawPath =
      typeof input.path === "string" && input.path ? input.path : null;

    if (!rawPath) {
      return isScopeTool(toolName) ? [cwd] : [];
    }

    return [rawPath];
  }

  return [];
}

function hitDenyPaths(
  toolName: string,
  input: Record<string, unknown>,
  cwd: string,
  bases: string[],
): string | null {
  if (bases.length === 0) {
    return null;
  }

  const subtree = isScopeTool(toolName);

  for (const candidate of denyPathCandidates(toolName, input, cwd)) {
    for (const candidateForm of denyPathForms(candidate, cwd)) {
      for (const base of bases) {
        if (
          pathEquals(candidateForm, base) ||
          pathStartsWith(candidateForm, base) ||
          (subtree && pathStartsWith(base, candidateForm))
        ) {
          return base;
        }
      }
    }
  }

  return null;
}

// Priority: protection -> danger rules -> user deny -> protected paths -> user allow -> classifier.
export function classifyByRules(
  toolName: string,
  input: Record<string, unknown>,
  cwd: string,
  user: UserRules,
  prot: ProtectedSet,
  denyPathBases: string[],
): RuleResult {
  const protection = selfProtectCheck(toolName, input, cwd, prot);

  if (protection) {
    return protection;
  }

  let base: RuleResult;
  const kind = toolKind(toolName);

  if (kind === "command") {
    base = classifyBash(String(input.command ?? ""), user.builtinDenyFloor);
  } else if (toolName === "write" || toolName === "edit") {
    base = classifyPath(
      String(input.path ?? ""),
      cwd,
      true,
      user.builtinDenyFloor,
    );
  } else if (toolName === "read") {
    base = classifyPath(
      String(input.path ?? ""),
      cwd,
      false,
      user.builtinDenyFloor,
    );
  } else if (kind === "file") {
    const rawPath =
      typeof input.path === "string" && input.path ? input.path : undefined;
    base = classifyPath(rawPath ?? cwd, cwd, false, user.builtinDenyFloor);

    if (
      base.verdict !== "deny" &&
      scopeContainsS0(path.resolve(cwd, expandHome(rawPath ?? cwd)))
    ) {
      base = {
        verdict: user.builtinDenyFloor ? "deny" : "gray",
        reason:
          "S0 secrets/credential file inside the search scope (scope tool)",
      };
    }
  } else {
    base = user.ignoreTools.includes(toolName)
      ? {
          verdict: "allow",
          reason: `user ignoreTools passthrough: ${toolName}`,
        }
      : {
          verdict: "gray",
          reason: `tool not covered by built-in rules: ${toolName}`,
        };
  }

  if (base.verdict === "deny") {
    return base;
  }

  const target = userRuleTarget(toolName, input, cwd);

  if (target !== null) {
    for (const pattern of user.deny) {
      if (pattern.test(target)) {
        return { verdict: "deny", reason: `user deny rule: ${pattern.source}` };
      }
    }

    const matchesPathRules = hitDenyPaths(toolName, input, cwd, denyPathBases);

    if (matchesPathRules) {
      return {
        verdict: "ask",
        reason:
          "user-declared protected path (denyPaths) [path withheld; see extensionSettings.verdict]",
        detail: matchesPathRules,
      };
    }

    for (const pattern of user.allow) {
      if (pattern.test(target)) {
        return { verdict: "allow", reason: "user allow rule" };
      }
    }
  }

  return base;
}
