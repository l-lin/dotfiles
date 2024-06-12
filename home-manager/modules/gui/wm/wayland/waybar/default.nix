#
# Highly customizable Wayland bar for Sway and Wlroots based compositors.
# src: https://github.com/alexays/waybar
#

{ config, pkgs, ... }:
let
  palette = config.colorScheme.palette;
in {
  programs.waybar = {
    enable = true;
  };

  # Symlink to ~/.config/waybar
  xdg.configFile."waybar/config.jsonc".source = ./config/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./config/style.css;
  xdg.configFile."waybar/colorscheme.css".text = ''
@define-color fg #${palette.base05};
@define-color fg-alt #${palette.base00};
@define-color bg #${palette.base00};
@define-color bg-alt #${palette.base0D};
  '';
}
