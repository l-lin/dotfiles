#
# Dynamic tiling Wayland compositor
# See:
# - https://hyprland.org/
# - https://nixos.wiki/wiki/Hyprland
# - https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
#

{ pkgs, ... }: {
  wayland.windowManager.hyprland = {
    # Whether to enable Hyprland wayland compositor
    enable = true;
    # The hyprland package to use
    package = pkgs.hyprland;
    extraConfig = ''
      ${builtins.readFile ./hyprland.conf}
    '';
  };
}
