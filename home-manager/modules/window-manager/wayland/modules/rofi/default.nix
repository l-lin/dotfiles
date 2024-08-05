#
# A launcher/menu program.
# src: https://github.com/lbonn/rofi
#

{ config, pkgs, ... }:
let
  #palette = config.lib.stylix.colors;
in {
  home.packages = with pkgs; [ rofi-wayland ];

  # Symlink to ~/.config/rofi
  xdg.configFile."rofi/colorscheme.rasi".text = ''
    * {
      font:           "JetBrainsMono Nerd font 12";
      background:     #1F1F28;
      background-alt: #1F1F28;
      foreground:     #DCD7BA;
      selected:       #7E9CD8;
      active:         #7E9CD8;
      urgent:         #C34043;
    }
  '';
  xdg.configFile."rofi/config.rasi".source = ./config/rofi/config.rasi;
}
