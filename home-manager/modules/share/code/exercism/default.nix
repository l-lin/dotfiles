#
# Solve coding exercises and get mentored to develop fluency in your chosen programming languages.
# src: https://exercism.org
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ exercism ];
}
