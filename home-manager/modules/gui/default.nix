#
# Graphical User Interfaces.
#

{ userSettings, ... }: {
  imports = [
    ./theme
    (./. + "/wm/${userSettings.wmType}")
  ];
}
