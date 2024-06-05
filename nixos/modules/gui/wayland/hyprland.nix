{ pkgs, ... }: {
  imports = [
    ./wayland.nix
    ./wofi.nix
  ];

  # https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
  programs.hyprland.enable = true;

  # Enable screen sharing
  #xdg.portal = {
  #  enable = true;
  #  wlr.enable = true;
  #  extraPortals = [
  #    pkgs.xdg-desktop-portal-gtk
  #  ];
  #};

  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };
}
 
