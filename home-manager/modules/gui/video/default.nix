#
# Video related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Cross-platform media player and streaming server: https://www.videolan.org/vlc/
    vlc
  ];
}
