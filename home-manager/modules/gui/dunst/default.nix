#
# Lightweight and customizable notifications.
# src: https://dunst-project.org/
#

{ config, ... }:
let
  palette = config.colorScheme.palette;
in {
  services.dunst = {
    enable = true;

    # For settings: man dunst.5
    # also available here: https://github.com/dunst-project/dunst/blob/master/docs/dunst.5.pod
    settings = {
      global = {
        follow = "mouse";
        # Dynamic width of the notification window, from 0 to 300px.
        width = "(0,300)";
        # The maximum height of a single notification, excluding the frame.
        height = 300;
        # Respectively the horizontal and vertical offset in pixels from the corner
        # of the screen specified by origin. A negative offset will lead to the notification being off screen.
        # Margin of 14px from the right and 50 pixels from the top.
        offset = "14x50";

        # The distance in pixels from the content to the border of the window in the horizontal axis.
        horizontal_padding = 10;

        # Defines color of the frame around the notification window.
        frame_color = "#${palette.base05}";
        background = "#${palette.base00}";
        foreground = "#${palette.base05}";

        font = "JetBrainsMono Nerd Font 12";

        corner_radius = 4;
        timeout = 4;
      };

      ##################
      # Specific rules #
      ##################

      urgency_low = {};
      urgency_normal = {};
      urgency_critical = {
        frame_color = "#${palette.base08}";
        timeout = 0;
      };
    };
  };

}
