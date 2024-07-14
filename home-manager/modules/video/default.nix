#
# Video related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # A complete, cross-platform solution to record, convert and stream audio and video: https://www.ffmpeg.org/
    ffmpeg
    # General-purpose media player, fork of MPlayer and mplayer2: https://mpv.io/
    mpv
    # Cross-platform media player and streaming server: https://www.videolan.org/vlc/
    vlc
    # Utility program for screen recording of wlroots-based compositors: https://github.com/ammen99/wf-recorder
    wf-recorder
  ];
}
