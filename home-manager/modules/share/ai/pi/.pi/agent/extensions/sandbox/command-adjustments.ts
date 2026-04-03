export const KOTLIN_MAVEN_DAEMON_DISABLED_FLAG =
  "-Dkotlin.compiler.daemon=false";

const SHELL_SEGMENT_SEPARATOR_REGEX = /(&&|\|\||;|\n)/;
const LEADING_MAVEN_SEGMENT_REGEX =
  /^(\s*)((?:env\s+)?)((?:[A-Za-z_][A-Za-z0-9_]*=(?:"[^"]*"|'[^']*'|[^\s"';&|]+)\s+)*)((?:\.\.?\/)?mvnw|mvn)\b/;

export function prepareSandboxedCommand(command: string): string {
  return disableKotlinMavenDaemon(command);
}

export function disableKotlinMavenDaemon(command: string): string {
  return command
    .split(SHELL_SEGMENT_SEPARATOR_REGEX)
    .map((segment, index) =>
      index % 2 === 0 ? disableKotlinMavenDaemonInSegment(segment) : segment,
    )
    .join("");
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
