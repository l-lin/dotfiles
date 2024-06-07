#
# Wayland is a replacement for the X11 window system protocol and architecture
# with the aim to be easier to develop, extend, and maintain.
# src: https://wayland.freedesktop.org/
#

{ ... }: {
  # Need to add this line to make swaylock works.
  # src: 
  security.pam.services.swaylock = {};
}
