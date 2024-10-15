#
# GitHub CLI tool.
# src: https://cli.github.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ gh ];

  # Symlink ~/.config/zsh/completions/_gh
  xdg.configFile."zsh/completions/_gh".source = ./.config/zsh/completions/_gh;
}
