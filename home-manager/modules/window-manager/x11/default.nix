#
# X11 window system protocol.
# src: https://www.x.org/wiki/
#

{ pkgs, userSettings, ... }: {
  imports = [
    ./redshift
    (./. + "/${userSettings.wm}")
  ];

  # HACK: xscreensaver is installed natively because I'm getting some
  # "Permission denied" with the one installed from home-manager.
  # I should investigate it when I have the time...

  home.packages = with pkgs; [
    # Resize and Rotate for X window manager: https://wiki.archlinux.org/title/Xrandr
    xorg.xrandr
    # Command-line program for getting and setting the contents of the X selection: http://www.kfish.org/software/xsel
    xsel
  ];
}
