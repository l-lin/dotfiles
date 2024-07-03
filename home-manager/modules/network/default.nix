#
# Networking tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Command-line DNS client for humans: https://doggo.mrkaran.dev/docs/
    doggo
  ];
}
