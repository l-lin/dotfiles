# Not working for me... :(
#
# See https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
{ pkgs, ... }: {

  programs.hyprland.enable = true;

  # Enable screen sharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = {
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };
}
