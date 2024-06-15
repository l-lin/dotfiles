#
# Shells.
#

{ userSettings, ...}: {
  imports = [
    (./. + "/${userSettings.shell}")

    ./multiplexer
  ];
}
