#
# Powerful screenshot annotation tool.
# src: https://github.com/gabm/Satty
#

{ pkgs, ...}: {
  home.packages = with pkgs; [
    # Grab image from a Wayland compositor: https://github.com/emersion/grim
    grim
    # Select a region in a Wayland compositor: https://github.com/emersion/slurp
    slurp

    satty
  ];
}
