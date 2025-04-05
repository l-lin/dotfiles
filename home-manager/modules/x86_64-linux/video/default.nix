#
# Video related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Cross-platform media player and streaming server: https://www.videolan.org/vlc/
    vlc
    # Utility program for screen recording of wlroots-based compositors: https://github.com/ammen99/wf-recorder
    wf-recorder
  ];
}
