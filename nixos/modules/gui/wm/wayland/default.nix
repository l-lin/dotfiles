#
# Wayland is a replacement for the X11 window system protocol and architecture
# with the aim to be easier to develop, extend, and maintain.
# src: https://wayland.freedesktop.org/
#

{ userSettings, ... }: {
  imports = [
    (./. + "/modules/gui/wm"+("/"+userSettings.wmType+"/"+userSettings.wm))
    ./swaylock.nix
  ];
}
