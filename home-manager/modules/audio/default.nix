#
# Audio stuff.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # A minimalist command line interface to MPD: https://www.musicpd.org/clients/mpc/
    mpc-cli
    # Pulseaudio volume control: https://github.com/cdemoulins/pamixer
    pamixer
    # PulseAudio Volume Control GUI: http://freedesktop.org/software/pulseaudio/pavucontrol/
    pavucontrol
    # CLI and curses mixer for pulseaudio.
    # src: https://github.com/GeorgeFilipkin/pulsemixer
    pulsemixer
  ];
}
