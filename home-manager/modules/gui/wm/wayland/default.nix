#
# Wayland is a replacement for the X11 window system protocol and architecture
# with the aim to be easier to develop, extend, and maintain.
# src: https://wayland.freedesktop.org/
#

{ pkgs, ... }: {

  imports = [
    ./swaylock
  ];

  home.packages = with pkgs; [
    # Copy/paste utilities: https://github.com/bugaevc/wl-clipboard
    wl-clipboard
  ];
}
