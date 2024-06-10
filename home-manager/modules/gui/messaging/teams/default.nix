#
# MS teams.
# src: https://teams.microsoft.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ teams-for-linux ];
}
