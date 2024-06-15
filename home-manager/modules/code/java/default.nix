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

  # Symlink ~/.local/share/eclipse/java-code-style.xml
  xdg.dataFile."eclipse/java-code-style.xml".source = ./config/java-code-style.xml;
}
