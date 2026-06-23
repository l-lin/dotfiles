import assert from "node:assert/strict";
import test from "node:test";
import {
  disableKotlinMavenDaemon,
  KOTLIN_MAVEN_DAEMON_DISABLED_FLAG,
  rewriteSandboxRuntimeLoopbackHosts,
} from "./command-adjustments.js";

function when_disablingKotlinMavenDaemon(command: string): string {
  return disableKotlinMavenDaemon(command);
}

function when_rewritingSandboxRuntimeLoopbackHosts(
  wrappedCommand: string,
): string {
  return rewriteSandboxRuntimeLoopbackHosts(wrappedCommand);
}

test("disableKotlinMavenDaemon GIVEN a direct mvn invocation WHEN adjusting the sandboxed command THEN the Kotlin daemon is disabled", () => {
  const actual = when_disablingKotlinMavenDaemon("mvn test");
  const expected = `mvn ${KOTLIN_MAVEN_DAEMON_DISABLED_FLAG} test`;

  assert.equal(actual, expected);
});

test("disableKotlinMavenDaemon GIVEN a Maven wrapper invocation WHEN adjusting the sandboxed command THEN the Kotlin daemon is disabled", () => {
  const actual = when_disablingKotlinMavenDaemon("./mvnw -q verify");
  const expected = `./mvnw ${KOTLIN_MAVEN_DAEMON_DISABLED_FLAG} -q verify`;

  assert.equal(actual, expected);
});

test("disableKotlinMavenDaemon GIVEN environment assignments before mvn WHEN adjusting the sandboxed command THEN the Kotlin daemon flag is inserted after the executable", () => {
  const actual = when_disablingKotlinMavenDaemon(
    'JAVA_HOME="/tmp/jdk" MAVEN_OPTS="-Xmx2g" mvn test',
  );
  const expected = `JAVA_HOME="/tmp/jdk" MAVEN_OPTS="-Xmx2g" mvn ${KOTLIN_MAVEN_DAEMON_DISABLED_FLAG} test`;

  assert.equal(actual, expected);
});

test("disableKotlinMavenDaemon GIVEN an env-prefixed Maven command WHEN adjusting the sandboxed command THEN the Kotlin daemon flag is still inserted after the executable", () => {
  const actual = when_disablingKotlinMavenDaemon(
    'env JAVA_HOME="/tmp/jdk" mvn test',
  );
  const expected = `env JAVA_HOME="/tmp/jdk" mvn ${KOTLIN_MAVEN_DAEMON_DISABLED_FLAG} test`;

  assert.equal(actual, expected);
});

test("disableKotlinMavenDaemon GIVEN chained shell commands WHEN adjusting the sandboxed command THEN only the Maven segment is rewritten", () => {
  const actual = when_disablingKotlinMavenDaemon("cd repo && mvn test");
  const expected = `cd repo && mvn ${KOTLIN_MAVEN_DAEMON_DISABLED_FLAG} test`;

  assert.equal(actual, expected);
});

test("disableKotlinMavenDaemon GIVEN an explicit Kotlin daemon property WHEN adjusting the sandboxed command THEN the user-provided value is preserved", () => {
  const actual = when_disablingKotlinMavenDaemon(
    "mvn -Dkotlin.compiler.daemon=true test",
  );
  const expected = "mvn -Dkotlin.compiler.daemon=true test";

  assert.equal(actual, expected);
});

test("disableKotlinMavenDaemon GIVEN a non-Maven command WHEN adjusting the sandboxed command THEN the command stays unchanged", () => {
  const actual = when_disablingKotlinMavenDaemon("gradle test");
  const expected = "gradle test";

  assert.equal(actual, expected);
});

