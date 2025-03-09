#
# The open-source Java Development Kit.
# src: https://openjdk.java.net/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Build automation tool (used primarily for Java projects): https://maven.apache.org/
    maven
  ];

  programs.java = with pkgs; {
    # Ensure JAVA_HOME is set.
    enable = true;
    package = jdk21;
  };

  home.sessionVariables = {
    MAVEN_OPTS = "-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Dorg.slf4j.simpleLogger.dateTimeFormat=HH:mm:ss";
    JDTLS_JVM_ARGS = "-javaagent:$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar";
    # Better font rendering on Java desktop apps.
    # src: https://wiki.nixos.org/wiki/Java
    _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
  };

  # Symlink ~/.local/share/eclipse/java-code-style.xml
  xdg.dataFile."eclipse/java-code-style.xml".source = ./.local/share/eclipse/java-code-style.xml;
}
