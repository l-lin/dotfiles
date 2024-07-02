#
# Modules for wayland window manager.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Copy/paste utilities: https://github.com/bugaevc/wl-clipboard
    wl-clipboard
    # Day/night gamma adjustments for Wayland: https://sr.ht/~kennylevinsen/wlsunset
    wlsunset
  ];
}
