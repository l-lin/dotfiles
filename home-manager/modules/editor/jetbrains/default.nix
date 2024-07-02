#
# Tools for software developers.
# src: https://www.jetbrains.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ jetbrains-toolbox ];

  # Symlink to ~/.ideavimrc
  home.file.".ideavimrc".source = ./.ideavimrc;
}
