#
# X11 window system protocol.
# src: https://www.x.org/wiki/
#

{ userSettings, ...}: {
  imports = [
    (./. + "/${userSettings.wm}")
  ];
}
