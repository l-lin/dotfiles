#
# A wlroots-compatible Wayland color picker that does not suck.
# src: https://github.com/hyprwm/hyprpicker
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ hyprpicker ];

  # Need to set the cursor theme for hyprpicker to work.
  # src: https://github.com/hyprwm/hyprpicker/issues/51
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.gnome.adwaita-icon-theme;
    name = "Adwaita";
    size = 16;
  };
}
