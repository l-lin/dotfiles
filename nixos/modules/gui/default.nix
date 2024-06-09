#
# Graphical User Interfaces.
#

{ userSettings, ...}: {
  imports = [
    (./. + "/wm/${userSettings.wmType}")
    ./thunar.nix
  ];
}
