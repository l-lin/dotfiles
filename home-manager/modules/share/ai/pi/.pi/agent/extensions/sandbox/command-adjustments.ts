export const KOTLIN_MAVEN_DAEMON_DISABLED_FLAG =
  "-Dkotlin.compiler.daemon=false";

const SHELL_SEGMENT_SEPARATOR_REGEX = /(&&|\|\||;|\n)/;
const LEADING_MAVEN_SEGMENT_REGEX =
  /^(\s*)((?:env\s+)?)((?:[A-Za-z_][A-Za-z0-9_]*=(?:"[^"]*"|'[^']*'|[^\s"';&|]+)\s+)*)((?:\.\.?\/)?mvnw|mvn)\b/;
const MACOS_SANDBOX_EXEC_SENTINEL = " sandbox-exec -p ";
const LINUX_WRAPPER_EXEC_SENTINEL = " -- ";

export function prepareSandboxedCommand(command: string): string {
  return disableKotlinMavenDaemon(command);
}

export function rewriteSandboxRuntimeLoopbackHosts(
  wrappedCommand: string,
): string {
  let rewrittenCommand = wrappedCommand;

  if (rewrittenCommand.includes(MACOS_SANDBOX_EXEC_SENTINEL)) {
    rewrittenCommand = rewritePrefixBeforeSentinel(
      rewrittenCommand,
      MACOS_SANDBOX_EXEC_SENTINEL,
    );
  }

  if (rewrittenCommand.startsWith("bwrap ")) {
    rewrittenCommand = rewritePrefixBeforeSentinel(
      rewrittenCommand,
      LINUX_WRAPPER_EXEC_SENTINEL,
    );
  }

  return rewrittenCommand;
}

export function disableKotlinMavenDaemon(command: string): string {
  return command
    .split(SHELL_SEGMENT_SEPARATOR_REGEX)
    .map((segment, index) =>
      index % 2 === 0 ? disableKotlinMavenDaemonInSegment(segment) : segment,
    )
    .join("");
}

function rewritePrefixBeforeSentinel(
  wrappedCommand: string,
  sentinel: string,
): string {
  const sentinelIndex = wrappedCommand.indexOf(sentinel);

  if (sentinelIndex === -1) {
    return wrappedCommand;
  }

  const wrapperPrefix = wrappedCommand.slice(0, sentinelIndex);
  const wrapperSuffix = wrappedCommand.slice(sentinelIndex);

  return `${rewriteRuntimeLoopbackPrefix(wrapperPrefix)}${wrapperSuffix}`;
}

function rewriteRuntimeLoopbackPrefix(wrapperPrefix: string): string {
  // AI: this only rewrites the sandbox-runtime wrapper prefix so user command text stays untouched.
  return wrapperPrefix
    .replaceAll("localhost\\:", "127.0.0.1\\:")
    .replaceAll("localhost:", "127.0.0.1:")
    .replaceAll(
      "CLOUDSDK_PROXY_ADDRESS\\=localhost",
      "CLOUDSDK_PROXY_ADDRESS\\=127.0.0.1",
    )
    .replaceAll(
      "CLOUDSDK_PROXY_ADDRESS=localhost",
      "CLOUDSDK_PROXY_ADDRESS=127.0.0.1",
    )
    .replaceAll(
      "--setenv CLOUDSDK_PROXY_ADDRESS localhost",
      "--setenv CLOUDSDK_PROXY_ADDRESS 127.0.0.1",
    );
}

function disableKotlinMavenDaemonInSegment(segment: string): string {
  if (segment.includes("kotlin.compiler.daemon=")) {
    return segment;
  }

  const match = segment.match(LEADING_MAVEN_SEGMENT_REGEX);

  if (!match) {
    return segment;
  }

  const [
    matchedPrefix,
    leadingWhitespace,
    envCommand,
    envAssignments,
    executable,
  ] = match;
  const replacement = `${leadingWhitespace}${envCommand}${envAssignments}${executable} ${KOTLIN_MAVEN_DAEMON_DISABLED_FLAG}`;

  return segment.replace(matchedPrefix, replacement);
}
