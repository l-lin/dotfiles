#
# The open-source Java Development Kit.
# src: https://openjdk.java.net/
#

{
  home.sessionVariables = {
    JDTLS_JVM_ARGS = "-javaagent:$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar";
    # Better font rendering on Java desktop apps with the flag `-Dawt.useSystemAAFontSettings=lcd`.
    # src: https://wiki.nixos.org/wiki/Java
    #
    # Make macOS M4 works on Java 21 with the flag `-XX:UseSVE=0`, but it's not really working...
    # src: https://github.com/corretto/corretto-21/issues/85#issuecomment-2537411974
    #_JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd -XX:UseSVE=0";
  };

  # Symlink ~/.local/share/eclipse/java-code-style.xml
  xdg.dataFile."eclipse/java-code-style.xml".source = ./.local/share/eclipse/java-code-style.xml;
}
