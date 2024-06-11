#
# The open-source Java Development Kit.
# src: https://openjdk.java.net/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Free Java, Kotlin, Groovy and Scala IDE from jetbrains (built from source): https://www.jetbrains.com/idea/
    jetbrains-toolbox
    jdk21
    # Build automation tool (used primarily for Java projects): https://maven.apache.org/
    maven
  ];
}
