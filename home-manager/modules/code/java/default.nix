#
# The open-source Java Development Kit.
# src: https://openjdk.java.net/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    jdk21
    # Build automation tool (used primarily for Java projects): https://maven.apache.org/
    maven
  ];

  home.sessionVariables = {
    MAVEN_OPTS = "-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Dorg.slf4j.simpleLogger.dateTimeFormat=HH:mm:ss";
    JDTLS_JVM_ARGS = "-javaagent:$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar";
  };

  # Symlink ~/.local/share/eclipse/java-code-style.xml
  xdg.dataFile."eclipse/java-code-style.xml".source = ./.local/share/eclipse/java-code-style.xml;
  # Symlink ~/.config/nvim/snippets/java.snippets
  xdg.configFile."nvim/snippets/java.snippets".source = ./.config/nvim/snippets/java.snippets;
}
