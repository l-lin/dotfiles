#
# Audio stuff.
#

{ pkgs, ... }: {
  imports = [
    ./ncmpcpp.nix
    ./mpd.nix
  ];

  home.packages = with pkgs; [
    # PulseAudio Volume Control GUI.
    pavucontrol
    # Cli and curses mixer for pulseaudio.
    # src: https://github.com/GeorgeFilipkin/pulsemixer
    pulsemixer
  ];
}
