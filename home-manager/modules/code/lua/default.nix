#
# Powerful, fast, lightweight, embeddable scripting language.
# src: https://www.lua.org/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ lua ];
}
