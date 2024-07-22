#
# Dynamic tiling Wayland compositor
# src:
# - https://hyprland.org/
# - https://nixos.wiki/wiki/Hyprland
# - https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
#

{ pkgs, ... }: {
  programs.hyprland.enable = true;

  # Enable XDG Desktop Portal (XDP) integration.
  # An XDP is a program that lets other applications communicate swiftly with the compositor through D-Bus.
  # Used for:
  # - screen sharing
  # - communication with GTK-based application (e.g. set properties like "prefer-dark")
  # src: https://flatpak.github.io/xdg-desktop-portal/docs/index.html
  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      # For Hyprland, you’d usually use xdg-desktop-portal-wlr.
      # Unfortunately, due to various reasons the -wlr portal is inferior to the KDE or Gnome ones.
      # In order to bridge the gap, Hyprland has its own fork of xdg-desktop-portal-wlr that has more features,
      # called xdg-desktop-portal-hyprland.
      # You don’t need xdg-desktop-portal-hyprland. Hyprland will work with xdg-desktop-portal-wlr, but
      # xdg-desktop-portal-hyprland has more features, like e.g. window sharing.
      # src: https://wiki.hyprland.org/hyprland-wiki/pages/Useful-Utilities/Hyprland-desktop-portal/
      xdg-desktop-portal-hyprland
    ];
  };

  environment.sessionVariables = {
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };
}
