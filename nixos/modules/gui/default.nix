#
# Graphical User Interfaces.
#

{ userSettings, ...}:
let
  wmType = if (userSettings.wm == "gnome") then "x11" else "wayland";
in {
  imports = [
    (./. + "/wm/${wmType}")
    ./thunar.nix
  ];
}
