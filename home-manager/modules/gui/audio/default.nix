#
# Audio stuff.
#

{ pkgs, ... }: {

  imports = [
    ./spotify
  ];

  home.packages = with pkgs; [
    # PulseAudio Volume Control GUI: http://freedesktop.org/software/pulseaudio/pavucontrol/
    pavucontrol
  ];
}
