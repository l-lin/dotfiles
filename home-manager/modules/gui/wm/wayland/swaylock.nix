#
# Screen lock.
# src: https://github.com/swaywm/swaylock
#

{ pkgs, ... }: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      clock = true;
      color = "00000000";
      font = "JetBrainsMono Nerd Font";
      show-failed-attempts = true;
      indicator = true;
      indicator-radius = 220;
      indicator-thickness = 25;
      separator-color = "00000000";
      line-uses-ring = false;
      grace = 0;
      grace-no-mouse = true;
      grace-no-touch = true;
      datestr = "%d.%m.%y";
      fade-in = "0.1";
      ignore-empty-password = true;
    };
  };
}
