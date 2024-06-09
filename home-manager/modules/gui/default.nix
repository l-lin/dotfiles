#
# Graphical User Interfaces.
#

{ userSettings, ... }: {
  imports = [
    (./. + "/wm/${userSettings.wmType}")
    ./browser/firefox
    ./browser/w3m
    ./dunst
    ./hyprpicker.nix
    ./jetbrains
    ./satty.nix
    ./wall
  ];
}
