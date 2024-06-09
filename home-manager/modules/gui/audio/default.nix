#
# Audio stuff.
#

{ pkgs, ... }: {
  imports = [
    ./ncmpcpp.nix
  ];

  home.packages = with pkgs; [
    # Cli and curses mixer for pulseaudio.
    # src: https://github.com/GeorgeFilipkin/pulsemixer
    pulsemixer
  ];
}
