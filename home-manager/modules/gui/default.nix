#
# Graphical User Interfaces.
#

{ userSettings, ... }: {
  imports = [
    (./. + "/wm/${userSettings.wmType}")
    ./browser/firefox
    ./dunst
    ./hyprpicker.nix
    #./eww
    ./wall
  ];
}
