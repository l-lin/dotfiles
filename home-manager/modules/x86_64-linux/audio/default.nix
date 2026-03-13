#
# Audio stuff.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Pulseaudio volume control: https://github.com/cdemoulins/pamixer
    pamixer
    # PulseAudio Volume Control GUI: http://freedesktop.org/software/pulseaudio/pavucontrol/
    pavucontrol
  ];
}
