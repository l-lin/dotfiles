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
    $red-light : #${palette.base08};
    $green : #${palette.base0B};
    $green-light : #${palette.base0B};
    $yellow : #${palette.base0A};
    $yellow-light : #${palette.base0A};
    $blue : #${palette.base0D};
    $blue-light : #${palette.base0D};
    $cyan : #${palette.base0C};
    $cyan-light : #${palette.base0C};
    $magenta : #${palette.base0E};
    $magenta-light : #${palette.base0E};
    $comment : #${palette.base04};
    $accent : #${palette.base0D};
  '';
}
