#
# Lightweight and customizable notifications.
# src: https://dunst-project.org/
#

{ config, lib, ... }:
let
  palette = config.lib.stylix.colors;
in {
  services.dunst = {
    enable = true;

    # For settings: `man dunst.5`.
    # Also available here: https://github.com/dunst-project/dunst/blob/master/docs/dunst.5.pod
    # Default values: https://github.com/dunst-project/dunst/blob/master/dunstrc
    #
    # Cannot use symlink to ~/.config/dunst/dunstrc and ~/.config/dunst/dunstrc.d/*.conf, it seems
    # home-manager/nix is doing some stuff behind the scene that overrides the values...
    settings = {
      global = {
        # Display notification on focused monitor.  Possible modes are:
        #   mouse: follow mouse pointer
        #   keyboard: follow window with keyboard focus
        #   none: don't follow anything
        #
        # "keyboard" needs a window manager that exports the
        # _NET_ACTIVE_WINDOW property.
        # This should be the case for almost all modern window managers.
        #
        # If this option is set to mouse or keyboard, the monitor option
        # will be ignored.
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

        # Defines width in pixels of frame around the notification window.
        # Set to 0 to disable.
        frame_width = 2;

        # Defines color of the frame around the notification window.
        frame_color = "#${palette.base05}";

        # Define the corner radius of the notification window
        # in pixel size. If the radius is 0, you have no rounded
        # corners.
        # The radius will be automatically lowered if it exceeds half of the
        # notification height to avoid clipping text and/or icons.
        corner_radius = 8;

        timeout = 4;
      };

      ##################
      # Specific rules #
      ##################

      urgency_low = {
        # Force color of the frame instead of the one from stylix.
        frame_color = lib.mkForce "#${palette.base05}";
      };
      urgency_normal = {
        # Force color of the frame instead of the one from stylix.
        frame_color = lib.mkForce "#${palette.base05}";
      };
      urgency_critical = {
        # Force color of the frame instead of the one from stylix.
        frame_color = lib.mkForce "#${palette.base08}";
        timeout = 0;
      };
    };
  };

}
