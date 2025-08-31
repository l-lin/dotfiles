#
# Apache Maven is a build tool for Java projects. Using a project object model (POM), Maven manages a project's compilation, testing, and documentation.
# src: https://maven.apache.org/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Build automation tool (used primarily for Java projects): https://maven.apache.org/
    maven
    # The Apache Maven Daemon: https://maven.apache.org/
    #mvnd

    # We need to declare as a global function instead of creating a zsh function because
    # it will be used by NeoVim, so using it does not have the zsh plugin that provides functions.
    (writeShellScriptBin "mvn-compile" ''
#!/usr/bin/env bash
#
# Compile a Maven project and filter output to show only errors and warnings.
# Useful for integrating with editors like Neovim.
#

./mvnw compile -q -B -T1C 2>&1 | grep '^\[\(ERROR\|WARNING\)\] file://' | sort -u
    '')
  ];

  home.sessionVariables = {
    MAVEN_OPTS = "-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN";
  };
}
