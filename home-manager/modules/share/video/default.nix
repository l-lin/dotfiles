#
# Video related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # A complete, cross-platform solution to record, convert and stream audio and video: https://www.ffmpeg.org/
    ffmpeg
    # General-purpose media player, fork of MPlayer and mplayer2: https://mpv.io/
    mpv
  ];
}
