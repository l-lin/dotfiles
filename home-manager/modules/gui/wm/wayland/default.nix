#
# Wayland is a replacement for the X11 window system protocol and architecture
# with the aim to be easier to develop, extend, and maintain.
# src: https://wayland.freedesktop.org/
#

{ pkgs, userSettings, ... }: {
  imports = [
    (./. + "/modules/gui/wm"+("/"+userSettings.wmType+"/"+userSettings.wm))
    ./swaylock.nix
  ];

  home.packages = with pkgs; [
    # Read and control device brightness: https://github.com/Hummer12007/brightnessctl
    brightnessctl
    # Pulseaudio volume control: https://github.com/cdemoulins/pamixer
    pamixer
    # Copy/paste utilities: https://github.com/bugaevc/wl-clipboard
    wl-clipboard
  ];
}
