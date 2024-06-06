#
# Terminal emulator
# src: https://alacritty.org/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ alacritty ];

  # Symlink ~/.config/alacritty
  xdg.configFile.alacritty = {
    source = ./config;
    recursive = true;
  };
}
