#
# Hyprlock is a simple, yet fast, multi-threaded and GPU-accelerated screen lock for Hyprland.
# src: https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ hyprlock ];

  # Symlink to ~/.config/hypr/hyprlock.conf
  xdg.configFile."hypr/hyprlock.conf".source = ./config/hyprlock.conf;
}
