# Not working for me... :(
#
# See:
# - https://nixos.wiki/wiki/Hyprland
# - https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
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

  home.packages = with pkgs; [
    wl-clipboard
  ];

  # Enable screen sharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  #environment.sessionVariables = {
  #  # Hint electron apps to use wayland
  #  NIXOS_OZONE_WL = "1";
  #};
}
