#
# The Go Programming language
# src: https://go.dev/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ go ];
}