test("rewriteSandboxRuntimeLoopbackHosts GIVEN a macOS wrapped sandbox command WHEN adjusting THEN runtime proxy env vars use 127.0.0.1 while the sandbox profile and user command stay unchanged", () => {
  const actual =
    when_rewritingSandboxRuntimeLoopbackHosts(`env HTTP_PROXY\\=http\\://localhost\\:55231 HTTPS_PROXY\\=http\\://localhost\\:55231 ALL_PROXY\\=socks5h\\://localhost\\:55232 "GIT_SSH_COMMAND=ssh -o ProxyCommand='nc -X 5 -x localhost:55232 %h %p'" CLOUDSDK_PROXY_ADDRESS\\=localhost RSYNC_PROXY\\=localhost\\:55232 sandbox-exec -p "(allow network-bind (local ip \\\"localhost:*\\\"))
(allow network-inbound (local ip \\\"localhost:*\\\"))
(allow network-outbound (local ip \\\"localhost:*\\\"))
(allow network-bind (local ip \\\"localhost:55231\\\"))
(allow network-inbound (local ip \\\"localhost:55231\\\"))
(allow network-outbound (remote ip \\\"localhost:55231\\\"))
(allow network-bind (local ip \\\"localhost:55232\\\"))
(allow network-inbound (local ip \\\"localhost:55232\\\"))
(allow network-outbound (remote ip \\\"localhost:55232\\\"))" /bin/bash -c 'HTTP_PROXY=http://localhost:9999 echo localhost && gh api rate_limit'`);
  const expected = `env HTTP_PROXY\\=http\\://127.0.0.1\\:55231 HTTPS_PROXY\\=http\\://127.0.0.1\\:55231 ALL_PROXY\\=socks5h\\://127.0.0.1\\:55232 "GIT_SSH_COMMAND=ssh -o ProxyCommand='nc -X 5 -x 127.0.0.1:55232 %h %p'" CLOUDSDK_PROXY_ADDRESS\\=127.0.0.1 RSYNC_PROXY\\=127.0.0.1\\:55232 sandbox-exec -p "(allow network-bind (local ip \\\"localhost:*\\\"))
(allow network-inbound (local ip \\\"localhost:*\\\"))
(allow network-outbound (local ip \\\"localhost:*\\\"))
(allow network-bind (local ip \\\"localhost:55231\\\"))
(allow network-inbound (local ip \\\"localhost:55231\\\"))
(allow network-outbound (remote ip \\\"localhost:55231\\\"))
(allow network-bind (local ip \\\"localhost:55232\\\"))
(allow network-inbound (local ip \\\"localhost:55232\\\"))
(allow network-outbound (remote ip \\\"localhost:55232\\\"))" /bin/bash -c 'HTTP_PROXY=http://localhost:9999 echo localhost && gh api rate_limit'`;

  assert.equal(actual, expected);
});

test("rewriteSandboxRuntimeLoopbackHosts GIVEN a Linux wrapped sandbox command WHEN adjusting THEN runtime setenv proxy values use 127.0.0.1 without changing the user command", () => {
  const actual = when_rewritingSandboxRuntimeLoopbackHosts(
    `bwrap --setenv HTTP_PROXY http\\://localhost\\:3128 --setenv HTTPS_PROXY http\\://localhost\\:3128 --setenv ALL_PROXY socks5h\\://localhost\\:1080 --setenv all_proxy socks5h\\://localhost\\:1080 --setenv FTP_PROXY socks5h\\://localhost\\:1080 --setenv GRPC_PROXY socks5h\\://localhost\\:1080 --setenv GIT_SSH_COMMAND "ssh -o ProxyCommand='nc -X 5 -x localhost:1080 %h %p'" --setenv CLOUDSDK_PROXY_ADDRESS localhost --setenv RSYNC_PROXY localhost\\:1080 -- /bin/bash -c 'ALL_PROXY=socks5h://localhost:9999 printf %s localhost && gh api rate_limit'`,
  );
  const expected = `bwrap --setenv HTTP_PROXY http\\://127.0.0.1\\:3128 --setenv HTTPS_PROXY http\\://127.0.0.1\\:3128 --setenv ALL_PROXY socks5h\\://127.0.0.1\\:1080 --setenv all_proxy socks5h\\://127.0.0.1\\:1080 --setenv FTP_PROXY socks5h\\://127.0.0.1\\:1080 --setenv GRPC_PROXY socks5h\\://127.0.0.1\\:1080 --setenv GIT_SSH_COMMAND "ssh -o ProxyCommand='nc -X 5 -x 127.0.0.1:1080 %h %p'" --setenv CLOUDSDK_PROXY_ADDRESS 127.0.0.1 --setenv RSYNC_PROXY 127.0.0.1\\:1080 -- /bin/bash -c 'ALL_PROXY=socks5h://localhost:9999 printf %s localhost && gh api rate_limit'`;

  assert.equal(actual, expected);
});

test("rewriteSandboxRuntimeLoopbackHosts GIVEN an unwrapped user command WHEN adjusting THEN the command stays unchanged", () => {
  const actual = when_rewritingSandboxRuntimeLoopbackHosts(
    "HTTP_PROXY=http://localhost:9999 gh api rate_limit",
  );
  const expected = "HTTP_PROXY=http://localhost:9999 gh api rate_limit";

  assert.equal(actual, expected);
});
