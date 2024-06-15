# Sway is a tiling Wayland compositor and a drop-in replacement for the i3 window manager for X11.
#
# See https://nixos.wiki/wiki/Sway
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4"; # Super key
      # Exhaustive list of options: https://www.mankier.com/5/sway-input
      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
          xkb_options = "ctrl:nocaps";
          xkb_numlock = "enabled";
        };

        "type:touchpad" = {
          tap = "enabled";
        };
      };
    };
  };
}
