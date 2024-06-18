#
# Dynamic tiling Wayland compositor
# src:
# - https://hyprland.org/
# - https://nixos.wiki/wiki/Hyprland
# - https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
#

{ pkgs, ... }: {
  programs.hyprland.enable = true;

  # Enable XDG desktop integration.
  # Used for:
  # - screen sharing
  # - communication with GTK-based application (e.g. set properties like "prefer-dark")
  # src: https://flatpak.github.io/xdg-desktop-portal/docs/index.html
  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = {
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };
}
