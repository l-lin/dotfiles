#
# Hyprland's idle daemon.
# src: https://wiki.hyprland.org/Hypr-Ecosystem/hypridle/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ hypridle ];

  # Symlink to ~/.config/hypr/hypridle.conf
  xdg.configFile."hypr/hypridle.conf".source = ./config/hypridle.conf;
}
