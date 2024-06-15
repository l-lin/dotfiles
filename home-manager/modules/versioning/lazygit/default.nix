#
# Simple terminal UI for git commands.
# src: https://github.com/jesseduffield/lazygit
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ lazygit ];

  # Symlink to ~/.config/lazygit/config.yml
  xdg.configFile."lazygit/config.yml".source = ./config/config.yml;
}
