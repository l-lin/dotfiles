#
# Dynamic tiling Wayland compositor
# See:
# - https://hyprland.org/
# - https://nixos.wiki/wiki/Hyprland
# - https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
#

{ pkgs, ... }: {
  imports = [ ../default.nix ];

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
