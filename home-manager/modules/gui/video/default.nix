#
# Video related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # General-purpose media player, fork of MPlayer and mplayer2: https://mpv.io/
    mpv
    # Cross-platform media player and streaming server: https://www.videolan.org/vlc/
    vlc
  ];
}
