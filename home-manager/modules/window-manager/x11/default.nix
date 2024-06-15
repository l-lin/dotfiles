#
# X11 window system protocol.
# src: https://www.x.org/wiki/
#

{ userSettings, ... }: {
  imports = [
    ./redshift
    (./. + "/${userSettings.wm}")
  ];
}
