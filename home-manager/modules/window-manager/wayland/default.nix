#
# Wayland is a replacement for the X11 window system protocol and architecture
# with the aim to be easier to develop, extend, and maintain.
# src: https://wayland.freedesktop.org/
#

{
  imports = [
    # TODO: Keeping Gnome Wayland, in case I have some issue with X WM...
    # (./. + "/${userSettings.wm}")
    ./gnome

    ./tools
  ];

  home.sessionVariables = {
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };
}
