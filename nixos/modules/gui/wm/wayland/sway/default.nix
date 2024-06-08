#
# Sway is a tiling Wayland compositor and a drop-in replacement for the i3 window manager for X11.
#
# src: https://nixos.wiki/wiki/Sway
#

{ ... }: {
  imports = [ ../default.nix ];

  programs.sway.enable = true;
}