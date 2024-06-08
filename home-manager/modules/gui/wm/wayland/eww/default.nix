#
# Standalone widget system in any window manager.
# src: https://github.com/elkowar/eww
#

{ config, pkgs, ... }:
let
  palette = config.colorScheme.palette;
in {
  home.packages = with pkgs; [ eww ];

  # Symlink to ~/.config/eww
  xdg.configFile.eww = {
    source = ./config;
    recursive = true;
  };

  # Symlink to ~/.config/eww/style/_colors.scss
  xdg.configFile."eww/style/_colors.scss".text = ''
    $background : #${palette.base00};
    $foreground : #${palette.base05};
    $background-alt : #${palette.base00};
    $background-light : #${palette.base04};
    $foreground-alt : #${palette.base05};
    $red : #${palette.base08};
    $red-light : #${palette.color08};
    $green : #${palette.color0B};
    $green-light : #${palette.color0B};
    $yellow : #${palette.color0A};
    $yellow-light : #${palette.color0A};
    $blue : #${palette.color0D};
    $blue-light : #${palette.color0D};
    $cyan : #${palette.color0C};
    $cyan-light : #${palette.color0C};
    $magenta : #${palette.color0E};
    $magenta-light : #${palette.color0E};
    $comment : #${palette.base04};
    $accent : #${palette.color0D};
  '';
}
