#
# Audio stuff.
#

{ pkgs, ... }: {
  imports = [
    ./ncmpcpp.nix
    ./mpd.nix
  ];

  home.packages = with pkgs; [
    # A minimalist command line interface to MPD: https://www.musicpd.org/clients/mpc/
    mpc-cli
    # PulseAudio is a sound server for POSIX and Win32 systems: http://www.pulseaudio.org/
    pulseaudio
    # CLI and curses mixer for pulseaudio.
    # src: https://github.com/GeorgeFilipkin/pulsemixer
    pulsemixer
  ];
}
