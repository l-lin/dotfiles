#
# Standalone widget system in any window manager.
# src: https://github.com/elkowar/eww
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ eww ];

  xdg.configFile.eww = {
    source = ./config;
    recursive = true;
  };
}
