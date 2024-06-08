#
# Screen lock.
# src: https://github.com/swaywm/swaylock
#

{ pkgs, ... }: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;

    # https://github.com/swaywm/swaylock/blob/master/swaylock.1.scd
    settings = {
      show-failed-attempts = false;

      indicator = true;
      indicator-caps-lock = true;
      indicator-radius = 200;
      indicator-thickness = 25;

      line-uses-ring = false;

      ignore-empty-password = true;

      # Colors
      bs-hl-color = "ffffff";
      caps-lock-key-hl-color = "ffffff";
      caps-lock-bs-hl-color = "ffffff";
      key-hl-color = "00000066";
      separator-color = "00000000";

      inside-color = "00000033";
      inside-clear-color = "00000000";
      inside-caps-lock-color = "ffffff00";
      inside-ver-color = "ffffff00";
      inside-wrong-color = "ffffff00";

      ring-color = "ffffff";
      ring-clear-color = "ffffff";
      ring-caps-lock-color = "ffffff";
      ring-ver-color = "ffffff";
      ring-wrong-color = "ffffff";

      line-color = "000000";
      line-clear-color = "000000";
      line-caps-lock-color = "000000";
      line-ver-color = "000000";
      line-wrong-color = "000000";

      text-color = "ffffff";
      text-clear-color = "ffffff";
      text-caps-lock-color = "ffffff";
      text-ver-color = "ffffff";
      text-wrong-color = "ffffff";

      # Effects
      # Options: https://github.com/jirutka/swaylock-effects
      # Show date/time indicator.
      clock = true;
      timestr = "%R";
      datestr = "%a, %e of %B";

      # Use screenshots instead of an image.
      screenshots = true;

      # Password grace period.
      grace = 0;
      grace-no-mouse = true;
      grace-no-touch = true;

      # Blur the image, <radius>x<times>.
      effect-blur = "10x3";
    };
  };
}
