#
# Tools for software developers.
# src: https://www.jetbrains.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Free Java, Kotlin, Groovy and Scala IDE from jetbrains (built from source): https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/default.nix#L53
    jetbrains.idea-community
  ];

  # Symlink to ~/.ideavimrc
  home.file.".ideavimrc".source = ./.ideavimrc;
}
