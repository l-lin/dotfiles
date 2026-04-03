import assert from "node:assert/strict";
import test from "node:test";
import {
  disableKotlinMavenDaemon,
  KOTLIN_MAVEN_DAEMON_DISABLED_FLAG,
} from "./command-adjustments.js";

function when_disablingKotlinMavenDaemon(command: string): string {
  return disableKotlinMavenDaemon(command);
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
