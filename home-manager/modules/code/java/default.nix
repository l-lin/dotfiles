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
}
