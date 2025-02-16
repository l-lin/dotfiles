#
# X11 window system protocol.
# src: https://www.x.org/wiki/
#

{ pkgs, ... }: {
  imports = [
    ./redshift
    ./rofi
    # (./. + "/${userSettings.wm}")
  ];

  home.packages = with pkgs; [
    # Resize and Rotate for X window manager: https://wiki.archlinux.org/title/Xrandr
    xorg.xrandr
  ];
}
