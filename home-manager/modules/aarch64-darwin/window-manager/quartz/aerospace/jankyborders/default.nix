#
# JankyBorders is a lightweight tool designed to add colored borders to user windows on macOS 14.0+.
# src: https://github.com/FelixKratz/JankyBorders
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ jankyborders ];
}
