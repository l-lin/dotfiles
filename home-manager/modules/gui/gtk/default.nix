#
# GTK
#

{ pkgs, ... }: {
  # Enable toggle dark/light mode
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
