#
# Modules for hyprland.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # A wlroots-compatible Wayland color picker that does not suck.
    #
    # /!\ Need to set the cursor theme for hyprpicker to work.
    # See https://github.com/hyprwm/hyprpicker/issues/51.
    # Cursor set in `theme/default.nix`.
    #
    # src: https://github.com/hyprwm/hyprpicker
    hyprpicker
    # Copy/paste utilities: https://github.com/bugaevc/wl-clipboard
    wl-clipboard
    # Day/night gamma adjustments for Wayland: https://sr.ht/~kennylevinsen/wlsunset
    wlsunset
  ];
}
