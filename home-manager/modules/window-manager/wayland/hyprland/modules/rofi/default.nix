#
# A launcher/menu program.
# src: https://github.com/lbonn/rofi
#

{ config, pkgs, ... }:
let
  palette = config.lib.stylix.colors;
in {
  home.packages = with pkgs; [ rofi-wayland ];

  # Symlink to ~/.config/rofi
  xdg.configFile."rofi/colorscheme.rasi".text = ''
    * {
      font:           "JetBrainsMono Nerd font 12";
      background:     #${palette.base00};
      background-alt: #${palette.base00};
      foreground:     #${palette.base05};
      selected:       #${palette.base0D};
      active:         #${palette.base0D};
      urgent:         #${palette.base08};
    }
  '';
  xdg.configFile."rofi/config.rasi".source = ./config/rofi/config.rasi;
}
