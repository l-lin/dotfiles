#
# A wayland based logout menu:
# https://github.com/ArtsyMacaw/wlogout
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ wlogout ];

  # Symlink to ~/.config/wlogout.layout
  xdg.configFile."wlogout/layout".source = ./config/wlogout/layout;
}
