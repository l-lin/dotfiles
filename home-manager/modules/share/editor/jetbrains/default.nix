#
# Tools for software developers.
# src: https://www.jetbrains.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; lib.optional (! stdenv.isDarwin) jetbrains.idea-oss;

  # Symlink to ~/.ideavimrc
  home.file.".ideavimrc".source = ./.ideavimrc;
}
