#
# Graphical User Interfaces.
#

{ userSettings, ...}: {
  imports = [
    (./. + "/${userSettings.wmType}")
  ];
}
