#
# Screen lock.
# src: https://github.com/swaywm/swaylock
#

{ pkgs, ... }: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
  };
}
