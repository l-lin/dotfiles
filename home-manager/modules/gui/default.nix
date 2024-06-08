#
# Graphical User Interfaces.
#

{ pkgs, userSettings, ... }: {
  imports = [
    (./. + "/wm/${userSettings.wmType}")
    ./browser/firefox
    ./dunst
    #./eww
    ./wall
  ];

  home.packages = with pkgs; [
    # A wlroots-compatible Wayland color picker that does not suck: https://github.com/hyprwm/hyprpicker
    hyprpicker
  ];
}
