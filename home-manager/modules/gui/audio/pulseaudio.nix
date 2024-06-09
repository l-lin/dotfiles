#
# Adjust the audio volume of the PulseAudio sound system
# src: https://gitlab.xfce.org/panel-plugins/xfce4-pulseaudio-plugin
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ xfce.xfce4-pulseaudio-plugin ];
}
