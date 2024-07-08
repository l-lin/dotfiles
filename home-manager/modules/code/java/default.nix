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
  xdg.dataFile."eclipse/java-code-style.xml".source = ./.local/share/eclipse/java-code-style.xml;
  # Symlink ~/.config/nvim/snippets/java.snippets
  xdg.configFile."nvim/snippets/java.snippets".source = ./.config/nvim/snippets/java.snippets;
}
